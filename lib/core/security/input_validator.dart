
/// Input validator and sanitizer for security
class InputValidator {
  /// Validate and sanitize email
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    final sanitized = email.trim().toLowerCase();
    
    if (!emailRegex.hasMatch(sanitized)) {
      return 'Please enter a valid email';
    }

    if (sanitized.length > 254) {
      return 'Email is too long';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (password.length > 128) {
      return 'Password is too long';
    }

    // Check for at least one uppercase
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one number
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Phone number is required';
    }

    final sanitized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (sanitized.length < 10 || sanitized.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Sanitize text input (prevent XSS)
  static String sanitizeText(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;')
        .trim();
  }

  /// Validate and sanitize name
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Name is required';
    }

    final sanitized = sanitizeText(name.trim());
    
    if (sanitized.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (sanitized.length > 50) {
      return 'Name is too long';
    }

    // Allow only letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(sanitized)) {
      return 'Name contains invalid characters';
    }

    return null;
  }

  /// Validate amount
  static String? validateAmount(String? amount) {
    if (amount == null || amount.trim().isEmpty) {
      return 'Amount is required';
    }

    final parsed = double.tryParse(amount);
    if (parsed == null) {
      return 'Please enter a valid amount';
    }

    if (parsed < 0) {
      return 'Amount cannot be negative';
    }

    if (parsed > 1000000) {
      return 'Amount is too large';
    }

    return null;
  }

  /// Validate address
  static String? validateAddress(String? address) {
    if (address == null || address.trim().isEmpty) {
      return 'Address is required';
    }

    final sanitized = sanitizeText(address.trim());
    
    if (sanitized.length < 5) {
      return 'Address is too short';
    }

    if (sanitized.length > 200) {
      return 'Address is too long';
    }

    return null;
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Sanitize user input for database
  static String sanitizeForDatabase(String input) {
    // Remove null bytes and control characters
    return input
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .trim();
  }

  /// Check for SQL injection patterns
  static bool containsSqlInjection(String input) {
    final sqlPatterns = [
      'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP',
      'CREATE', 'ALTER', 'EXEC', 'UNION', '--', ';'
    ];

    final upperInput = input.toUpperCase();
    return sqlPatterns.any((pattern) => upperInput.contains(pattern));
  }
}
