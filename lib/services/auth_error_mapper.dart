/// Maps Firebase Auth error codes to user-facing strings — grey/white-box testable.
class AuthErrorMapper {
  AuthErrorMapper._();

  static bool isCredentialMismatch(Object error) {
    if (error is Exception || error is Error) {
      // FirebaseAuthException.code when available (duck-typed for web wrappers).
      try {
        final dynamic dyn = error;
        final code = (dyn.code as String?)?.toLowerCase() ?? '';
        if (_credentialCodes.contains(code)) return true;
      } catch (_) {}
    }
    final text = error.toString().toLowerCase();
    return text.contains('wrong-password') ||
        text.contains('invalid-credential') ||
        text.contains('invalid-login-credentials') ||
        text.contains('invalid_login_credentials');
  }

  static bool isUserMissing(Object error) {
    try {
      final dynamic dyn = error;
      final code = (dyn.code as String?)?.toLowerCase() ?? '';
      if (code == 'user-not-found' || code == 'invalid-email') return true;
    } catch (_) {}
    final text = error.toString().toLowerCase();
    return text.contains('user-not-found') || text.contains('invalid-email');
  }

  static bool isEmailInUse(Object error) {
    try {
      final dynamic dyn = error;
      final code = (dyn.code as String?)?.toLowerCase() ?? '';
      if (code == 'email-already-in-use') return true;
    } catch (_) {}
    return error.toString().toLowerCase().contains('email-already-in-use');
  }

  static const _credentialCodes = {
    'wrong-password',
    'invalid-credential',
    'invalid-login-credentials',
  };

  static String map(String code, String? message) {
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
      case 'invalid-login-credentials':
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
