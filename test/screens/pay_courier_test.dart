import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:dilivvafast/core/domain/entities/bank_account.dart';
import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/features/courier/domain/repositories/i_courier_repository.dart';
import 'package:dilivvafast/features/courier/presentation/widgets/pay_courier_card.dart';

/// Paying the courier directly — cash, or a bank transfer to the courier's
/// own account. There is no wallet.

const _bank = BankAccount(
  bankName: 'GTBank',
  accountNumber: '0123456789',
  accountName: 'Musa Bello',
);

CourierOrderModel _order({
  OrderStatus status = OrderStatus.delivered,
  PaymentMethod method = PaymentMethod.transfer,
  PaymentStatus payment = PaymentStatus.pending,
  BankAccount? bank = _bank,
}) => CourierOrderModel(
  id: 'o1',
  userId: 'customer-1',
  driverId: 'driver-1',
  status: status,
  pickupAddress: '1 Marina, Lagos',
  pickupGeoPoint: const GeoPoint(6.4541, 3.3947),
  dropoffAddress: '12 Awolowo Rd, Ikoyi',
  dropoffGeoPoint: const GeoPoint(6.4478, 3.4342),
  packageDescription: 'Documents',
  recipientName: 'Ada',
  recipientPhone: '+2348000000000',
  trackingCode: 'DF-1',
  totalFare: 1500,
  paymentMethod: method,
  paymentStatus: payment,
  courierBank: bank,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

class _PayRepo implements ICourierRepository {
  final calls = <String>[];

  @override
  Future<Either<Failure, Unit>> setPaymentMethod(
    String orderId,
    PaymentMethod method,
  ) async {
    calls.add('method:${method.name}');
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> markPaymentSent(String orderId) async {
    calls.add('sent');
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> confirmPaymentReceived(String orderId) async {
    calls.add('paid');
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget child, _PayRepo repo) => ProviderScope(
  overrides: [courierRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  ),
);

void main() {
  group('BankAccount', () {
    test('needs a bank, a 10-digit NUBAN and a name', () {
      expect(_bank.isComplete, isTrue);
      expect(BankAccount.isValidAccountNumber('012345678'), isFalse);
      expect(BankAccount.isValidAccountNumber('01234567890'), isFalse);
      expect(BankAccount.isValidAccountNumber('01234a6789'), isFalse);
    });

    test('reads from a Firestore map, and absent or empty is null', () {
      expect(BankAccount.fromMap(_bank.toMap()), _bank);
      expect(BankAccount.fromMap(null), isNull);
      expect(BankAccount.fromMap(<String, dynamic>{}), isNull);
    });
  });

  group('Payment on old orders', () {
    test('"wallet" and "card" orders read as cash', () {
      for (final legacy in ['wallet', 'card']) {
        final json = _order().toFirestore()
          ..['id'] = 'o1'
          ..['paymentMethod'] = legacy
          ..['courierBank'] = null;
        expect(
          CourierOrderModel.fromJson(json).paymentMethod,
          PaymentMethod.cash,
        );
      }
    });
  });

  group('Customer: Pay your courier', () {
    testWidgets('a transfer shows the courier account and "I\'ve sent"', (
      tester,
    ) async {
      final repo = _PayRepo();
      await tester.pumpWidget(_wrap(PayCourierCard(order: _order()), repo));

      expect(find.text('Pay your courier'), findsOneWidget);
      expect(find.text('₦1500'), findsOneWidget);
      expect(find.text('GTBank'), findsOneWidget);
      expect(find.text('0123456789'), findsOneWidget);
      expect(find.text('Musa Bello'), findsOneWidget);

      await tester.tap(find.text("I've sent ₦1500"));
      await tester.pump();
      expect(repo.calls, ['sent']);
    });

    testWidgets('cash says to hand it over, with no bank details', (
      tester,
    ) async {
      final repo = _PayRepo();
      await tester.pumpWidget(
        _wrap(PayCourierCard(order: _order(method: PaymentMethod.cash)), repo),
      );
      expect(find.textContaining('in cash'), findsOneWidget);
      expect(find.text('0123456789'), findsNothing);

      await tester.tap(find.text('Bank transfer'));
      await tester.pump();
      expect(repo.calls, ['method:transfer']);
    });

    testWidgets('no saved account: pay cash or ask in chat', (tester) async {
      await tester.pumpWidget(
        _wrap(PayCourierCard(order: _order(bank: null)), _PayRepo()),
      );
      expect(
        find.textContaining("hasn't added a bank account"),
        findsOneWidget,
      );
      expect(find.textContaining("I've sent"), findsNothing);
    });

    testWidgets('after "sent", waits for the courier', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PayCourierCard(order: _order(payment: PaymentStatus.sent)),
          _PayRepo(),
        ),
      );
      expect(find.textContaining('waiting for your courier'), findsOneWidget);
      expect(find.textContaining("I've sent"), findsNothing);
    });

    testWidgets('paid is shown as done', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PayCourierCard(order: _order(payment: PaymentStatus.paid)),
          _PayRepo(),
        ),
      );
      expect(find.textContaining('Paid ₦1500'), findsOneWidget);
    });

    test('shown once the courier has the package, not before', () {
      expect(showPayCourier(_order(status: OrderStatus.accepted)), isFalse);
      expect(showPayCourier(_order(status: OrderStatus.arrived)), isFalse);
      expect(showPayCourier(_order(status: OrderStatus.pickedUp)), isTrue);
      expect(showPayCourier(_order(status: OrderStatus.inTransit)), isTrue);
      expect(showPayCourier(_order(status: OrderStatus.delivered)), isTrue);
      expect(showPayCourier(_order(status: OrderStatus.cancelled)), isFalse);
    });
  });

  group('Courier: collect payment', () {
    testWidgets('a sent transfer is confirmed after a check', (tester) async {
      final repo = _PayRepo();
      await tester.pumpWidget(
        _wrap(
          CollectPaymentCard(order: _order(payment: PaymentStatus.sent)),
          repo,
        ),
      );
      expect(find.textContaining('says they have sent ₦1500'), findsOneWidget);

      await tester.tap(find.text("I've received ₦1500"));
      await tester.pumpAndSettle();
      expect(find.text('Received ₦1500?'), findsOneWidget);
      await tester.tap(find.text('Yes, I received it'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['paid']);
    });

    testWidgets('cash: collect it', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CollectPaymentCard(order: _order(method: PaymentMethod.cash)),
          _PayRepo(),
        ),
      );
      expect(
        find.text('Collect ₦1500 in cash from the customer.'),
        findsOneWidget,
      );
    });

    testWidgets('transfer with no saved account offers to add one', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(CollectPaymentCard(order: _order(bank: null)), _PayRepo()),
      );
      expect(find.text('Add bank account'), findsOneWidget);
    });
  });
}
