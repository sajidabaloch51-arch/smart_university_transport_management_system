/// Shared email rules for Student, Driver, and Admin (login + registration).
class AppEmailValidator {
  static const String hint = 'name@uog.edu.pk or name@gmail.com';

  static const String errorMessage =
      'Enter a valid email ending with @uog.edu.pk or @gmail.com';

  /// Trim + lowercase so Ali@Gmail.com and ali@gmail.com match.
  static String normalize(String email) => email.trim().toLowerCase();

  /// Form validator: returns null when valid, otherwise [errorMessage].
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = normalize(value);
    final at = email.indexOf('@');
    if (at <= 0 || at != email.lastIndexOf('@')) {
      return errorMessage;
    }

    final local = email.substring(0, at);
    final domain = email.substring(at + 1);

    // Local part: letters, numbers, dots, underscores, hyphens, plus.
    if (!RegExp(r'^[a-z0-9._+-]+$').hasMatch(local)) {
      return errorMessage;
    }
    if (local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..')) {
      return errorMessage;
    }

    if (domain != 'uog.edu.pk' && domain != 'gmail.com') {
      return errorMessage;
    }

    return null;
  }

  static bool isAllowed(String email) => validate(email) == null;
}
