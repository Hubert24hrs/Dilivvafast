import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

/// Order status transitions.
///
/// These mirror what firestore.rules allows a driver to do. If the transition
/// table changes, the rules have to change with it — a status the client can
/// reach but the rules reject shows up as a silent permission error mid
/// delivery.
void main() {
  CourierOrderModel orderWith(OrderStatus status) {
    final now = DateTime(2026, 1, 1);
    return CourierOrderModel(
      id: 'order_1',
      userId: 'customer_1',
      status: status,
      pickupAddress: '12 Awolowo Road, Ikoyi',
      pickupGeoPoint: const GeoPoint(6.4541, 3.4316),
      dropoffAddress: '5 Adeola Odeku, Victoria Island',
      dropoffGeoPoint: const GeoPoint(6.4281, 3.4219),
      packageDescription: 'Documents',
      recipientName: 'Ada',
      recipientPhone: '+2348012345678',
      trackingCode: 'DVF-001',
      createdAt: now,
      updatedAt: now,
    );
  }

  group('CourierOrderModel.canTransitionTo', () {
    test('a pending order can be accepted or cancelled', () {
      final order = orderWith(OrderStatus.pending);

      expect(order.canTransitionTo(OrderStatus.accepted), isTrue);
      expect(order.canTransitionTo(OrderStatus.cancelled), isTrue);
    });

    test('a pending order cannot jump straight to delivered', () {
      final order = orderWith(OrderStatus.pending);

      expect(order.canTransitionTo(OrderStatus.delivered), isFalse);
      expect(order.canTransitionTo(OrderStatus.pickedUp), isFalse);
      expect(order.canTransitionTo(OrderStatus.inTransit), isFalse);
    });

    test('an accepted order moves to picked up, not straight to transit', () {
      final order = orderWith(OrderStatus.accepted);

      expect(order.canTransitionTo(OrderStatus.pickedUp), isTrue);
      expect(order.canTransitionTo(OrderStatus.inTransit), isFalse);
    });

    test('a collected package can no longer be cancelled from the client', () {
      // Cancelling after pickup is a refund decision, so it goes through the
      // cancelOrder Cloud Function rather than a status write.
      expect(
        orderWith(OrderStatus.pickedUp).canTransitionTo(OrderStatus.cancelled),
        isFalse,
      );
      expect(
        orderWith(OrderStatus.inTransit).canTransitionTo(OrderStatus.cancelled),
        isFalse,
      );
    });

    test('a delivery in transit can succeed or fail', () {
      final order = orderWith(OrderStatus.inTransit);

      expect(order.canTransitionTo(OrderStatus.delivered), isTrue);
      expect(order.canTransitionTo(OrderStatus.failed), isTrue);
    });

    test('terminal states accept nothing', () {
      for (final terminal in [
        OrderStatus.delivered,
        OrderStatus.cancelled,
        OrderStatus.failed,
      ]) {
        final order = orderWith(terminal);
        for (final target in OrderStatus.values) {
          expect(
            order.canTransitionTo(target),
            isFalse,
            reason: '$terminal should not transition to $target',
          );
        }
      }
    });

    test('an order cannot transition to its own status', () {
      for (final status in OrderStatus.values) {
        expect(
          orderWith(status).canTransitionTo(status),
          isFalse,
          reason: '$status should not transition to itself',
        );
      }
    });
  });

  group('driver location', () {
    test('is absent until a driver publishes one', () {
      // The customer's tracking map reads this field; null means "no driver
      // position yet" rather than an error.
      expect(orderWith(OrderStatus.pending).driverLocation, isNull);
    });

    test('round-trips through the model', () {
      final order = orderWith(
        OrderStatus.inTransit,
      ).copyWith(driverLocation: const GeoPoint(6.5, 3.35));

      expect(order.driverLocation?.latitude, 6.5);
      expect(order.driverLocation?.longitude, 3.35);
    });
  });
}
