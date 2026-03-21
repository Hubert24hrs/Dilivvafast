class RoleGuard {
  static bool hasRole(String? userRole, List<String> allowedRoles) {
    if (userRole == null) return false;
    return allowedRoles.contains(userRole);
  }

  static bool isAdmin(String? role) => role == 'admin';
  static bool isDriver(String? role) => role == 'driver';
  static bool isUser(String? role) => role == 'user';

  static String? getRedirectPath({
    required String? userRole,
    required String attemptedPath,
  }) {
    // Admin routes
    if (attemptedPath.startsWith('/admin')) {
      return isAdmin(userRole) ? null : '/';
    }
    
    // Driver routes
    if (attemptedPath.startsWith('/driver')) {
      if (isAdmin(userRole)) return null; // Admins can access driver routes
      if (isDriver(userRole)) {
        // Drivers can't access earnings immediately in this mock setup
        if (attemptedPath == '/driver-earnings' && userRole != 'admin') return '/';
        return null;
      }
      return '/driver-selection';
    }

    return null; // Unprotected routes
  }
}
