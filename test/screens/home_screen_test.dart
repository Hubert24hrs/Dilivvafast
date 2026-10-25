import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dilivvafast/core/presentation/components/app_drawer.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/widgets/live_map.dart';
import 'package:dilivvafast/features/home/presentation/screens/home_screen.dart';

import '../support/harness.dart';

/// The inDrive-style home: map on top, one panel underneath, navigation in
/// the side menu rather than an app bar or tab bar.
void main() {
  group('HomeScreen (inDrive layout)', () {
    Future<void> pumpHome(WidgetTester tester) async {
      // A phone-sized surface, so the panel lays out as it would on a device.
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wrapScreen(const HomeScreen()));
      await tester.pump();
    }

    testWidgets('has no app bar — the map runs to the top', (tester) async {
      await pumpHome(tester);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(LiveMap), findsOneWidget);
    });

    testWidgets('the menu button opens the side menu', (tester) async {
      await pumpHome(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isA<AppDrawer>());

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      expect(find.byType(AppDrawer), findsOneWidget);
    });

    testWidgets('offers a bike or car courier, bike first', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHome(tester);

      expect(find.text('Bike'), findsOneWidget);
      expect(find.text('Car'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Bike courier'))),
        isSemantics(isSelected: true, isButton: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Car courier'))),
        isSemantics(isSelected: false, isButton: true),
      );
      semantics.dispose();
    });

    testWidgets('choosing car moves the selection', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHome(tester);

      await tester.tap(find.text('Car'));
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Car courier'))),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Bike courier'))),
        isSemantics(isSelected: false),
      );
      semantics.dispose();
    });

    testWidgets('shows the "Where to & for how much?" entry point', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(find.text('Where to & for how much?'), findsOneWidget);
    });

    testWidgets('pins a pickup point card over the map', (tester) async {
      await pumpHome(tester);
      expect(find.text('Pickup point'), findsOneWidget);
    });

    testWidgets('takes its colours from the active palette', (tester) async {
      await tester.pumpWidget(
        wrapScreen(const HomeScreen(), themeMode: ThemeMode.light),
      );
      await tester.pump();

      final context = tester.element(find.byType(HomeScreen));
      expect(context.palette.surfaceBase, AppTheme.lightPalette.surfaceBase);
    });
  });

  group('AppDrawer (inDrive layout)', () {
    Future<void> pumpDrawer(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        wrapScreen(const Scaffold(body: SizedBox(), drawer: AppDrawer())),
      );
      final state = tester.state<ScaffoldState>(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();
    }

    testWidgets('lists the customer destinations', (tester) async {
      await pumpDrawer(tester);
      for (final label in [
        'City',
        'Request history',
        'Couriers',
        'Saved addresses',
        'Promotions',
        'Refer & earn',
        'Notifications',
        'Safety',
        'Settings',
        'Help',
        'Support',
      ]) {
        // The list is longer than a phone screen; it scrolls, as inDrive's
        // does, and builds rows lazily.
        await tester.scrollUntilVisible(
          find.text(label),
          120,
          scrollable: find.descendant(
            of: find.byType(Drawer),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('ends with the Driver mode button', (tester) async {
      await pumpDrawer(tester);
      expect(find.widgetWithText(FilledButton, 'Driver mode'), findsOneWidget);
    });

    testWidgets('hides social icons until real URLs are configured', (
      tester,
    ) async {
      await pumpDrawer(tester);
      expect(find.byTooltip('Facebook'), findsNothing);
      expect(find.byTooltip('Instagram'), findsNothing);
    });
  });
}
