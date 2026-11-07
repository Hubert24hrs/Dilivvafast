import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/infrastructure/notification/fcm_service.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/features/courier/domain/repositories/i_courier_repository.dart';
import 'package:dilivvafast/features/courier/presentation/screens/tracking_screen.dart';
import 'package:dilivvafast/features/driver/presentation/screens/driver_active_delivery_screen.dart';
import 'package:dilivvafast/features/rating/presentation/screens/rating_screen.dart';

/// The screens on the pickup → delivered → rated path.
///
/// The backend half of this flow is exercised end to end against staging by
/// test/e2e/delivery_flow.mjs. These cover the UI half: that each status
/// shows the right action, that the driver cannot skip a state, and that a
/// finished delivery offers the customer a rating.

const _driver = 'driver-1';

CourierOrderModel _order(
  OrderStatus status, {
  String? driverId = _driver,
  int? rating,
}) => CourierOrderModel(
  id: 'o1',
  userId: 'customer-1',
  driverId: driverId,
  status: status,
  pickupAddress: '1 Marina, Lagos',
  pickupGeoPoint: const GeoPoint(6.4541, 3.3947),
  dropoffAddress: '12 Awolowo Rd, Ikoyi',
  dropoffGeoPoint: const GeoPoint(6.4478, 3.4342),
  packageDescription: 'Documents',
  recipientName: 'Ada',
  recipientPhone: '+2348000000000',
  trackingCode: 'DF-1',
  totalFare: 1400,
  driverEarnings: 1120,
  rating: rating,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

/// Records status updates; each takes a moment, like a network call.
class _FakeRepo implements ICourierRepository {
  final updates = <OrderStatus>[];
  final ratings = <(int, List<String>)>[];

  @override
  Future<Either<Failure, Unit>> rateOrder(
    String orderId,
    int rating,
    String? comment, {
    List<String> tags = const [],
  }) async {
    ratings.add((rating, tags));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    updates.add(newStatus);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget screen, CourierOrderModel order, _FakeRepo repo) {
  return ProviderScope(
    overrides: [
      orderStreamProvider('o1').overrideWith((ref) => Stream.value(order)),
      currentUserIdProvider.overrideWithValue(_driver),
      driverLocationProvider(_driver).overrideWith((ref) => Stream.value(null)),
      driverLocationSyncProvider.overrideWithValue(null),
      courierRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(theme: AppTheme.light, home: screen),
  );
}

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('Driver active delivery', () {
    final cases = {
      OrderStatus.accepted: "I've arrived",
      OrderStatus.arrived: 'I have picked up the package',
      OrderStatus.pickedUp: 'Start delivery',
      OrderStatus.inTransit: 'Mark as delivered',
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key.name} shows "${entry.value}"', (tester) async {
        await _phone(tester);
        await tester.pumpWidget(
          _wrap(
            const DriverActiveDeliveryScreen(orderId: 'o1'),
            _order(entry.key),
            _FakeRepo(),
          ),
        );
        await tester.pump();
        expect(find.text(entry.value), findsOneWidget);
      });
    }

    testWidgets('a double tap advances the job exactly one step', (
      tester,
    ) async {
      await _phone(tester);
      final repo = _FakeRepo();
      await tester.pumpWidget(
        _wrap(
          const DriverActiveDeliveryScreen(orderId: 'o1'),
          _order(OrderStatus.accepted),
          repo,
        ),
      );
      await tester.pump();

      final button = find.text("I've arrived");
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 50));
      // The button is now busy; a second tap must not send another update.
      await tester.tap(find.byType(FilledButton).last, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(repo.updates, [OrderStatus.arrived]);
    });

    testWidgets('a courier can drop the job only before pickup', (
      tester,
    ) async {
      await _phone(tester);
      for (final (status, offered) in [
        (OrderStatus.accepted, true),
        (OrderStatus.arrived, true),
        (OrderStatus.pickedUp, false),
        (OrderStatus.inTransit, false),
      ]) {
        // A fresh scope per status: re-pumping one ProviderScope keeps the
        // first order's stream.
        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey(status),
            child: _wrap(
              const DriverActiveDeliveryScreen(orderId: 'o1'),
              _order(status),
              _FakeRepo(),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.text('Cancel job'),
          offered ? findsOneWidget : findsNothing,
          reason: status.name,
        );
      }
    });

    testWidgets('marking delivered asks for confirmation first', (
      tester,
    ) async {
      await _phone(tester);
      final repo = _FakeRepo();
      await tester.pumpWidget(
        _wrap(
          const DriverActiveDeliveryScreen(orderId: 'o1'),
          _order(OrderStatus.inTransit),
          repo,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Mark as delivered'));
      await tester.pumpAndSettle();
      expect(find.text('Mark as delivered?'), findsOneWidget);

      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(repo.updates, isEmpty, reason: 'cancelling must not deliver');

      await tester.tap(find.text('Mark as delivered'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, delivered'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.updates, [OrderStatus.delivered]);
    });

    testWidgets('a delivered job asks the courier to collect payment', (
      tester,
    ) async {
      await _phone(tester);
      await tester.pumpWidget(
        _wrap(
          const DriverActiveDeliveryScreen(orderId: 'o1'),
          _order(OrderStatus.delivered),
          _FakeRepo(),
        ),
      );
      await tester.pump();
      // The customer pays the courier directly: no wallet payout.
      expect(find.text('Delivered — collect ₦1400'), findsOneWidget);
      expect(find.text("I've received ₦1400"), findsOneWidget);
      expect(find.text('Back to requests'), findsOneWidget);
    });

    testWidgets("another courier's job is not shown", (tester) async {
      await _phone(tester);
      await tester.pumpWidget(
        _wrap(
          const DriverActiveDeliveryScreen(orderId: 'o1'),
          _order(OrderStatus.accepted, driverId: 'someone-else'),
          _FakeRepo(),
        ),
      );
      await tester.pump();
      expect(
        find.text('This job is assigned to another courier.'),
        findsOneWidget,
      );
    });
  });

  group('Customer tracking', () {
    testWidgets('leads with what is happening now', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(
        _wrap(
          const TrackingScreen(orderId: 'o1'),
          _order(OrderStatus.arrived),
          _FakeRepo(),
        ),
      );
      await tester.pump();
      expect(find.text('Your courier has arrived'), findsOneWidget);
    });

    testWidgets('can be cancelled until the courier has the package', (
      tester,
    ) async {
      await _phone(tester);
      for (final (status, offered) in [
        (OrderStatus.accepted, true),
        (OrderStatus.arrived, true),
        (OrderStatus.pickedUp, false),
        (OrderStatus.delivered, false),
      ]) {
        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey(status),
            child: _wrap(
              const TrackingScreen(orderId: 'o1'),
              _order(status),
              _FakeRepo(),
            ),
          ),
        );
        await tester.pump();
        // The sheet builds lazily; scroll to its end before looking.
        await tester.drag(find.byType(ListView), const Offset(0, -3000));
        await tester.pump();
        final cancel = find.text('Cancel delivery');
        expect(
          cancel,
          offered ? findsOneWidget : findsNothing,
          reason: status.name,
        );
      }
    });

    test('share text says where the delivery is up to', () {
      final text = shareTextFor(_order(OrderStatus.arrived));
      expect(text, contains('Your courier has arrived'));
      expect(text, contains('DF-1'));
    });

    testWidgets('offers a rating once delivered', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(
        _wrap(
          const TrackingScreen(orderId: 'o1'),
          _order(OrderStatus.delivered),
          _FakeRepo(),
        ),
      );
      await tester.pump();
      // Paying the courier comes first, then the rating below it.
      expect(find.text('Pay your courier'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Rate your courier'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('Rate your courier'), findsOneWidget);
    });

    testWidgets('no rating prompt once rated, or before delivery', (
      tester,
    ) async {
      await _phone(tester);
      await tester.pumpWidget(
        _wrap(
          const TrackingScreen(orderId: 'o1'),
          _order(OrderStatus.delivered, rating: 5),
          _FakeRepo(),
        ),
      );
      await tester.pump();
      expect(find.text('Rate your courier'), findsNothing);

      await tester.pumpWidget(
        _wrap(
          const TrackingScreen(orderId: 'o1'),
          _order(OrderStatus.inTransit),
          _FakeRepo(),
        ),
      );
      await tester.pump();
      expect(find.text('Rate your courier'), findsNothing);
    });
  });

  group('Rating', () {
    testWidgets('compliments appear for a good rating and are sent', (
      tester,
    ) async {
      await _phone(tester);
      final repo = _FakeRepo();
      await tester.pumpWidget(
        _wrap(
          const RatingScreen(orderId: 'o1'),
          _order(OrderStatus.delivered),
          repo,
        ),
      );
      await tester.pump();
      expect(find.text('Fast delivery'), findsNothing);

      await tester.tap(find.byTooltip('5 stars'));
      await tester.pump();
      await tester.tap(find.text('Fast delivery'));
      await tester.pump();
      await tester.tap(find.text('Submit rating'));
      await tester.pump();

      expect(repo.ratings.single.$1, 5);
      expect(repo.ratings.single.$2, ['fast_delivery']);
    });

    testWidgets('no compliments for a poor rating', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(
        _wrap(
          const RatingScreen(orderId: 'o1'),
          _order(OrderStatus.delivered),
          _FakeRepo(),
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('2 stars'));
      await tester.pump();
      expect(find.text('Fast delivery'), findsNothing);
    });
  });

  group('Notification taps', () {
    test('open the screen each notification is about', () {
      expect(notificationRouteFor({'type': 'new_order'}), '/driver/home');
      expect(
        notificationRouteFor({'type': 'new_bid', 'orderId': 'o1'}),
        '/matching/o1',
      );
      expect(
        notificationRouteFor({'type': 'bid_accepted', 'orderId': 'o1'}),
        '/driver/active/o1',
      );
      expect(
        notificationRouteFor({'type': 'order_update', 'orderId': 'o1'}),
        '/customer/track/o1',
      );
      // The wallet is gone, so its old referral-bonus push opens nothing.
      expect(notificationRouteFor({'type': 'referral_bonus'}), isNull);
      expect(
        notificationRouteFor({'type': 'referral_completed'}),
        '/customer/refer',
      );
      expect(
        notificationRouteFor({'type': 'payment_sent', 'orderId': 'o1'}),
        '/driver/active/o1',
      );
      expect(
        notificationRouteFor({'type': 'payment_received', 'orderId': 'o1'}),
        '/customer/track/o1',
      );
      expect(
        notificationRouteFor({'type': 'weekly_report'}),
        '/driver/earnings',
      );
      expect(notificationRouteFor({'type': 'sos_alert'}), '/admin/dashboard');
      expect(
        notificationRouteFor({'type': 'courier_cancelled', 'orderId': 'o1'}),
        '/matching/o1',
      );
      expect(notificationRouteFor({'type': 'job_cancelled'}), '/driver/home');
      expect(notificationRouteFor({'type': 'support_reply'}), '/support-chat');
      expect(
        notificationRouteFor({'type': 'support_message', 'userId': 'u1'}),
        '/admin/support/u1',
      );
      expect(notificationRouteFor({'type': 'support_message'}), isNull);
    });

    test('an order notification without an order id opens nothing', () {
      expect(notificationRouteFor({'type': 'order_update'}), isNull);
      expect(
        notificationRouteFor({'type': 'bid_accepted', 'orderId': ''}),
        isNull,
      );
      expect(notificationRouteFor({'type': 'something_new'}), isNull);
    });
  });
}
