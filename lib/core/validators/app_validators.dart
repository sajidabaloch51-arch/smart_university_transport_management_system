class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!value.endsWith('@gmail.com')) return 'Only @gmail.com addresses are allowed';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? validateRequired(String? value, String field) {
    if (value == null || value.isEmpty) return '$field is required';
    return null;
  }
}
