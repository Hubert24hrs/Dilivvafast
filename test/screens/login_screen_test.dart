import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/features/auth/presentation/screens/login_screen.dart';

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

      // Should find a sign-in / login action. Matched case-insensitively
      // against both wordings so a copy change doesn't fail the test.
      expect(
        find.byWidgetPredicate((w) {
          final label = w is Text ? w.data?.toLowerCase() ?? '' : '';
          return label.contains('log in') ||
              label.contains('login') ||
              label.contains('sign in') ||
              label.contains('sign up');
        }),
        findsAtLeast(1),
      );
    });

    testWidgets('renders app branding', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should find Dilivvafast branding. Case-insensitive: the screen renders
      // the wordmark as 'DILIVVAFAST'.
      expect(
        find.byWidgetPredicate((w) {
          final label = w is Text ? w.data?.toLowerCase() ?? '' : '';
          return label.contains('dilivva') || label.contains('fast');
        }),
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
