import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_delivery/core/presentation/theme/app_theme.dart';

void main() {
  testWidgets('App theme applies correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.futuristicTheme,
          home: const Scaffold(
            body: Center(
              child: Text('Dilivvafast'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Dilivvafast'), findsOneWidget);
  });

  test('AppTheme has correct colors', () {
    expect(AppTheme.primaryColor, const Color(0xFF00F0FF));
    expect(AppTheme.secondaryColor, const Color(0xFFFF00AA));
    expect(AppTheme.backgroundColor, const Color(0xFF0A0E21));
  });
}
