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

  Stream<List<StudentModel>> streamStudents() {
    final db = _db;
    if (db == null) return const Stream.empty();

    try {
      return db.collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList());
    } catch (e) {
      debugPrint("Error streaming students: $e");
      return const Stream.empty();
    }
  }

  Future<void> addStudent(StudentModel student) async {
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
