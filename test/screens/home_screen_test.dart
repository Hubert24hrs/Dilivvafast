import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dilivvafast/core/presentation/components/app_drawer.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/features/home/presentation/screens/home_screen.dart';

import '../support/harness.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders a scaffold', (tester) async {
      await tester.pumpWidget(wrapScreen(const HomeScreen()));
      await tester.pump();

      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('shows the app bar', (tester) async {
      await tester.pumpWidget(wrapScreen(const HomeScreen()));
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('exposes the drawer that hosts the mode switcher', (
      tester,
    ) async {
      await tester.pumpWidget(wrapScreen(const HomeScreen()));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isA<AppDrawer>());
    });

    testWidgets('contains actionable content', (tester) async {
      await tester.pumpWidget(wrapScreen(const HomeScreen()));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is GestureDetector || w is InkWell || w is ElevatedButton,
        ),
        findsAtLeast(1),
      );
    });

    testWidgets('takes its background from the active palette', (tester) async {
      await tester.pumpWidget(
        wrapScreen(const HomeScreen(), themeMode: ThemeMode.light),
      );
      await tester.pump();

      final context = tester.element(find.byType(HomeScreen));
      expect(context.palette.surfaceBase, AppTheme.lightPalette.surfaceBase);
    });
  });
}
