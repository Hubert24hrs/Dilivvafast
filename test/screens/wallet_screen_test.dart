import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:dilivvafast/presentation/screens/wallet/wallet_screen.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/services/auth_service.dart';
import 'package:dilivvafast/core/services/database_service.dart';
import 'package:dilivvafast/core/models/user_model.dart';

void main() {
  group('WalletScreen', () {
    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService()),
          databaseServiceProvider.overrideWithValue(FakeDatabaseService()),
        ],
        child: const MaterialApp(
          home: WalletScreen(),
        ),
      );
    }

    testWidgets('renders wallet title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('My Wallet'), findsOneWidget);
    });

    testWidgets('renders balance card area', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Should show balance-related text
      expect(
        find.byWidgetPredicate(
            (w) => w is Text && w.data?.contains('Balance') == true),
        findsAtLeast(1),
      );
    });

    testWidgets('renders top up button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Top Up'), findsOneWidget);
    });

    testWidgets('renders history action button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('renders payment methods section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('PAYMENT METHODS'), findsOneWidget);
    });
  });
}

class FakeUser extends Fake implements User {
  @override
  String get uid => 'test_uid';
  @override
  String? get email => 'test@example.com';
}

class FakeAuthService extends Fake implements AuthService {
  @override
  User? get currentUser => FakeUser();
  @override
  Stream<User?> get authStateChanges => Stream.value(FakeUser());
}

class FakeDatabaseService extends Fake implements DatabaseService {
  @override
  Stream<UserModel?> getUserStream(String uid) {
    return Stream.value(UserModel(
      id: uid,
      email: 'test@example.com',
      displayName: 'Test User',
      phoneNumber: '+2348012345678',
      role: 'user',
      walletBalance: 5000.0,
      createdAt: DateTime.now(),
    ));
  }
}
