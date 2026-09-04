import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AuthService {
  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (e) {
      debugPrint("Auth access error: $e");
    }
    return null;
  }

  // Sign in
  Future<User?> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) return null;

    try {
      UserCredential result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Create User (Admin Action)
  Future<UserCredential?> createUser(String email, String password) async {
    final auth = _auth;
    if (auth == null) return null;

    try {
      return await auth.createUserWithEmailAndPassword(
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
    await _auth?.signOut();
  }

  // Current User
  User? get currentUser => _auth?.currentUser;
}
