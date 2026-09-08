import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/features/auth/presentation/screens/login_screen.dart';

import '../support/harness.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(wrapScreen(const LoginScreen()));
      await tester.pump();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(
        find.widgetWithText(TextFormField, 'Email address'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    });

    testWidgets('renders the log in button', (tester) async {
      await tester.pumpWidget(wrapScreen(const LoginScreen()));
      await tester.pump();

      expect(find.byKey(const Key('login_btn')), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    });

    testWidgets('renders app branding', (tester) async {
      await tester.pumpWidget(wrapScreen(const LoginScreen()));
      await tester.pump();

      expect(find.text('Dilivvafast'), findsOneWidget);
    });

    testWidgets('offers a route to sign up', (tester) async {
      await tester.pumpWidget(wrapScreen(const LoginScreen()));
      await tester.pump();

      expect(find.byKey(const Key('toggle_btn')), findsOneWidget);
    });

    testWidgets('validates an empty form instead of submitting', (
      tester,
    ) async {
      await tester.pumpWidget(wrapScreen(const LoginScreen()));
      await tester.pump();

      await tester.tap(find.byKey(const Key('login_btn')));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('password is obscured until the reveal toggle is used', (
      tester,
    ) async {
      await tester.pumpWidget(wrapScreen(const LoginScreen()));
      await tester.pump();

      EditableText passwordField() => tester.widget<EditableText>(
        find.descendant(
          of: find.ancestor(
            of: find.text('Password'),
            matching: find.byType(TextFormField),
          ),
          matching: find.byType(EditableText),
        ),
      );

      expect(passwordField().obscureText, isTrue);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();

      expect(passwordField().obscureText, isFalse);
    });

    testWidgets('renders against the light palette', (tester) async {
      await tester.pumpWidget(
        wrapScreen(const LoginScreen(), themeMode: ThemeMode.light),
      );
      await tester.pump();

      final context = tester.element(find.byType(LoginScreen));
      expect(context.palette.surfaceBase, AppTheme.lightPalette.surfaceBase);
      expect(context.palette.textPrimary, AppTheme.lightPalette.textPrimary);
    });

    testWidgets('renders against the dark palette', (tester) async {
      await tester.pumpWidget(
        wrapScreen(const LoginScreen(), themeMode: ThemeMode.dark),
      );
      await tester.pump();

      final context = tester.element(find.byType(LoginScreen));
      expect(context.palette.surfaceBase, AppTheme.darkPalette.surfaceBase);
      expect(context.palette.textPrimary, AppTheme.darkPalette.textPrimary);
    });
  });
}
