import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class StudentProvider extends ChangeNotifier {
  // Safe getter for FirebaseFirestore
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Local cache for demo/offline mode
  final Map<String, StudentModel> _localStudents = {};

  Stream<List<StudentModel>> streamStudents() {
    final db = _db;
    if (db == null) {
      return Stream.value(_localStudents.values.toList());
    }

    try {
      return db.collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots()
          .map((snapshot) {
            final students = snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
            // Update local cache
            for (var s in students) { _localStudents[s.uid] = s; }
            return students;
          });
    } catch (e) {
      debugPrint("Error streaming students: $e");
      return Stream.value(_localStudents.values.toList());
    }
  }

  Future<StudentModel?> getStudent(String uid) async {
    final db = _db;
    
    // Check local cache first for demo purposes
    if (_localStudents.containsKey(uid)) return _localStudents[uid];

    if (db == null) return null;

    try {
      final doc = await db.collection('users').doc(uid).get();
      if (doc.exists) {
        final student = StudentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        _localStudents[uid] = student;
        return student;
      }
    } catch (e) {
      debugPrint("Error getting student: $e");
    }
    return null;
  }

  Future<void> updateStudent(StudentModel student) async {
    _localStudents[student.uid] = student;
    notifyListeners();

    final db = _db;
    if (db == null) return;

    try {
      _isLoading = true;
      notifyListeners();
      await db.collection('users').doc(student.uid).update(student.toMap());
    } catch (e) {
      debugPrint("Error updating student: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStudent(StudentModel student) async {
    _localStudents[student.uid] = student;
    notifyListeners();

    final db = _db;
    if (db == null) return;

    try {
      _isLoading = true;
      notifyListeners();
      await db.collection('users').doc(student.uid).set(student.toMap());
    } catch (e) {
      debugPrint("Error adding student: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStudent(String uid) async {
    final db = _db;
    if (db == null) return;

    try {
      _isLoading = true;
      notifyListeners();
      await db.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint("Error deleting student: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
