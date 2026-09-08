import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

void main() {
  testWidgets('App theme applies correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.futuristicTheme,
          home: const Scaffold(body: Center(child: Text('Dilivvafast'))),
        ),
      ),
    );

    expect(find.text('Dilivvafast'), findsOneWidget);
  });

  test('AppTheme has correct colors', () {
    expect(AppTheme.primaryColor, const Color(0xFFFF6B00));
    expect(AppTheme.secondaryColor, const Color(0xFFFF9500));
    expect(AppTheme.backgroundColor, const Color(0xFF0B0D12));
    // The brand fill carries near-black text in light mode so the exact brand
    // orange can be kept without failing contrast.
    expect(AppTheme.lightPalette.brand, AppTheme.primaryColor);
    expect(AppTheme.lightPalette.onBrand, const Color(0xFF11131A));
  });
}
