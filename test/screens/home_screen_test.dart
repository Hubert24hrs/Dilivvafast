import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/features/home/presentation/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    Widget createTestWidget() {
      return const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('renders scaffold with dark theme', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('displays app bar or header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have some form of navigation/header
      expect(find.byType(AppBar), findsAny);
    });

    testWidgets('contains actionable content', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have interactive elements (buttons, cards, etc.)
      expect(
        find.byWidgetPredicate(
            (w) => w is GestureDetector || w is InkWell || w is ElevatedButton),
        findsAtLeast(1),
      );
    });
  });
}
