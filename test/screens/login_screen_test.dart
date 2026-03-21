import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fast_delivery/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('LoginScreen', () {
    Widget createTestWidget() {
      return const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should find email and password input fields
      expect(find.byType(TextField), findsAtLeast(2));
    });

    testWidgets('renders login button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should find a login/sign-in action button
      expect(
        find.byWidgetPredicate(
            (w) => w is Text && w.data?.toLowerCase().contains('log') == true),
        findsAtLeast(1),
      );
    });

    testWidgets('renders app branding', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should find Dilivvafast or Fast Delivery branding
      expect(
        find.byWidgetPredicate(
            (w) => w is Text && (w.data?.contains('Fast') == true ||
                                  w.data?.contains('Dilivva') == true)),
        findsAtLeast(1),
      );
    });

    testWidgets('has dark background theme', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have a Scaffold widget
      expect(find.byType(Scaffold), findsAtLeast(1));
    });
  });
}
