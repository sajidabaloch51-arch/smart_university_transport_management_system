/// Shared email rules for Student, Driver, and Admin (login + registration).
class AppEmailValidator {
  static const String hint = 'name@uog.edu.pk or name@gmail.com';

  static const String studentHint =
      'name@uog.edu.pk, name@gmail.com or name@student.ug.edu.pk';

  static const String errorMessage =
      'Enter a valid email ending with @uog.edu.pk or @gmail.com';

  static const String studentErrorMessage =
      'Enter a valid email ending with @uog.edu.pk, @gmail.com or @student.ug.edu.pk';

  static const Set<String> _sharedDomains = {
    'uog.edu.pk',
    'gmail.com',
  };

  /// Extra domain allowed only on the Student panel (login + registration).
  static const Set<String> _studentOnlyDomains = {
    'student.ug.edu.pk',
  };

  /// Trim + lowercase so Ali@Gmail.com and ali@gmail.com match.
  static String normalize(String email) => email.trim().toLowerCase();

  /// Form validator for Admin / Driver: @uog.edu.pk or @gmail.com only.
  static String? validate(String? value) =>
      _validate(value, allowStudentDomain: false);

  /// Form validator for Student panel only: also allows @student.ug.edu.pk.
  static String? validateStudent(String? value) =>
      _validate(value, allowStudentDomain: true);

  /// Role-aware helper — use `student` for the student panel only.
  static String? validateForRole(String? value, String? role) {
    final r = (role ?? '').trim().toLowerCase();
    if (r == 'student') return validateStudent(value);
    return validate(value);
  }

  static String hintForRole(String? role) {
    final r = (role ?? '').trim().toLowerCase();
    return r == 'student' ? studentHint : hint;
  }

  static String? _validate(String? value, {required bool allowStudentDomain}) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = normalize(value);
    final at = email.indexOf('@');
    if (at <= 0 || at != email.lastIndexOf('@')) {
      return allowStudentDomain ? studentErrorMessage : errorMessage;
    }

    final local = email.substring(0, at);
    final domain = email.substring(at + 1);
    final err = allowStudentDomain ? studentErrorMessage : errorMessage;

    // Local part: letters, numbers, dots, underscores, hyphens, plus.
    if (!RegExp(r'^[a-z0-9._+-]+$').hasMatch(local)) {
      return err;
    }
    if (local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..')) {
      return err;
    }

    final allowed = allowStudentDomain
        ? {..._sharedDomains, ..._studentOnlyDomains}
        : _sharedDomains;
    if (!allowed.contains(domain)) {
      return err;
    }

    return null;
  }

  static bool isAllowed(String email) => validate(email) == null;

  static bool isAllowedForStudent(String email) =>
      validateStudent(email) == null;
}
