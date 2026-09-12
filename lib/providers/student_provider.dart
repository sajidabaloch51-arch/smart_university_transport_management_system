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

  // Local cache for demo/offline mode
  final Map<String, StudentModel> _localStudents = {
    'pending_1': StudentModel(
      uid: 'pending_1',
      name: 'Khadija Maqbool',
      email: 'khadija@gmail.com',
      phone: '03344556677',
      role: 'student',
      regNumber: '002',
      fatherName: 'Maqbool Ahmed',
      gender: 'Female',
      dob: '2004-05-15',
      department: 'Computer Science',
      semester: '1',
      profileImage: '',
      routeAddress: 'Gwadar East Bay',
      rollNo: '01234',
      verificationStatus: 'pending',
    ),
    'pending_2': StudentModel(
      uid: 'pending_2',
      name: 'Zubair Ahmed',
      email: 'zubair@gmail.com',
      phone: '03322110099',
      role: 'student',
      regNumber: '005',
      fatherName: 'Ahmed Khan',
      gender: 'Male',
      dob: '2003-10-20',
      department: 'Business Administration',
      semester: '3',
      profileImage: '',
      routeAddress: 'Main Town Gwadar',
      rollNo: '220145',
      verificationStatus: 'pending',
    ),
  };

  Stream<List<StudentModel>> streamStudents() {
    try {
      final db = _db;
      if (db == null) {
        return Stream.value(_localStudents.values.toList());
      }

      return db.collection('users')
          .where('role', isEqualTo: 'student')
          .where('verificationStatus', isEqualTo: 'approved')
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
      debugPrint("Error in streamStudents: $e");
      return Stream.value(_localStudents.values.toList());
    }
  }

  Stream<List<StudentModel>> streamPendingStudents() {
    try {
      final db = _db;
      if (db == null) {
        return Stream.value(_localStudents.values
            .where((s) => s.verificationStatus == 'pending')
            .toList());
      }

      return db.collection('users')
          .where('role', isEqualTo: 'student')
          .where('verificationStatus', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) {
            final students = snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
            for (var s in students) { _localStudents[s.uid] = s; }
            return students;
          });
    } catch (e) {
      debugPrint("Error in streamPendingStudents: $e");
      return Stream.value(_localStudents.values
          .where((s) => s.verificationStatus == 'pending')
          .toList());
    }
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
          verificationStatus: status,
        );
        notifyListeners();
      }

      final db = _db;
      if (db != null) {
        await db.collection('users').doc(uid).update({'verificationStatus': status});
      }
    } catch (e) {
      debugPrint("Error verifying student: $e");
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
