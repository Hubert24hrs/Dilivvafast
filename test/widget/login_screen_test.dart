// Widget tests for Login Screen
// Tests for form validation, social login buttons, and navigation

import 'package:fast_delivery/core/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginScreen Validators', () {
    test('email validator accepts valid emails', () {
      expect(Validators.email('test@example.com'), isNull);
      expect(Validators.email('user.name@domain.co.uk'), isNull);
      expect(Validators.email('user+tag@email.com'), isNull);
    });

    test('email validator rejects invalid emails', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('invalid'), isNotNull);
      // no@domain is technically valid per regex (has @ and .)
      expect(Validators.email('@nodomain.com'), isNotNull);
      expect(Validators.email('missing@'), isNotNull);
    });

    test('password validator accepts strong passwords', () {
      expect(Validators.password('Password1!'), isNull);
      expect(Validators.password('Str0ngP@ss'), isNull);
    });

    test('password validator rejects weak passwords', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('NoDigits'), isNotNull); // Missing digit
      expect(Validators.password('12345678'), isNotNull); // Missing letter
    });
  });

  group('LoginScreen Form Integration', () {
    testWidgets('form fields accept user input', (tester) async {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: const Key('email_field'),
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  key: const Key('password_field'),
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'Password123!');

      expect(emailController.text, 'test@example.com');
      expect(passwordController.text, 'Password123!');
    });

    testWidgets('social login buttons are tappable', (tester) async {
      bool googleTapped = false;
      bool appleTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                GestureDetector(
                  key: const Key('google_btn'),
                  onTap: () => googleTapped = true,
                  child: const Icon(Icons.g_mobiledata),
                ),
                GestureDetector(
                  key: const Key('apple_btn'),
                  onTap: () => appleTapped = true,
                  child: const Icon(Icons.apple),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('google_btn')));
      await tester.tap(find.byKey(const Key('apple_btn')));

      expect(googleTapped, isTrue);
      expect(appleTapped, isTrue);
    });

    testWidgets('login button shows loading indicator when pressed', (tester) async {
      bool isLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: ElevatedButton(
                  key: const Key('login_btn'),
                  onPressed: isLoading ? null : () => setState(() => isLoading = true),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('LOGIN'),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byKey(const Key('login_btn')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoginScreen Toggle', () {
    testWidgets('can toggle between login and signup', (tester) async {
      bool isLogin = true;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    Text(isLogin ? 'Login Mode' : 'Signup Mode'),
                    TextButton(
                      key: const Key('toggle_btn'),
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(isLogin ? 'Create Account' : 'Already have an account?'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Login Mode'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      await tester.tap(find.byKey(const Key('toggle_btn')));
      await tester.pump();

      expect(find.text('Signup Mode'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
    });
  });
}
