// Basic Flutter widget test for Fast Delivery app.
//
// Verifies the app can launch without errors.

import 'package:flutter_test/flutter_test.dart';

import 'package:fast_delivery/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: FastDeliveryApp()));

    // Allow async operations to complete
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify the app rendered something (no crash)
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
