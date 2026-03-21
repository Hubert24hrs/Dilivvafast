import 'package:flutter_test/flutter_test.dart';
import 'package:fast_delivery/features/auth/domain/entities/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create a valid UserModel', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: 'test-uid',
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '+2348012345678',
        role: UserRole.customer,
        referralCode: 'ABC12345',
        createdAt: now,
        updatedAt: now,
      );

      expect(user.uid, 'test-uid');
      expect(user.fullName, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.role, UserRole.customer);
      expect(user.isVerified, false);
      expect(user.walletBalance, 0.0);
    });

    test('should support copyWith', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: 'test-uid',
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '+2348012345678',
        referralCode: 'ABC12345',
        createdAt: now,
        updatedAt: now,
      );

      final updatedUser = user.copyWith(fullName: 'Updated User');
      expect(updatedUser.fullName, 'Updated User');
      expect(updatedUser.email, 'test@example.com');
    });

    test('should convert to Firestore map', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: 'test-uid',
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '+2348012345678',
        referralCode: 'ABC12345',
        createdAt: now,
        updatedAt: now,
      );

      final map = user.toFirestore();
      expect(map['fullName'], 'Test User');
      expect(map['email'], 'test@example.com');
      expect(map['role'], 'customer');
    });
  });
}
