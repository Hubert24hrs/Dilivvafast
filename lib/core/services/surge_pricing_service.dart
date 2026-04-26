import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Surge pricing multiplier based on demand, time, and zone.
/// Returns a multiplier (1.0 = normal, 1.5 = 50% surge, etc.)
class SurgePricingService {
  static final SurgePricingService _instance = SurgePricingService._();
  static SurgePricingService get instance => _instance;
  SurgePricingService._();

  // Cache surge data to avoid excessive Firestore reads
  final Map<String, _SurgeCache> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Calculate surge multiplier for a given zone
  Future<double> getSurgeMultiplier(String zoneId) async {
    // Check cache first
    final cached = _cache[zoneId];
    if (cached != null && !cached.isExpired) {
      return cached.multiplier;
    }

    try {
      // 1. Check Firestore for admin-set surge overrides
      final overrideDoc = await FirebaseFirestore.instance
          .collection('surge_overrides')
          .doc(zoneId)
          .get();

      if (overrideDoc.exists) {
        final data = overrideDoc.data()!;
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
        if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
          final multiplier = (data['multiplier'] as num?)?.toDouble() ?? 1.0;
          _cache[zoneId] = _SurgeCache(multiplier);
          return multiplier;
        }
      }

      // 2. Calculate dynamic surge based on demand
      final multiplier = await _calculateDynamicSurge(zoneId);
      _cache[zoneId] = _SurgeCache(multiplier);
      return multiplier;
    } catch (e) {
      debugPrint('Surge pricing error: $e');
      return 1.0; // Default to no surge on error
    }
  }

  /// Calculate surge based on real-time demand metrics
  Future<double> _calculateDynamicSurge(String zoneId) async {
    final now = DateTime.now();

    // Count pending orders in the last 30 minutes for this zone
    final thirtyMinAgo = now.subtract(const Duration(minutes: 30));
    final pendingOrders = await FirebaseFirestore.instance
        .collection('orders')
        .where('zoneId', isEqualTo: zoneId)
        .where('status', isEqualTo: 'pending')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyMinAgo))
        .count()
        .get();

    // Count available drivers in the zone
    final availableDrivers = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .where('currentZoneId', isEqualTo: zoneId)
        .where('isOnline', isEqualTo: true)
        .where('isOnDelivery', isEqualTo: false)
        .count()
        .get();

    final orderCount = pendingOrders.count ?? 0;
    final driverCount = availableDrivers.count ?? 0;

    // Calculate demand ratio
    double demandRatio;
    if (driverCount == 0) {
      demandRatio = orderCount > 0 ? 5.0 : 1.0;
    } else {
      demandRatio = orderCount / driverCount;
    }

    // Apply time-based adjustments
    final timeMultiplier = _getTimeMultiplier(now);

    // Weather/special event multiplier (from Firestore config)
    final eventMultiplier = await _getEventMultiplier(zoneId);

    // Calculate final multiplier
    double surge = 1.0;

    if (demandRatio > 3.0) {
      surge = 2.0; // Very high demand
    } else if (demandRatio > 2.0) {
      surge = 1.7;
    } else if (demandRatio > 1.5) {
      surge = 1.4;
    } else if (demandRatio > 1.0) {
      surge = 1.2;
    }

    // Apply time and event modifiers
    surge *= timeMultiplier * eventMultiplier;

    // Cap at 3x maximum
    return surge.clamp(1.0, 3.0);
  }

  /// Time-based surge adjustments
  double _getTimeMultiplier(DateTime now) {
    final hour = now.hour;

    // Peak hours in Nigerian cities
    if (hour >= 7 && hour <= 9) return 1.15; // Morning rush
    if (hour >= 16 && hour <= 19) return 1.2; // Evening rush
    if (hour >= 22 || hour <= 5) return 1.1; // Late night (fewer drivers)

    return 1.0; // Normal hours
  }

  /// Check for special event multipliers (e.g., holidays, heavy rain)
  Future<double> _getEventMultiplier(String zoneId) async {
    try {
      final now = DateTime.now();
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('surge_events')
          .where('zoneId', whereIn: [zoneId, 'all'])
          .where('startsAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endsAt', isGreaterThan: Timestamp.fromDate(now))
          .limit(1)
          .get();

      if (eventsSnapshot.docs.isNotEmpty) {
        return (eventsSnapshot.docs.first.data()['multiplier'] as num?)
                ?.toDouble() ??
            1.0;
      }
    } catch (_) {}

    return 1.0;
  }

  /// Apply surge to a base fare
  double applyToFare(double baseFare, double surgeMultiplier) {
    return baseFare * surgeMultiplier;
  }

  /// Get display info for the surge
  SurgeInfo getSurgeInfo(double multiplier) {
    if (multiplier <= 1.0) {
      return SurgeInfo(
        multiplier: 1.0,
        label: 'Normal pricing',
        color: 0xFF4CAF50,
        isActive: false,
      );
    }
    if (multiplier <= 1.3) {
      return SurgeInfo(
        multiplier: multiplier,
        label: 'Slightly busy',
        color: 0xFFFF9500,
        isActive: true,
      );
    }
    if (multiplier <= 1.7) {
      return SurgeInfo(
        multiplier: multiplier,
        label: 'High demand',
        color: 0xFFFF6B00,
        isActive: true,
      );
    }
    return SurgeInfo(
      multiplier: multiplier,
      label: 'Very high demand',
      color: 0xFFEF5350,
      isActive: true,
    );
  }

  /// Clear cached surge data
  void clearCache() => _cache.clear();
}

class SurgeInfo {
  final double multiplier;
  final String label;
  final int color;
  final bool isActive;

  SurgeInfo({
    required this.multiplier,
    required this.label,
    required this.color,
    required this.isActive,
  });

  String get displayMultiplier => '${multiplier.toStringAsFixed(1)}x';
  String get percentageIncrease =>
      '+${((multiplier - 1) * 100).toStringAsFixed(0)}%';
}

class _SurgeCache {
  final double multiplier;
  final DateTime createdAt;

  _SurgeCache(this.multiplier) : createdAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(createdAt) > SurgePricingService._cacheTtl;
}
