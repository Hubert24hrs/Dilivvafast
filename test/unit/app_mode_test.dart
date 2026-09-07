import 'package:flutter_test/flutter_test.dart';

import 'package:dilivvafast/features/auth/domain/entities/app_mode.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

UserModel buildUser({
  UserRole role = UserRole.customer,
  ModeAccess driverStatus = ModeAccess.none,
  ModeAccess investorStatus = ModeAccess.none,
  AppMode activeMode = AppMode.customer,
}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    uid: 'u1',
    fullName: 'Ada Obi',
    email: 'ada@example.com',
    phone: '08012345678',
    referralCode: 'ABC12345',
    role: role,
    driverStatus: driverStatus,
    investorStatus: investorStatus,
    activeMode: activeMode,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('registration defaults', () {
    test('a new account is a customer with no other modes unlocked', () {
      final user = buildUser();

      expect(user.role, UserRole.customer);
      expect(user.activeMode, AppMode.customer);
      expect(user.driverStatus, ModeAccess.none);
      expect(user.investorStatus, ModeAccess.none);
    });
  });

  group('accessFor', () {
    test('customer is always granted', () {
      expect(buildUser().accessFor(AppMode.customer), ModeAccess.approved);
    });

    test('driver and investor follow their own status fields', () {
      final user = buildUser(
        driverStatus: ModeAccess.pending,
        investorStatus: ModeAccess.approved,
      );

      expect(user.accessFor(AppMode.driver), ModeAccess.pending);
      expect(user.accessFor(AppMode.investor), ModeAccess.approved);
    });

    test('admin is derived from role, never self-granted', () {
      expect(buildUser().accessFor(AppMode.admin), ModeAccess.none);
      expect(
        buildUser(role: UserRole.admin).accessFor(AppMode.admin),
        ModeAccess.approved,
      );
    });
  });

  group('canEnter', () {
    test('only approved unlocks a mode', () {
      for (final status in ModeAccess.values) {
        final user = buildUser(driverStatus: status);
        expect(
          user.canEnter(AppMode.driver),
          status == ModeAccess.approved,
          reason: 'driverStatus $status',
        );
      }
    });
  });

  group('availableModes', () {
    test('a fresh customer can only be a customer', () {
      expect(buildUser().availableModes, [AppMode.customer]);
    });

    test('an approved driver keeps customer access too', () {
      final user = buildUser(driverStatus: ModeAccess.approved);
      expect(user.availableModes, [AppMode.customer, AppMode.driver]);
    });
  });

  group('effectiveMode', () {
    test('honours activeMode when the user is entitled', () {
      final user = buildUser(
        driverStatus: ModeAccess.approved,
        activeMode: AppMode.driver,
      );
      expect(user.effectiveMode, AppMode.driver);
    });

    test('falls back to customer when entitlement was revoked', () {
      // A driver who was suspended while signed in still has activeMode set.
      final user = buildUser(
        driverStatus: ModeAccess.suspended,
        activeMode: AppMode.driver,
      );
      expect(user.effectiveMode, AppMode.customer);
    });

    test('falls back to customer for a mode never applied for', () {
      final user = buildUser(activeMode: AppMode.investor);
      expect(user.effectiveMode, AppMode.customer);
    });

    test('admins always land on the admin surface', () {
      final user = buildUser(role: UserRole.admin, activeMode: AppMode.customer);
      expect(user.effectiveMode, AppMode.admin);
    });
  });

  group('AppMode metadata', () {
    test('admin is not offered as a switchable mode', () {
      expect(AppMode.switchable, isNot(contains(AppMode.admin)));
      expect(AppMode.switchable,
          [AppMode.customer, AppMode.driver, AppMode.investor]);
    });

    test('every mode has a home route under its own prefix', () {
      for (final mode in AppMode.values) {
        expect(mode.homeRoute, startsWith(mode.routePrefix));
      }
    });
  });

  group('serialisation', () {
    test('mode fields round-trip through JSON', () {
      final user = buildUser(
        driverStatus: ModeAccess.approved,
        investorStatus: ModeAccess.pending,
        activeMode: AppMode.driver,
      );

      final restored = UserModel.fromJson(user.toJson());

      expect(restored.driverStatus, ModeAccess.approved);
      expect(restored.investorStatus, ModeAccess.pending);
      expect(restored.activeMode, AppMode.driver);
    });

    test('documents written before mode fields existed still decode', () {
      final legacy = buildUser().toJson()
        ..remove('driverStatus')
        ..remove('investorStatus')
        ..remove('activeMode');

      final restored = UserModel.fromJson(legacy);

      expect(restored.driverStatus, ModeAccess.none);
      expect(restored.investorStatus, ModeAccess.none);
      expect(restored.activeMode, AppMode.customer);
    });
  });
}
