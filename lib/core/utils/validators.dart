/// Comprehensive input validation utilities for form fields
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Validates email format
  /// Returns null if valid, error message if invalid
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // RFC 5322 compliant email regex (simplified)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates password strength
  /// Requires: min 8 chars, at least 1 letter, at least 1 number
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  /// Validates password confirmation matches
  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validates Nigerian phone number
  /// Accepts formats: +234XXXXXXXXXX, 234XXXXXXXXXX, 0XXXXXXXXXX
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Nigerian phone number patterns
    final patterns = [
      RegExp(r'^\+234[789][01]\d{8}$'),  // +234XXXXXXXXX
      RegExp(r'^234[789][01]\d{8}$'),     // 234XXXXXXXXX
      RegExp(r'^0[789][01]\d{8}$'),       // 0XXXXXXXXX
    ];
    
    if (!patterns.any((pattern) => pattern.hasMatch(cleaned))) {
      return 'Please enter a valid Nigerian phone number';
    }
    
    return null;
  }

  /// Validates required field
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates minimum length
  static String? minLength(String? value, int minLength, [String fieldName = 'This field']) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validates maximum length
  static String? maxLength(String? value, int maxLength, [String fieldName = 'This field']) {
    if (value != null && value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  /// Validates numeric input
  static String? numeric(String? value, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    
    return null;
  }

  /// Validates positive number
  static String? positiveNumber(String? value, [String fieldName = 'Amount']) {
    final numericError = numeric(value, fieldName);
    if (numericError != null) return numericError;
    
    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }
    
    return null;
  }

  /// Validates address (basic check for reasonable length)
  static String? address(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    if (value.length < 10) {
      return 'Please enter a complete address';
    }
    
    return null;
  }

  /// Validates name (alphabetic characters, spaces, and common name characters)
  static String? name(String? value, [String fieldName = 'Name']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    // Allow letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, and hyphens';
    }
    
    return null;
  }

  /// Combines multiple validators
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}
