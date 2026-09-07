import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

/// Regression tests for the OrderStatus wire format.
///
/// The enum declares `@JsonValue('picked_up')` / `@JsonValue('in_transit')`,
/// but `toFirestore()` used to serialise with `.name`, producing `pickedUp` /
/// `inTransit`. Writes and reads therefore disagreed on the two mid-delivery
/// states, and an order that reached either could not be decoded again.
void main() {
  CourierOrderModel buildOrder({OrderStatus status = OrderStatus.pending}) {
    return CourierOrderModel(
      id: 'order-1',
      userId: 'customer-1',
      status: status,
      pickupAddress: '1 Marina, Lagos',
      pickupGeoPoint: const GeoPoint(6.4541, 3.3947),
      dropoffAddress: '12 Awolowo Rd, Ikoyi',
      dropoffGeoPoint: const GeoPoint(6.4478, 3.4342),
      packageDescription: 'Documents',
      recipientName: 'Ada',
      recipientPhone: '+2348000000000',
      trackingCode: 'DF-TEST-1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  group('OrderStatus wire format', () {
    test('serialises the snake_case @JsonValue, not the Dart enum name', () {
      expect(OrderStatus.pickedUp.wireValue, 'picked_up');
      expect(OrderStatus.inTransit.wireValue, 'in_transit');
      expect(OrderStatus.pending.wireValue, 'pending');
      expect(OrderStatus.delivered.wireValue, 'delivered');
    });

    test('toFirestore writes the wire value for every status', () {
      for (final status in OrderStatus.values) {
        final map = buildOrder(status: status).toFirestore();
        expect(map['status'], status.wireValue,
            reason: '$status must serialise to its @JsonValue');
      }
    });

    test('toFirestore output round-trips back through fromJson', () {
      // This is the assertion that would have caught the original bug: a
      // pickedUp order serialised to `pickedUp`, which fromJson rejected.
      for (final status in OrderStatus.values) {
        final map = buildOrder(status: status).toFirestore();
        map['id'] = 'order-1';
        // Timestamps come back as Timestamp from Firestore.
        map['createdAt'] = Timestamp.fromDate(DateTime.utc(2026, 1, 1));
        map['updatedAt'] = Timestamp.fromDate(DateTime.utc(2026, 1, 1));

        final decoded = CourierOrderModel.fromJson(map);
        expect(decoded.status, status);
      }
    });

    test('orderStatusFromWire accepts the canonical snake_case form', () {
      expect(orderStatusFromWire('picked_up'), OrderStatus.pickedUp);
      expect(orderStatusFromWire('in_transit'), OrderStatus.inTransit);
      expect(orderStatusFromWire('delivered'), OrderStatus.delivered);
    });

    test('orderStatusFromWire still accepts legacy camelCase documents', () {
      // Written by builds that used `.name`; must keep loading.
      expect(orderStatusFromWire('pickedUp'), OrderStatus.pickedUp);
      expect(orderStatusFromWire('inTransit'), OrderStatus.inTransit);
    });

    test('orderStatusFromWire falls back rather than throwing', () {
      expect(orderStatusFromWire(null), OrderStatus.pending);
      expect(orderStatusFromWire('not_a_status'), OrderStatus.pending);
    });
  });

  group('delivery state machine', () {
    void expectAllowed(OrderStatus from, List<OrderStatus> allowed) {
      final order = buildOrder(status: from);
      for (final target in OrderStatus.values) {
        expect(
          order.canTransitionTo(target),
          allowed.contains(target),
          reason: '$from -> $target should be '
              '${allowed.contains(target) ? "allowed" : "rejected"}',
        );
      }
    }

    test('pending may only be accepted or cancelled', () {
      expectAllowed(OrderStatus.pending,
          [OrderStatus.accepted, OrderStatus.cancelled]);
    });

    test('accepted may only be picked up or cancelled', () {
      expectAllowed(OrderStatus.accepted,
          [OrderStatus.pickedUp, OrderStatus.cancelled]);
    });

    test('picked up may only move to in transit', () {
      expectAllowed(OrderStatus.pickedUp, [OrderStatus.inTransit]);
    });

    test('in transit may only be delivered or failed', () {
      expectAllowed(OrderStatus.inTransit,
          [OrderStatus.delivered, OrderStatus.failed]);
    });

    test('terminal states admit no further transition', () {
      for (final terminal in [
        OrderStatus.delivered,
        OrderStatus.cancelled,
        OrderStatus.failed,
      ]) {
        expectAllowed(terminal, const []);
      }
    });

    test('a customer cannot short-circuit straight to delivered', () {
      // The fraud case the rules also block server-side.
      expect(
        buildOrder(status: OrderStatus.pending)
            .canTransitionTo(OrderStatus.delivered),
        isFalse,
      );
      expect(
        buildOrder(status: OrderStatus.accepted)
            .canTransitionTo(OrderStatus.delivered),
        isFalse,
      );
    });

    test('a delivered order cannot be reopened or re-cancelled', () {
      final delivered = buildOrder(status: OrderStatus.delivered);
      expect(delivered.canTransitionTo(OrderStatus.cancelled), isFalse);
      expect(delivered.canTransitionTo(OrderStatus.pending), isFalse);
    });
  });
}
