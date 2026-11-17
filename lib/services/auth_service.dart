import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../utils/email_validator.dart';
import 'auth_error_mapper.dart';

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
      throw AuthServiceException(AuthErrorMapper.map(e.code, e.message));
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      if (AuthErrorMapper.isCredentialMismatch(e)) {
        throw AuthServiceException(
          AuthErrorMapper.map('invalid-credential', null),
        );
      }
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
      throw AuthServiceException(AuthErrorMapper.map(e.code, e.message));
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      debugPrint('createUser error: $e');
      throw AuthServiceException('Could not create account. Check your connection.');
    }
  }

  Future<FirebaseApp> _secondaryApp() async {
    const secondaryName = 'SUTMSSecondaryAuth';
    try {
      return Firebase.app(secondaryName);
    } catch (_) {
      return Firebase.initializeApp(
        name: secondaryName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
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

    final secondary = await _secondaryApp();
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
      throw AuthServiceException(AuthErrorMapper.map(e.code, e.message));
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      debugPrint('createUserKeepCurrentSession error: $e');
      throw AuthServiceException(
        'Could not create account. Check your connection.',
      );
    }
  }

  /// Ensures a demo Email/Password Auth user exists (secondary app only).
  /// Returns the Auth uid, or null if Auth is unavailable / misconfigured.
  ///
  /// Order: sign-in → create if missing → if password mismatch, attempt a
  /// password reset via secondary sign-in is impossible; surface a clear log.
  Future<String?> ensureAuthUserKeepCurrentSession(
    String email,
    String password,
  ) async {
    if (Firebase.apps.isEmpty) return null;
    final normalized = AppEmailValidator.normalize(email);
    final secondary = await _secondaryApp();
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondary);
    void logPasswordMismatch() {
      debugPrint(
        '⚠️ Demo Auth password mismatch for $normalized. '
        'In Firebase Console → Authentication → Users, set password to '
        'the demo value (or delete the user) then relaunch.',
      );
    }

    try {
      // 1) Prefer sign-in (fast path when demo password already matches).
      try {
        final signedIn = await secondaryAuth.signInWithEmailAndPassword(
          email: normalized,
          password: password,
        );
        final uid = signedIn.user?.uid;
        await secondaryAuth.signOut();
        return uid;
      } catch (e) {
        if (AuthErrorMapper.isCredentialMismatch(e)) {
          // Auth user exists but password ≠ demo seed password.
          // Client SDK cannot reset another user's password without their
          // current credentials — delete+recreate in Firebase Console, or
          // reset the password to the demo value.
          logPasswordMismatch();
          return null;
        }
        if (!AuthErrorMapper.isUserMissing(e)) {
          debugPrint('ensureAuthUser signIn: $e');
          // Fall through to create attempt for unknown codes.
        }
      }

      // 2) Create when the account does not exist yet.
      try {
        final created = await secondaryAuth.createUserWithEmailAndPassword(
          email: normalized,
          password: password,
        );
        final uid = created.user?.uid;
        await secondaryAuth.signOut();
        return uid;
      } catch (e) {
        if (AuthErrorMapper.isEmailInUse(e) ||
            AuthErrorMapper.isCredentialMismatch(e)) {
          logPasswordMismatch();
          return null;
        }
        debugPrint('ensureAuthUser create: $e');
        return null;
      }
    } catch (e) {
      if (AuthErrorMapper.isCredentialMismatch(e) ||
          AuthErrorMapper.isEmailInUse(e)) {
        logPasswordMismatch();
      } else {
        debugPrint('ensureAuthUserKeepCurrentSession failed: $e');
      }
      try {
        await secondaryAuth.signOut();
      } catch (_) {}
      return null;
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
      throw AuthServiceException(AuthErrorMapper.map(e.code, e.message));
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
      throw AuthServiceException(AuthErrorMapper.map(e.code, e.message));
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

  static bool isConfigurationError(Object error) =>
      AuthErrorMapper.isConfigurationError(error);
}

class AuthServiceException implements Exception {
  final String message;
  AuthServiceException(this.message);

  @override
  String toString() => message;
}
