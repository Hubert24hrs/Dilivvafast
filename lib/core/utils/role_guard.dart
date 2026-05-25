/// Role guard utility for protecting routes based on user roles
class RoleGuard {
  /// Check if the user has the required role
  static bool hasRole(String? userRole, List<String> allowedRoles) {
    if (userRole == null) return false;
    return allowedRoles.contains(userRole);
  }

  /// Check if user is admin
  static bool isAdmin(String? userRole) => userRole == 'admin';

  /// Check if user is driver
  static bool isDriver(String? userRole) => userRole == 'driver';

  /// Check if user is regular user
  static bool isUser(String? userRole) => userRole == 'user';

  /// Get redirect path based on role and attempted route
  static String? getRedirectPath({
    required String? userRole,
    required String attemptedPath,
  }) {
    // Admin routes
    if (attemptedPath.startsWith('/admin')) {
      if (!isAdmin(userRole)) {
        return '/'; // Redirect non-admins to home
      }
    }

    // Driver routes
    if (attemptedPath == '/driver' || attemptedPath.startsWith('/driver-navigation')) {
      if (!isDriver(userRole) && !isAdmin(userRole)) {
        return '/driver-selection'; // Redirect to become a driver
      }
    }

    // Driver earnings and reviews
    if (attemptedPath == '/driver-earnings' || attemptedPath == '/driver-reviews') {
      if (!isDriver(userRole) && !isAdmin(userRole)) {
        return '/';
      }
    }

    return null; // No redirect needed
  }
}
