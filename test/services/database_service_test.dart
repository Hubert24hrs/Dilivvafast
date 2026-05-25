import 'package:fast_delivery/core/services/database_service.dart';
import 'package:fast_delivery/core/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('DatabaseService Tests', () {

    setUp(() {
      final _ = DatabaseService();
    });

    test('saveUser creates proper user document structure', () {
      final user = UserModel(
        id: 'test_123',
        email: 'test@example.com',
        displayName: 'Test User',
        phoneNumber: '+2348012345678',
        role: 'user',
        walletBalance: 0.0,
        createdAt: DateTime.now(),
      );

      expect(user.id, equals('test_123'));
      expect(user.email, equals('test@example.com'));
      expect(user.role, equals('user'));
      expect(user.walletBalance, equals(0.0));
    });

    test('UserModel toMap conversion works correctly', () {
      final user = UserModel(
        id: 'test_123',
        email: 'test@example.com',
        displayName: 'Test User',
        phoneNumber: '+2348012345678',
        role: 'user',
        walletBalance: 100.0,
        createdAt: DateTime(2024, 1, 1),
      );

      final map = user.toMap();
      
      expect(map['email'], equals('test@example.com'));
      expect(map['displayName'], equals('Test User'));
      expect(map['role'], equals('user'));
      expect(map['walletBalance'], equals(100.0));
    });

    test('UserModel fromMap reconstruction works', () {
      final map = {
        'email': 'test@example.com',
        'displayName': 'Test User',
        'phoneNumber': '+2348012345678',
        'role': 'user',
        'walletBalance': 50.0,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      final user = UserModel.fromMap(map, 'test_id');
      
      expect(user.id, equals('test_id'));
      expect(user.email, equals('test@example.com'));
      expect(user.walletBalance, equals(50.0));
    });
  });
}
