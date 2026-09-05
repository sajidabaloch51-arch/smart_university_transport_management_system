class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email Address is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email address';
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full Name is required';
    // Must contain a valid name (alphabets and spaces)
    if (!RegExp(r"^[a-zA-Z\s']+$").hasMatch(value)) return 'Full Name must only contain letters and spaces';
    // Ensure it contains at least a first and last name
    List<String> words = value.trim().split(RegExp(r'\s+'));
    if (words.length < 2) return 'Please enter your complete full name (at least two names)';
    return null;
  }

  static String? validateRegNo(String? value) {
    if (value == null || value.trim().isEmpty) return 'Registration Number is required';
    // University format example: Alphanumeric and dashes
    final regRegex = RegExp(r'^[a-zA-Z0-9-]+$');
    if (!regRegex.hasMatch(value)) return 'Invalid Registration Number format. Use alphanumeric and dashes only.';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone Number is required';
    // Pakistani format: 03xxxxxxxxx or +923xxxxxxxxx or 00923xxxxxxxxx
    final phoneRegex = RegExp(r'^((\+92)|(0092)|(0))3[0-9]{9}$');
    if (!phoneRegex.hasMatch(value)) return 'Please enter a valid Pakistani phone number (e.g., 03001234567)';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    
    // Check length (8-20 characters)
    if (value.length < 8 || value.length > 20) {
      return 'Password must contain at least 8 characters and a maximum of 20 characters.';
    }

    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(value);
    final hasDigits = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

    if (!hasUpperCase || !hasLowerCase || !hasDigits || !hasSpecialCharacters) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.';
    }
    
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match. Please check again.';
    return null;
  }

  static String? validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }
}
