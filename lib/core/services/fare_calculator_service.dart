import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/constants/firestore_constants.dart';
import 'package:fast_delivery/features/booking/domain/entities/zone_model.dart';

/// Dynamic fare calculator based on zone config from Firestore.
class FareCalculatorService {
  FareCalculatorService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const double _minimumFare = 500.0; // ₦500

  /// Calculate fare for a delivery
  Future<FareBreakdown> calculateFare({
    required double distanceKm,
    required double packageWeightKg,
    required double pickupLat,
    required double pickupLng,
    double? promoDiscount,
  }) async {
    // Find matching zone
    final zone = await _findZoneForCoordinates(pickupLat, pickupLng);

    final baseFare = zone?.baseFare ?? 500.0;
    final perKmRate = zone?.perKmRate ?? 100.0;
    final surgeMultiplier = zone?.currentSurgeMultiplier ?? 1.0;

    // Weight surcharge
    double weightSurcharge = 0.0;
    if (packageWeightKg >= 5 && packageWeightKg < 10) {
      weightSurcharge = 200.0;
    } else if (packageWeightKg >= 10) {
      weightSurcharge = 500.0;
    }

    // Calculate total before promo
    final distanceFare = distanceKm * perKmRate;
    final fareBeforePromo =
        (baseFare + distanceFare + weightSurcharge) * surgeMultiplier;

    // Apply promo discount
    final discount = promoDiscount ?? 0.0;
    final totalFare = max(fareBeforePromo - discount, _minimumFare);

    return FareBreakdown(
      baseFare: baseFare,
      distanceFare: distanceFare,
      weightSurcharge: weightSurcharge,
      surgeMultiplier: surgeMultiplier,
      subtotal: fareBeforePromo,
      promoDiscount: discount,
      totalFare: totalFare,
      zoneName: zone?.name,
    );
  }

  /// Calculate driver earnings and platform commission
  EarningsSplit calculateEarningsSplit(double totalFare,
      {double platformCommissionRate = 0.20}) {
    final platformCommission = totalFare * platformCommissionRate;
    final driverEarnings = totalFare - platformCommission;
    return EarningsSplit(
      totalFare: totalFare,
      driverEarnings: driverEarnings,
      platformCommission: platformCommission,
      commissionRate: platformCommissionRate,
    );
  }

  Future<ZoneModel?> _findZoneForCoordinates(
      double lat, double lng) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreConstants.zones)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in snapshot.docs) {
        final zone = ZoneModel.fromFirestore(doc);
        if (_isPointInPolygon(lat, lng, zone.polygonCoordinates)) {
          return zone;
        }
      }
      // Return first active zone as fallback (city-wide)
      if (snapshot.docs.isNotEmpty) {
        return ZoneModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Ray-casting algorithm for point-in-polygon test
  bool _isPointInPolygon(
      double lat, double lng, List<GeoPoint> polygon) {
    if (polygon.length < 3) return false;

    var inside = false;
    var j = polygon.length - 1;

    for (var i = 0; i < polygon.length; i++) {
      final xi = polygon[i].latitude;
      final yi = polygon[i].longitude;
      final xj = polygon[j].latitude;
      final yj = polygon[j].longitude;

      if (((yi > lng) != (yj > lng)) &&
          (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }
}

/// Fare breakdown for itemized receipt
class FareBreakdown {
  const FareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.weightSurcharge,
    required this.surgeMultiplier,
    required this.subtotal,
    required this.promoDiscount,
    required this.totalFare,
    this.zoneName,
  });

  final double baseFare;
  final double distanceFare;
  final double weightSurcharge;
  final double surgeMultiplier;
  final double subtotal;
  final double promoDiscount;
  final double totalFare;
  final String? zoneName;
}

/// Earnings split between driver and platform
class EarningsSplit {
  const EarningsSplit({
    required this.totalFare,
    required this.driverEarnings,
    required this.platformCommission,
    required this.commissionRate,
  });

  final double totalFare;
  final double driverEarnings;
  final double platformCommission;
  final double commissionRate;
}
