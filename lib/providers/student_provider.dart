import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class StudentProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<StudentModel> _students = [];
  bool _isLoading = false;

  List<StudentModel> get students => _students;
  bool get isLoading => _isLoading;

  Stream<List<StudentModel>> streamStudents() {
    return _db.collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addStudent(StudentModel student) async {
    await _db.collection('users').doc(student.uid).set(student.toMap());
  }

  Future<void> deleteStudent(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }
}
