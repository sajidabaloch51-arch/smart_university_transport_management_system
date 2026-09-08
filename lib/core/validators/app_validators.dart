class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (value.length > 20) {
      return 'Password must not exceed 20 characters';
    }
    
    if (!hasUppercase || !hasLowercase || !hasDigits || !hasSpecialCharacters) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character';
    }
    
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm Password is required';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? validateRequired(String? value, String field) {
    if (value == null || value.isEmpty) return '$field is required';
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) return 'Full Name is required';
    if (value.trim().split(' ').length < 2) return 'Please enter your full name (at least two words)';
    return null;
  }

  static String? validateRegistrationNumber(String? value) {
    if (value == null || value.isEmpty) return 'Registration Number is required';
    // Example format: UG-202X-XXXXX or similar alphanumeric
    final regExp = RegExp(r'^[a-zA-Z0-9-]+$');
    if (!regExp.hasMatch(value)) return 'Invalid Registration Number format';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    // Pakistani phone number format: 03xx-xxxxxxx or +923xx-xxxxxxx
    final regExp = RegExp(r'^((\+92)|(0))3[0-9]{9}$');
    String cleanValue = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!regExp.hasMatch(cleanValue)) {
      return 'Invalid Pakistani phone number format (e.g., 03001234567)';
    }
    return null;
  }
}
