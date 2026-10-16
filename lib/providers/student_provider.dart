import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../services/university_db_service.dart';

class StudentProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  bool get isLoading => false;

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

  /// Approved students from Firestore `users` where role == student.
  Stream<List<StudentModel>> streamStudents() {
    final db = _db;
    if (db == null) return Stream.value(const <StudentModel>[]);

    return db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .where((s) => s.verificationStatus == 'approved')
          .toList();
    }).handleError((e) {
      debugPrint('streamStudents error: $e');
    });
  }

  Stream<List<StudentModel>> streamPendingStudents() {
    final db = _db;
    if (db == null) return Stream.value(const <StudentModel>[]);

    return db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((e) {
      debugPrint('streamPendingStudents error: $e');
    });
  }

  Future<void> verifyStudent(String uid, String status) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('users').doc(uid).update({
        'verificationStatus': status,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error verifying student: $e');
      rethrow;
    }
  }

  Future<StudentModel?> getStudent(String uid) async {
    if (uid.isEmpty) return null;
    final db = _db;
    if (db == null) return null;
    try {
      final doc = await db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return StudentModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('getStudent failed: $e');
    }
    return null;
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
    notifyListeners();
  }

  Future<void> addStudent(StudentModel student) async {
    final db = _db;
    if (db == null) {
      throw Exception(
        'Firestore not available. Create the database in Firebase Console first.',
      );
    }
    await db.collection('users').doc(student.uid).set(student.toMap());
    notifyListeners();
  }

  Future<void> deleteStudent(String uid) async {
    final db = _db;
    if (db == null) return;
    await db.collection('users').doc(uid).delete();
    notifyListeners();
  }
}
