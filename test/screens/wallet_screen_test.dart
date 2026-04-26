import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/features/payment/presentation/screens/wallet_screen.dart';

void main() {
  group('WalletScreen', () {
    Widget createTestWidget() {
      return const ProviderScope(
        child: MaterialApp(
          home: WalletScreen(),
        ),
      );
    }

    testWidgets('renders wallet title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Wallet'), findsAtLeast(1));
    });

    testWidgets('renders balance card area', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show balance-related text
      expect(
        find.byWidgetPredicate(
            (w) => w is Text && w.data?.contains('Balance') == true),
        findsAtLeast(1),
      );
    });

    testWidgets('renders fund wallet button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Fund Wallet'), findsOneWidget);
    });

    testWidgets('renders withdraw button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Withdraw'), findsOneWidget);
    });

    testWidgets('renders transfer button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Transfer'), findsOneWidget);
    });

    testWidgets('renders transactions section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent Transactions'), findsOneWidget);
    });
  });
}
