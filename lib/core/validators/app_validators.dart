class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    // Gmail Only Regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid Gmail address (e.g., student@gmail.com)';
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
    
    if (!hasUppercase) return 'Password must contain at least one uppercase letter (Capital)';
    if (!hasLowercase) return 'Password must contain at least one lowercase letter';
    if (!hasDigits) return 'Password must contain at least one number (Digit)';
    if (!hasSpecialCharacters) return 'Password must contain at least one special character/symbol (@#\$...)';
    
    if (value.length > 20) {
      return 'Password must not exceed 20 characters';
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
    if (value == null || value.isEmpty) return null; // Optional
    // Example format: UG-202X-XXXXX or similar alphanumeric
    final regExp = RegExp(r'^[a-zA-Z0-9-]+$');
    if (!regExp.hasMatch(value)) return 'Invalid Registration Number format';
    return null;
  }

  static String? validateRegNo(String? value) {
    if (value == null || value.isEmpty) return 'Registration number is required';
    final regExp = RegExp(r'^[a-zA-Z0-9-]+$');
    if (!regExp.hasMatch(value)) return 'Invalid format (e.g. 19-UOG-123)';
    return null;
  }

  static String? validateRollNo(String? value) {
    if (value == null || value.isEmpty) return 'Roll No is required';
    if (value.length < 3) return 'Roll No must be at least 3 characters long';
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

  static String? validateCNIC(String? value) {
    if (value == null || value.isEmpty) return 'CNIC Number is required';
    // CNIC format: XXXXX-XXXXXXX-X or 13 digits
    final regExp = RegExp(r'^[0-9]{5}-?[0-9]{7}-?[0-9]{1}$');
    String cleanValue = value.replaceAll('-', '');
    if (cleanValue.length != 13 || !RegExp(r'^[0-9]+$').hasMatch(cleanValue)) {
      return 'CNIC must be 13 digits long';
    }
    if (!regExp.hasMatch(value)) {
      return 'Enter a valid CNIC (e.g., 12345-1234567-1)';
    }
    return null;
  }

  static String? validateBalochistanLicense(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Now optional
    }
    
    final trimmedValue = value.trim().toUpperCase();
    
    // Valid Balochistan license prefixes:
    // QTA (Quetta), BL (Balochistan General), GAW (Gwadar), TUR (Turbat/Kech), 
    // KHZ (Khuzdar), SIB (Sibi), LOR (Loralai), PIS (Pishin), ZH (Zhob), 
    // KAL (Kalat), DB (Dera Bugti), NAS (Nasirabad), HUB (Hub), KHA (Kharan) etc.
    final licenseRegex = RegExp(r'^(QTA|BL|GAW|TUR|KHZ|SIB|LOR|PIS|ZH|KAL|DB|NAS|HUB|KHA|QA|SU|LZ)-\d{4,12}$');
    
    if (!licenseRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid driving licence number.';
    }
    
    return null;
  }

  static String? validateEmployeeId(String? value) {
    if (value == null || value.isEmpty) return 'Employee ID is required';
    // Format: UOG-EMP- followed by exactly 3 digits
    final empIdRegex = RegExp(r'^UOG-EMP-\d{3}$');
    if (!empIdRegex.hasMatch(value)) {
      return 'Invalid format. Use UOG-EMP-### (e.g., UOG-EMP-001)';
    }
    return null;
  }
}
