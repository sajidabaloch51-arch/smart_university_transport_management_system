import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../services/live_firestore.dart';
import '../services/university_db_service.dart';

class StudentProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  bool get isLoading => false;

  final Map<String, StudentModel> _studentCache = {};
  List<StudentModel> _cachedStudents = const [];
  List<StudentModel> _cachedPending = const [];
  List<StudentModel> get cachedStudents => _cachedStudents;
  List<StudentModel> get cachedPending => _cachedPending;

  /// Returns an existing student if this roll number is already registered.
  Future<StudentModel?> findByRollNo(String rollNo) async {
    final key = UniversityDBService.normalizeRollNo(rollNo);
    if (key.isEmpty) return null;
    final db = _db;
    if (db == null) return null;

    try {
      // Prefer indexed rollNoKey (string — preserves leading zeros).
      var snap = await db
          .collection('users')
          .where('rollNoKey', isEqualTo: key)
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 12));

      for (final doc in snap.docs) {
        final data = doc.data();
        if ((data['role'] ?? '') == 'student') {
          return StudentModel.fromMap(data, doc.id);
        }
      }

      // Fallback for older docs without rollNoKey
      final all = await db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get()
          .timeout(const Duration(seconds: 12));
      for (final doc in all.docs) {
        final data = doc.data();
        final existing = UniversityDBService.normalizeRollNo(
          (data['rollNo'] ?? '').toString(),
        );
        if (existing == key) {
          return StudentModel.fromMap(data, doc.id);
        }
      }
      return null;
    } catch (e) {
      debugPrint('findByRollNo failed: $e');
      rethrow;
    }
  }

  static const _studentsKey = 'users_students';
  static const _pendingKey = 'users_students_pending';

  /// Approved students from Firestore `users` where role == student.
  Stream<List<StudentModel>> streamStudents() {
    if (_db == null) return Stream.value(const <StudentModel>[]);
    return LiveFirestore.mapSnapshots(
      _studentsKey,
      (db) => db.collection('users').where('role', isEqualTo: 'student'),
      (snapshot) {
        final list = <StudentModel>[];
        for (final doc in snapshot.docs) {
          try {
            final s = StudentModel.fromMap(doc.data(), doc.id);
            if (s.verificationStatus == 'approved') list.add(s);
          } catch (e, st) {
            debugPrint('⚠️ Skipping bad student doc id=${doc.id}: $e\n$st');
          }
        }
        _cachedStudents = list;
        return _cachedStudents;
      },
      collectionLabel: 'users(role=student)',
    );
  }

  Stream<List<StudentModel>> streamPendingStudents() {
    if (_db == null) return Stream.value(const <StudentModel>[]);
    return LiveFirestore.mapSnapshots(
      _pendingKey,
      (db) => db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('verificationStatus', isEqualTo: 'pending'),
      (snapshot) {
        final list = <StudentModel>[];
        for (final doc in snapshot.docs) {
          try {
            list.add(StudentModel.fromMap(doc.data(), doc.id));
          } catch (e, st) {
            debugPrint(
              '⚠️ Skipping bad pending student doc id=${doc.id}: $e\n$st',
            );
          }
        }
        _cachedPending = list;
        return _cachedPending;
      },
      collectionLabel: 'users(student,pending)',
    );
  }

  void restartStudentStreams() {
    LiveFirestore.restart(_studentsKey);
    LiveFirestore.restart(_pendingKey);
  }

  Future<void> refreshStudents() => LiveFirestore.forceRefresh(_studentsKey);
  Future<void> refreshPending() => LiveFirestore.forceRefresh(_pendingKey);

  Future<void> verifyStudent(String uid, String status) async {
    final db = _db;
    if (db == null) return;
    try {
      final normalized = status.trim().toLowerCase();
      await db.collection('users').doc(uid).update({
        'verificationStatus': normalized,
      });
      final cached = _studentCache[uid];
      if (cached != null) {
        _studentCache[uid] = StudentModel(
          uid: cached.uid,
          name: cached.name,
          email: cached.email,
          phone: cached.phone,
          role: cached.role,
          regNumber: cached.regNumber,
          department: cached.department,
          profileImage: cached.profileImage,
          routeAddress: cached.routeAddress,
          rollNo: cached.rollNo,
          assignedRouteId: cached.assignedRouteId,
          assignedRouteName: cached.assignedRouteName,
          assignedBusId: cached.assignedBusId,
          assignedBusName: cached.assignedBusName,
          assignedBusCode: cached.assignedBusCode,
          assignedDriverId: cached.assignedDriverId,
          assignedDriverName: cached.assignedDriverName,
          assignedDriverPhone: cached.assignedDriverPhone,
          assignedDepartureTime: cached.assignedDepartureTime,
          assignedArrivalTime: cached.assignedArrivalTime,
          verificationStatus: normalized,
          passwordHash: cached.passwordHash,
          termsAccepted: cached.termsAccepted,
          termsVersion: cached.termsVersion,
        );
      } else {
        _studentCache.remove(uid);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error verifying student: $e');
      rethrow;
    }
  }

  /// Sync peek — used to paint UI before the network returns.
  StudentModel? peekStudent(String uid) =>
      uid.isEmpty ? null : _studentCache[uid];

  /// Login / access decisions must not use a stale disk/memory cache that still
  /// says `pending` after Admin already approved on the server.
  Future<StudentModel?> getStudentFresh(String uid) async {
    if (uid.isEmpty) return null;
    final db = _db;
    if (db == null) return _studentCache[uid];
    try {
      final doc = await db
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (doc.exists && doc.data() != null) {
        final model = StudentModel.fromMap(doc.data()!, doc.id);
        _studentCache[uid] = model;
        debugPrint(
          'getStudentFresh uid=$uid verificationStatus=${model.verificationStatus}',
        );
        return model;
      }
      _studentCache.remove(uid);
      return null;
    } catch (e) {
      debugPrint('getStudentFresh failed (fallback): $e');
      // Last resort: serverAndCache, still bypass memory-only stale entry.
      try {
        final doc = await db
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 5));
        if (doc.exists && doc.data() != null) {
          final model = StudentModel.fromMap(doc.data()!, doc.id);
          _studentCache[uid] = model;
          return model;
        }
      } catch (e2) {
        debugPrint('getStudentFresh fallback failed: $e2');
      }
      return _studentCache[uid];
    }
  }

  Future<StudentModel?> getStudent(String uid) async {
    if (uid.isEmpty) return null;
    final cached = _studentCache[uid];
    if (cached != null) return cached;

    final db = _db;
    if (db == null) return null;
    try {
      // Prefer disk cache so dashboards paint without waiting on the network.
      try {
        final fromCache = await db
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(milliseconds: 400));
        if (fromCache.exists && fromCache.data() != null) {
          final model = StudentModel.fromMap(fromCache.data()!, fromCache.id);
          _studentCache[uid] = model;
          // Soft refresh in background.
          // ignore: discarded_futures
          _refreshStudentFromServer(uid);
          return model;
        }
      } catch (_) {
        // Cache miss — fall through to serverAndCache.
      }

      final doc = await db
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));
      if (doc.exists && doc.data() != null) {
        final model = StudentModel.fromMap(doc.data()!, doc.id);
        _studentCache[uid] = model;
        return model;
      }
    } catch (e) {
      debugPrint('getStudent failed: $e');
    }
    return _studentCache[uid];
  }

  Future<void> _refreshStudentFromServer(String uid) async {
    final db = _db;
    if (db == null) return;
    try {
      final doc = await db
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (doc.exists && doc.data() != null) {
        _studentCache[uid] = StudentModel.fromMap(doc.data()!, doc.id);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> updateStudent(StudentModel student) async {
    final db = _db;
    if (db == null) {
      throw Exception(
        'Firestore not available. Create the database in Firebase Console first.',
      );
    }
    await db
        .collection('users')
        .doc(student.uid)
        .set(student.toMap(), SetOptions(merge: true));
    _studentCache[student.uid] = student;
    notifyListeners();
  }

  Future<void> addStudent(StudentModel student) async {
    final db = _db;
    if (db == null) {
      throw Exception(
        'Firestore not available. Create the database in Firebase Console first.',
      );
    }
    final data = student.toMap();
    if (student.termsAccepted) {
      data['termsAccepted'] = true;
      data['termsVersion'] = student.termsVersion ?? '1.0';
      data['termsAcceptedAt'] = FieldValue.serverTimestamp();
      data['role'] = 'student';
    }
    await db.collection('users').doc(student.uid).set(data);
    _studentCache[student.uid] = student;
    notifyListeners();
  }

  Future<void> deleteStudent(String uid) async {
    final db = _db;
    if (db == null) return;
    await db.collection('users').doc(uid).delete();
    notifyListeners();
  }
}
