import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dilivvafast/features/courier/domain/entities/courier_bid.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

/// Client-side mirror of the negotiation band the backend enforces in
/// onCourierCreated, raiseOffer, acceptBid and the bid rules. If these drift
/// from functions/src/index.ts the app will show a range the server rejects.
void main() {
  group('NegotiationBounds', () {
    test('floor is 70% of the recommendation, rounded up to ₦50', () {
      // 0.7 * 2000 = 1400, already a multiple of 50.
      expect(const NegotiationBounds(recommended: 2000).floor, 1400);
      // 0.7 * 2130 = 1491 → 1500.
      expect(const NegotiationBounds(recommended: 2130).floor, 1500);
    });

    test('floor never drops below the minimum fare', () {
      // 0.7 * 600 = 420, below the ₦500 minimum.
      expect(const NegotiationBounds(recommended: 600).floor, 500);
    });

    test('ceiling is three times the recommendation', () {
      expect(const NegotiationBounds(recommended: 2000).ceiling, 6000);
    });

    test('clamp pulls an offer into the band', () {
      const b = NegotiationBounds(recommended: 2000);
      expect(b.clamp(1), 1400, reason: 'a ₦1 offer is lifted to the floor');
      expect(b.clamp(99999), 6000, reason: 'nothing past the ceiling');
      expect(b.clamp(2500), 2500, reason: 'in-band offers are untouched');
    });
  });

  group('CourierVehicle', () {
    test('serialises to the wire values the rules check', () {
      expect(CourierVehicle.bike.wireValue, 'bike');
      expect(CourierVehicle.car.wireValue, 'car');
    });

    test('maps driver vehicles to the service they can do', () {
      expect(
        CourierVehicle.forDriverVehicle('motorcycle'),
        CourierVehicle.bike,
      );
      expect(CourierVehicle.forDriverVehicle('bicycle'), CourierVehicle.bike);
      expect(CourierVehicle.forDriverVehicle('car'), CourierVehicle.car);
      expect(CourierVehicle.forDriverVehicle('van'), CourierVehicle.car);
    });

    test('a driver with no recorded vehicle defaults to bike', () {
      expect(CourierVehicle.forDriverVehicle(null), CourierVehicle.bike);
    });

    test('each service lists exactly the vehicles the rules accept', () {
      expect(CourierVehicle.bike.driverVehicleTypes, ['motorcycle', 'bicycle']);
      expect(CourierVehicle.car.driverVehicleTypes, ['car', 'van']);
    });
  });

  group('BidStatus', () {
    test('decodes known values and falls back to open', () {
      expect(BidStatus.fromWire('accepted'), BidStatus.accepted);
      expect(BidStatus.fromWire('declined'), BidStatus.declined);
      expect(BidStatus.fromWire(null), BidStatus.open);
      expect(BidStatus.fromWire('garbage'), BidStatus.open);
    });
  });

  group('CourierOrderModel negotiation fields', () {
    test('legacy orders without a vehicle type decode as bike', () {
      final order = CourierOrderModel.fromJson({
        'id': 'o1',
        'userId': 'u1',
        'status': 'pending',
        'pickupAddress': 'A',
        'pickupGeoPoint': {'latitude': 6.4, 'longitude': 3.3},
        'dropoffAddress': 'B',
        'dropoffGeoPoint': {'latitude': 6.5, 'longitude': 3.4},
        'packageDescription': 'Docs',
        'recipientName': 'R',
        'recipientPhone': '080',
        'trackingCode': 'T',
        'createdAt': Timestamp.fromDate(DateTime.utc(2025, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2025, 1, 1)),
      });
      expect(order.vehicleType, CourierVehicle.bike);
      expect(order.offeredFare, 0);
    });
  });
}
