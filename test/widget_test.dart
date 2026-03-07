// Basic Flutter widget test for Fast Delivery app.
//
// Verifies the app can launch without errors.

import 'package:fast_delivery/features/courier/domain/entities/courier_model.dart';
import 'package:fast_delivery/features/_hidden_rides/domain/entities/ride_model.dart';
import 'package:fast_delivery/features/auth/domain/entities/user_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/features/auth/infrastructure/auth_service.dart';
import 'package:fast_delivery/core/infrastructure/network/database_service.dart';
import 'package:fast_delivery/core/infrastructure/notification/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fast_delivery/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> initialize() async {}
}

class FakeAuthService extends Fake implements AuthService {
  @override
  Stream<User?> get authStateChanges => Stream.value(null);
}

class FakeDatabaseService extends Fake implements DatabaseService {
  @override
  Stream<List<RideModel>> getActiveRides() => Stream.value([]);

  @override
  Stream<List<CourierModel>> getActiveCouriers() => Stream.value([]);

  @override
  Stream<UserModel?> getUserStream(String uid) => Stream.value(null);
}

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        authServiceProvider.overrideWithValue(FakeAuthService()),
        databaseServiceProvider.overrideWithValue(FakeDatabaseService()),
      ],
      child: const FastDeliveryApp(),
    ));

    // Allow async operations to complete
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify the app rendered something (no crash)
    expect(find.byType(FastDeliveryApp), findsOneWidget);
  });
}
