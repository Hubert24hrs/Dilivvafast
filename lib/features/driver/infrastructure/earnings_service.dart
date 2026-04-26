import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Earnings service backed by Firestore.
/// Queries the `orders` collection for completed deliveries
/// belonging to a specific driver.
class EarningsService {
  final FirebaseFirestore _firestore;

  EarningsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns the total lifetime earnings for a driver.
  Future<double> getTotalEarnings(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'delivered')
          .get();

      return snapshot.docs.fold<double>(0.0, (total, doc) {
        return total + ((doc.data()['driverEarnings'] as num?)?.toDouble() ?? 0);
      });
    } catch (e) {
      debugPrint('EarningsService.getTotalEarnings error: $e');
      return 0.0;
    }
  }

  /// Returns the earnings history as a list of maps
  /// sorted by delivery time (most recent first).
  Future<List<Map<String, dynamic>>> getEarningsHistory(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'delivered')
          .orderBy('deliveredAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'orderId': doc.id,
          'route':
              '${data['pickupAddress'] ?? 'Unknown'} → ${data['dropoffAddress'] ?? 'Unknown'}',
          'amount': (data['driverEarnings'] as num?)?.toDouble() ?? 0,
          'deliveredAt': (data['deliveredAt'] as Timestamp?)?.toDate(),
          'totalFare': (data['totalFare'] as num?)?.toDouble() ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('EarningsService.getEarningsHistory error: $e');
      return [];
    }
  }

  /// Returns daily earnings for the past N days, useful for charts.
  Future<Map<DateTime, double>> getDailyEarnings(
      String driverId, int days) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'delivered')
          .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();

      final data = <DateTime, double>{};
      for (var i = 0; i < days; i++) {
        final day = start.add(Duration(days: i));
        data[DateTime(day.year, day.month, day.day)] = 0;
      }

      for (final doc in snapshot.docs) {
        final deliveredAt =
            (doc.data()['deliveredAt'] as Timestamp?)?.toDate();
        final earnings =
            (doc.data()['driverEarnings'] as num?)?.toDouble() ?? 0;
        if (deliveredAt != null) {
          final key = DateTime(
              deliveredAt.year, deliveredAt.month, deliveredAt.day);
          data[key] = (data[key] ?? 0) + earnings;
        }
      }

      return data;
    } catch (e) {
      debugPrint('EarningsService.getDailyEarnings error: $e');
      return {};
    }
  }
}
