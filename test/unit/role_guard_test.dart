import 'package:fast_delivery/core/utils/role_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoleGuard', () {
    group('hasRole', () {
      test('returns false for null user role', () {
        expect(RoleGuard.hasRole(null, ['admin', 'driver']), false);
      });

      test('returns true when user has allowed role', () {
        expect(RoleGuard.hasRole('admin', ['admin', 'driver']), true);
        expect(RoleGuard.hasRole('driver', ['admin', 'driver']), true);
      });

      test('returns false when user does not have allowed role', () {
        expect(RoleGuard.hasRole('user', ['admin', 'driver']), false);
      });
    });

    group('isAdmin', () {
      test('returns true for admin role', () {
        expect(RoleGuard.isAdmin('admin'), true);
      });

      test('returns false for non-admin roles', () {
        expect(RoleGuard.isAdmin('user'), false);
        expect(RoleGuard.isAdmin('driver'), false);
        expect(RoleGuard.isAdmin(null), false);
      });
    });

    group('isDriver', () {
      test('returns true for driver role', () {
        expect(RoleGuard.isDriver('driver'), true);
      });

      test('returns false for non-driver roles', () {
        expect(RoleGuard.isDriver('user'), false);
        expect(RoleGuard.isDriver('admin'), false);
        expect(RoleGuard.isDriver(null), false);
      });
    });

    group('isUser', () {
      test('returns true for user role', () {
        expect(RoleGuard.isUser('user'), true);
      });

      test('returns false for non-user roles', () {
        expect(RoleGuard.isUser('driver'), false);
        expect(RoleGuard.isUser('admin'), false);
        expect(RoleGuard.isUser(null), false);
      });
    });

    group('getRedirectPath', () {
      test('redirects regular users from admin routes', () {
        expect(
          RoleGuard.getRedirectPath(userRole: 'user', attemptedPath: '/admin'),
          '/',
        );
      });

      test('allows admin to access admin routes', () {
        expect(
          RoleGuard.getRedirectPath(userRole: 'admin', attemptedPath: '/admin'),
          null,
        );
      });

      test('redirects regular users from driver dashboard', () {
        expect(
          RoleGuard.getRedirectPath(userRole: 'user', attemptedPath: '/driver'),
          '/driver-selection',
        );
      });

      test('allows drivers to access driver routes', () {
        expect(
          RoleGuard.getRedirectPath(userRole: 'driver', attemptedPath: '/driver'),
          null,
        );
      });

      test('allows admins to access driver routes', () {
        expect(
          RoleGuard.getRedirectPath(userRole: 'admin', attemptedPath: '/driver'),
          null,
        );
      });

      test('redirects users from driver earnings', () {
        expect(
          RoleGuard.getRedirectPath(userRole: 'user', attemptedPath: '/driver-earnings'),
          '/',
        );
      });

      test('returns null for unprotected routes', () {
        expect(
          RoleGuard.getRedirectPath(userRole: 'user', attemptedPath: '/'),
          null,
        );
        expect(
          RoleGuard.getRedirectPath(userRole: 'user', attemptedPath: '/profile'),
          null,
        );
      });
    });
  });
}
