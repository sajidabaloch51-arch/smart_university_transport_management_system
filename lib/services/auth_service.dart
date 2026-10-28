import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../utils/email_validator.dart';

class AuthService {
  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (_) {}
    return null;
  }

  bool get isAvailable => _auth != null;

  User? get currentUser => _auth?.currentUser;

  Future<User> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw AuthServiceException(
        'Authentication is unavailable. Check Firebase setup and internet.',
      );
    }

    try {
      final result = await auth.signInWithEmailAndPassword(
        email: AppEmailValidator.normalize(email),
        password: password,
      );
      final user = result.user;
      if (user == null) {
        throw AuthServiceException('Sign-in failed. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_mapAuthCode(e.code, e.message));
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      debugPrint('signIn error: $e');
      throw AuthServiceException('Sign-in failed. Check your connection.');
    }
  }

  /// Creates Firebase Auth user (password hashed/stored by Firebase — never in Firestore).
  /// Warning: switches the default Auth session to the new user.
  Future<User> createUser(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw AuthServiceException(
        'Authentication is unavailable. Check Firebase setup and internet.',
      );
    }

    try {
      final result = await auth.createUserWithEmailAndPassword(
        email: AppEmailValidator.normalize(email),
        password: password,
      );
      final user = result.user;
      if (user == null) {
        throw AuthServiceException('Could not create account. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_mapAuthCode(e.code, e.message));
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      debugPrint('createUser error: $e');
      throw AuthServiceException('Could not create account. Check your connection.');
    }
  }

  /// Creates an Auth user on a secondary FirebaseApp so the Admin session
  /// on the default app is not replaced / logged out.
  Future<User> createUserKeepCurrentSession(
    String email,
    String password,
  ) async {
    if (Firebase.apps.isEmpty) {
      throw AuthServiceException(
        'Authentication is unavailable. Check Firebase setup and internet.',
      );
    }

    const secondaryName = 'SUTMSSecondaryAuth';
    FirebaseApp secondary;
    try {
      secondary = Firebase.app(secondaryName);
    } catch (_) {
      secondary = await Firebase.initializeApp(
        name: secondaryName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondary);
    try {
      final result = await secondaryAuth.createUserWithEmailAndPassword(
        email: AppEmailValidator.normalize(email),
        password: password,
      );
      final user = result.user;
      if (user == null) {
        throw AuthServiceException('Could not create account. Please try again.');
      }
      // Sign out only on the secondary instance — Admin stays signed in.
      await secondaryAuth.signOut();
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_mapAuthCode(e.code, e.message));
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      debugPrint('createUserKeepCurrentSession error: $e');
      throw AuthServiceException(
        'Could not create account. Check your connection.',
      );
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth?.currentUser;
    if (user == null) {
      throw AuthServiceException('You must be signed in to change password.');
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_mapAuthCode(e.code, e.message));
    }
  }

  /// Sends a Firebase Auth password-reset email (user sets their own password).
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw AuthServiceException(
        'Authentication is unavailable. Check Firebase setup and internet.',
      );
    }
    try {
      await auth.sendPasswordResetEmail(
        email: AppEmailValidator.normalize(email),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_mapAuthCode(e.code, e.message));
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      debugPrint('sendPasswordResetEmail error: $e');
      throw AuthServiceException(
        'Could not send reset email. Check your connection.',
      );
    }
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }

  String _mapAuthCode(String code, String? message) {
    final msg = (message ?? '').toLowerCase();
    if (code == 'internal-error' ||
        msg.contains('configuration_not_found') ||
        msg.contains('configuration not found')) {
      return 'Firebase Auth Email/Password is not enabled. '
          'Open Firebase Console → Authentication → Sign-in method → '
          'enable Email/Password, then try again.';
    }
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please log in instead.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters with mixed rules.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return message ?? 'Authentication error ($code).';
    }
  }

  static bool isConfigurationError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('configuration_not_found') ||
        text.contains('configuration not found') ||
        text.contains('email/password is not enabled');
  }
}

class AuthServiceException implements Exception {
  final String message;
  AuthServiceException(this.message);

  @override
  String toString() => message;
}
