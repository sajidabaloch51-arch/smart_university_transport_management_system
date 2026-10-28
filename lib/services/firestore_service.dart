import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../constants/demo_credentials.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/driver_model.dart';
import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../models/notice_model.dart';
import '../models/schedule_model.dart';
import '../utils/email_validator.dart';

class FirestoreService {
  // Safe getter for FirebaseFirestore
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {
      // Firebase not ready yet
    }
    return null;
  }

  // Helper to handle Firebase calls with a timeout for better UX.
  // 2s was too aggressive on slow mobile networks and caused login to miss
  // the users/{authUid} doc, then fall back to email lookup / wrong path.
  Future<T?> _withTimeout<T>(Future<T?> Function(FirebaseFirestore db) call) async {
    final db = _db;
    if (db == null) return null;
    
    try {
      return await call(db).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint("Firebase Timeout/Error: $e");
      return null;
    }
  }

  // --- USER OPERATIONS ---
  Future<void> createUser(UserModel user) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    return await _withTimeout<UserModel>((db) async {
      var doc = await db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['uid'] = data['uid']?.toString().isNotEmpty == true ? data['uid'] : doc.id;
        return UserModel.fromMap(data);
      }
      return null;
    });
  }

  /// Looks up a user document by email (case-insensitive match on stored email).
  Future<UserModel?> findUserByEmail(String email) async {
    final profile = await getUserAuthProfile(email);
    if (profile == null) return null;
    return UserModel(
      uid: profile.uid,
      name: profile.name,
      email: profile.email,
      phone: profile.phone,
      role: profile.role,
      isActive: profile.isActive,
    );
  }

  /// True only if [email] is on the university admin allowlist (or demo admin).
  Future<bool> isApprovedAdminEmail(String email) async {
    final normalized = AppEmailValidator.normalize(email);
    if (normalized.isEmpty) return false;
    if (normalized ==
        AppEmailValidator.normalize(DemoCredentials.adminEmail)) {
      return true;
    }

    final db = _db;
    if (db == null) return false;

    try {
      final byId = await db
          .collection('approvedAdmins')
          .doc(normalized)
          .get()
          .timeout(const Duration(seconds: 8));
      if (byId.exists) return true;

      final snap = await db
          .collection('approvedAdmins')
          .where('email', isEqualTo: normalized)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('isApprovedAdminEmail failed: $e');
      return normalized ==
          AppEmailValidator.normalize(DemoCredentials.adminEmail);
    }
  }

  /// Login profile including optional passwordHash (demo / Auth fallback).
  Future<UserAuthProfile?> getUserAuthProfile(String email) async {
    final normalized = AppEmailValidator.normalize(email);
    if (normalized.isEmpty) return null;
    final db = _db;
    if (db == null) return null;

    try {
      var snap = await db
          .collection('users')
          .where('email', isEqualTo: normalized)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 12));

      if (snap.docs.isEmpty) {
        snap = await db
            .collection('users')
            .where('email', isEqualTo: email.trim())
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 12));
      }

      // Demo IDs: admin@… → admin_id
      if (snap.docs.isEmpty) {
        final local = normalized.split('@').first;
        final doc = await db
            .collection('users')
            .doc('${local}_id')
            .get()
            .timeout(const Duration(seconds: 8));
        if (doc.exists && doc.data() != null) {
          return UserAuthProfile.fromMap(doc.data()!, doc.id);
        }
        return null;
      }

      final doc = snap.docs.first;
      return UserAuthProfile.fromMap(doc.data(), doc.id);
    } catch (e) {
      debugPrint('getUserAuthProfile failed: $e');
      return null;
    }
  }

  Stream<List<UserModel>> getUsers(String role) {
    final db = _db;
    if (db == null) return const Stream.empty();
    
    return db.collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // --- STUDENT OPERATIONS ---
  Stream<List<StudentModel>> streamStudents() {
    final db = _db;
    if (db == null) return const Stream.empty();

    return db.collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // --- DRIVER OPERATIONS ---
  Future<DriverModel?> getDriverData(String driverId) async {
    return await _withTimeout<DriverModel>((db) async {
      final doc = await db.collection('users').doc(driverId).get();
      if (doc.exists) {
        return DriverModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> updateDriverStatus(String driverId, bool isOnDuty) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('users').doc(driverId).update({
        'isOnDuty': isOnDuty,
        'lastDutyStart': isOnDuty ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      debugPrint('$e');
    }
  }

  // --- ROUTE OPERATIONS ---
  Stream<List<RouteModel>> getRoutes(String universityId) {
    final db = _db;
    if (db == null) return const Stream.empty();

    return db
        .collection('routes')
        .where('universityId', isEqualTo: universityId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RouteModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<RouteModel?> getRoute(String routeId) {
    final db = _db;
    if (db == null) return Stream.value(null);

    return db.collection('routes').doc(routeId).snapshots().map((doc) {
      if (doc.exists) {
        return RouteModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }

  Stream<RouteModel?> getAssignedRoute(String routeId) => getRoute(routeId);

  Future<void> addRoute(RouteModel route) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('routes').doc(route.id).set(route.toMap());
    } catch (e) {
      debugPrint('$e');
    }
  }

  // --- SCHEDULE OPERATIONS ---
  Stream<List<ScheduleModel>> getSchedules(String routeId) {
    final db = _db;
    if (db == null) return const Stream.empty();

    return db
        .collection('schedules')
        .where('routeId', isEqualTo: routeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ScheduleModel>> getTodaySchedules(String routeId) => getSchedules(routeId);

  // --- NOTICE OPERATIONS ---
  Stream<List<NoticeModel>> getNotices(String universityId) {
    final db = _db;
    if (db == null) return const Stream.empty();

    // No orderBy — avoids composite index delay; sort in Dart.
    return db.collection('notices').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // --- BUS OPERATIONS ---
  Stream<List<BusModel>> streamBuses() {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db.collection('buses').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => BusModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> addNotice(NoticeModel notice) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('notices').doc(notice.id).set(notice.toMap());
    } catch (e) {
      debugPrint('$e');
    }
  }

  // --- FEEDBACK ---
  /// Prefer [FeedbackService.submitFeedback] — this wrapper rethrows errors.
  Future<void> addFeedback(Map<String, dynamic> feedback) async {
    final db = _db;
    if (db == null) {
      throw StateError('Firestore not available');
    }
    await db.collection('feedback').add(feedback);
  }

  // --- LIVE LOCATION ---
  Stream<DocumentSnapshot> getDriverLocation(String driverId) {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db.collection('liveLocations').doc(driverId).snapshots();
  }

  Future<void> updateLiveLocation(String driverId, Map<String, dynamic> locationData) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('liveLocations').doc(driverId).set(locationData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('$e');
    }
  }
}

/// Minimal login profile read from Firestore `users`.
class UserAuthProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final String? passwordHash;

  UserAuthProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    this.passwordHash,
  });

  factory UserAuthProfile.fromMap(Map<String, dynamic> map, String docId) {
    return UserAuthProfile(
      uid: (map['uid']?.toString().isNotEmpty == true)
          ? map['uid'].toString()
          : docId,
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: (map['role'] ?? 'student').toString(),
      isActive: map['isActive'] ?? true,
      passwordHash: map['passwordHash'] as String?,
    );
  }
}
