import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dilivvafast/features/auth/domain/entities/app_mode.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

/// The production project was first used by an earlier version of the app.
/// Its profiles have a different shape, and reading them used to throw —
/// which signed the user out as far as the app was concerned ("You need to
/// be signed in to switch modes") and broke the profile screen.
void main() {
  group('Profiles written by the first version of the app', () {
    // The exact field layout of the old production profiles.
    Map<String, dynamic> legacy({String role = 'user', Object? driverStatus}) =>
        {
          'displayName': 'iheanacho hubert',
          'email': 'someone@example.com',
          'phoneNumber': '+2348000000000',
          'photoUrl': null,
          'createdAt': '2025-12-03T10:15:30.000Z',
          'role': role,
          'walletBalance': 0,
          'homeAddress': '1 Somewhere St',
          'workAddress': null,
          'fcmToken': 'tok',
          'referralCode': 'ABC123',
          'driverStatus': ?driverStatus,
        };

    test('decode, with the name and phone carried over', () {
      final user = UserModel.fromJson(normalizeUserData(legacy(), 'u1'));
      expect(user.uid, 'u1');
      expect(user.fullName, 'iheanacho hubert');
      expect(user.phone, '+2348000000000');
      expect(user.role, UserRole.customer);
      expect(
        user.createdAt.isAtSameMomentAs(DateTime.utc(2025, 12, 3, 10, 15, 30)),
        isTrue,
      );
    });

    test('an approved old driver can enter driver mode', () {
      final user = UserModel.fromJson(
        normalizeUserData(
          legacy(role: 'driver', driverStatus: 'approved'),
          'u2',
        ),
      );
      expect(user.role, UserRole.driver);
      expect(user.canEnter(AppMode.driver), isTrue);
    });

    test('unknown values fall back to defaults instead of failing', () {
      final data = legacy(role: 'superuser', driverStatus: 'yes')
        ..['activeMode'] = 'rider'
        ..['rating'] = 'five'
        ..remove('email')
        ..remove('referralCode')
        ..remove('createdAt');
      final user = UserModel.fromJson(normalizeUserData(data, 'u3'));
      expect(user.role, UserRole.customer);
      expect(user.driverStatus, ModeAccess.none);
      expect(user.activeMode, AppMode.customer);
      expect(user.rating, 0);
      expect(user.email, '');
      expect(user.referralCode, '');
    });

    test('current profiles are unchanged', () {
      final now = Timestamp.fromDate(DateTime.utc(2026, 11, 8));
      final user = UserModel.fromJson(
        normalizeUserData({
          'fullName': 'Ada Obi',
          'email': 'ada@example.com',
          'phone': '+2348011111111',
          'referralCode': 'ADA1',
          'role': 'customer',
          'driverStatus': 'pending',
          'createdAt': now,
          'updatedAt': now,
        }, 'u4'),
      );
      expect(user.fullName, 'Ada Obi');
      expect(user.driverStatus, ModeAccess.pending);
      expect(
        user.createdAt.isAtSameMomentAs(DateTime.utc(2026, 11, 8)),
        isTrue,
      );
    });
  });
}
