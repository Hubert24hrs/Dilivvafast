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
    // Driver earnings are hidden until driver verification is modeled here.
    if (attemptedPath == '/driver-earnings') {
      return isAdmin(userRole) ? null : '/';
    }

    // Admin routes
    if (attemptedPath.startsWith('/admin')) {
      return isAdmin(userRole) ? null : '/';
    }

    // Driver routes
    if (attemptedPath.startsWith('/driver')) {
      if (isAdmin(userRole)) return null; // Admins can access driver routes
      if (isDriver(userRole)) return null;
      return '/driver-selection';
    }

    return null; // Unprotected routes
  }
}
