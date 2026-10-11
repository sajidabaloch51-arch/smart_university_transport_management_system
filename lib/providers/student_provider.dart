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
    } catch (e) {}
    return null;
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Local cache — starts empty; filled by registration / admin actions
  final Map<String, StudentModel> _localStudents = {};

  Stream<List<StudentModel>> streamStudents() {
    return Stream.value(
      _localStudents.values
          .where((s) => s.verificationStatus == 'approved')
          .toList(),
    );
  }

  Stream<List<StudentModel>> streamPendingStudents() {
    return Stream.value(
      _localStudents.values
          .where((s) => s.verificationStatus == 'pending')
          .toList(),
    );
  }

  Future<void> verifyStudent(String uid, String status) async {
    try {
      if (_localStudents.containsKey(uid)) {
        final current = _localStudents[uid]!;
        _localStudents[uid] = StudentModel(
          uid: current.uid,
          name: current.name,
          email: current.email,
          phone: current.phone,
          role: current.role,
          regNumber: current.regNumber,
          fatherName: current.fatherName,
          gender: current.gender,
          dob: current.dob,
          department: current.department,
          semester: current.semester,
          profileImage: current.profileImage,
          routeAddress: current.routeAddress,
          rollNo: current.rollNo,
          assignedRouteId: current.assignedRouteId,
          assignedRouteName: current.assignedRouteName,
          assignedBusId: current.assignedBusId,
          assignedBusName: current.assignedBusName,
          assignedBusCode: current.assignedBusCode,
          assignedDriverId: current.assignedDriverId,
          assignedDriverName: current.assignedDriverName,
          assignedDriverPhone: current.assignedDriverPhone,
          assignedDepartureTime: current.assignedDepartureTime,
          assignedArrivalTime: current.assignedArrivalTime,
          verificationStatus: status,
        );
        notifyListeners();
      }

      final db = _db;
      if (db == null) return;
      db.collection('users').doc(uid).update({'verificationStatus': status}).then(
        (_) {},
        onError: (e) => debugPrint("Error verifying student: $e"),
      );
    } catch (e) {
      debugPrint("Error verifying student: $e");
    }
  }

  Future<StudentModel?> getStudent(String uid) async {
    if (uid.isEmpty) return null;
    if (_localStudents.containsKey(uid)) return _localStudents[uid];

    final db = _db;
    if (db == null) return null;
    try {
      final doc = await db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final student = StudentModel.fromMap(doc.data()!, doc.id);
        _localStudents[uid] = student;
        return student;
      }
    } catch (e) {
      debugPrint('getStudent failed: $e');
    }
    return null;
  }

  Future<void> updateStudent(StudentModel student) async {
    _localStudents[student.uid] = student;
    notifyListeners();

    final db = _db;
    if (db == null) return;

    db.collection('users').doc(student.uid).set(student.toMap(), SetOptions(merge: true)).then(
      (_) {},
      onError: (e) => debugPrint("Error updating student: $e"),
    );
  }

  Future<void> addStudent(StudentModel student) async {
    _localStudents[student.uid] = student;
    notifyListeners();

    final db = _db;
    if (db == null) return;

    db.collection('users').doc(student.uid).set(student.toMap()).then(
      (_) {},
      onError: (e) => debugPrint("Error adding student: $e"),
    );
  }

  Future<void> deleteStudent(String uid) async {
    _localStudents.remove(uid);
    notifyListeners();

    final db = _db;
    if (db == null) return;

    db.collection('users').doc(uid).delete().then(
      (_) {},
      onError: (e) => debugPrint("Error deleting student: $e"),
    );
  }
}
