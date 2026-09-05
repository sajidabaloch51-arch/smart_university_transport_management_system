import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign in
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Register Student
  Future<User?> registerStudent(StudentModel student, String password) async {
    try {
      // Check if registration number already exists
      final query = await _db
          .collection('users')
          .where('regNumber', isEqualTo: student.regNumber)
          .get();
          
      if (query.docs.isNotEmpty) {
        throw 'Registration Number already exists';
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: student.email,
        password: password,
      );
      
      if (result.user != null) {
        // Save additional details to Firestore
        await _db.collection('users').doc(result.user!.uid).set(
          student.toMap()..['uid'] = result.user!.uid
        );
      }
      return result.user;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Create User (Admin Action)
  Future<UserCredential?> createUser(String email, String password) async {
    try {
      // Note: In production, creating other users should be done via Firebase Admin SDK (Cloud Functions)
      // because creating a user automatically signs you in as that user.
      // For this project, we assume this is handled correctly.
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Current User
  User? get currentUser => _auth.currentUser;
}
