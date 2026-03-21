import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/features/courier/domain/entities/courier_order_model.dart';

/// Service for matching pending orders to a driver's active route.
/// Uses corridor-based proximity matching: finds orders whose pickup
/// point falls within [radiusKm] of any point along the driver's route.
class RouteMatchingService {
  static const double defaultRadiusKm = 2.0;

  /// Given a driver's route polyline and a list of pending orders,
  /// returns orders whose pickup is within [radiusKm] of the route,
  /// sorted by detour distance (least detour first).
  List<EnRouteOrder> findEnRouteOrders({
    required List<GeoPoint> routePolyline,
    required List<CourierOrderModel> pendingOrders,
    double radiusKm = defaultRadiusKm,
  }) {
    if (routePolyline.length < 2 || pendingOrders.isEmpty) return [];

    final results = <EnRouteOrder>[];

    for (final order in pendingOrders) {
      final pickup = order.pickupGeoPoint;
      final dropoff = order.dropoffGeoPoint;

      // Find minimum distance from pickup to any segment of the route
      double minPickupDist = double.infinity;
      int closestSegmentIdx = 0;

      for (var i = 0; i < routePolyline.length - 1; i++) {
        final dist = _distanceToSegment(
          pickup.latitude,
          pickup.longitude,
          routePolyline[i].latitude,
          routePolyline[i].longitude,
          routePolyline[i + 1].latitude,
          routePolyline[i + 1].longitude,
        );
        if (dist < minPickupDist) {
          minPickupDist = dist;
          closestSegmentIdx = i;
        }
      }

      if (minPickupDist <= radiusKm) {
        // Calculate detour: how much extra distance to pick up + drop off
        final detour = _calculateDetour(
          routePolyline,
          closestSegmentIdx,
          pickup,
          dropoff,
        );

        results.add(EnRouteOrder(
          order: order,
          distanceFromRoute: minPickupDist,
          detourKm: detour,
          routeSegmentIndex: closestSegmentIdx,
        ));
      }
    }

    // Sort by detour distance (least deviation first)
    results.sort((a, b) => a.detourKm.compareTo(b.detourKm));
    return results;
  }

  /// Check if a single order's pickup is along the route
  bool isOrderAlongRoute({
    required List<GeoPoint> routePolyline,
    required CourierOrderModel order,
    double radiusKm = defaultRadiusKm,
  }) {
    for (var i = 0; i < routePolyline.length - 1; i++) {
      final dist = _distanceToSegment(
        order.pickupGeoPoint.latitude,
        order.pickupGeoPoint.longitude,
        routePolyline[i].latitude,
        routePolyline[i].longitude,
        routePolyline[i + 1].latitude,
        routePolyline[i + 1].longitude,
      );
      if (dist <= radiusKm) return true;
    }
    return false;
  }

  /// Simplify a polyline by reducing the number of points
  /// (Douglas-Peucker-style, simplified version)
  List<GeoPoint> simplifyRoute(List<GeoPoint> points, {int maxPoints = 20}) {
    if (points.length <= maxPoints) return points;
    final step = points.length ~/ maxPoints;
    final result = <GeoPoint>[];
    for (var i = 0; i < points.length; i += step) {
      result.add(points[i]);
    }
    if (result.last != points.last) {
      result.add(points.last);
    }
    return result;
  }

  /// Distance from point (px, py) to line segment (ax,ay)-(bx,by) in km
  double _distanceToSegment(
    double px, double py,
    double ax, double ay,
    double bx, double by,
  ) {
    final abx = bx - ax;
    final aby = by - ay;
    final apx = px - ax;
    final apy = py - ay;

    final abLenSq = abx * abx + aby * aby;
    if (abLenSq == 0) {
      return _haversine(px, py, ax, ay);
    }

    var t = (apx * abx + apy * aby) / abLenSq;
    t = t.clamp(0.0, 1.0);

    final closestX = ax + t * abx;
    final closestY = ay + t * aby;

    return _haversine(px, py, closestX, closestY);
  }

  /// Calculate detour km for picking up and dropping off an order
  double _calculateDetour(
    List<GeoPoint> route,
    int segmentIdx,
    GeoPoint pickup,
    GeoPoint dropoff,
  ) {
    // Simplified: detour = distance from route to pickup + pickup to dropoff
    // - distance that would have been traveled on original route for that segment
    final toPickup = _haversine(
      route[segmentIdx].latitude,
      route[segmentIdx].longitude,
      pickup.latitude,
      pickup.longitude,
    );
    final pickupToDropoff = _haversine(
      pickup.latitude,
      pickup.longitude,
      dropoff.latitude,
      dropoff.longitude,
    );
    final directSegment = _haversine(
      route[segmentIdx].latitude,
      route[segmentIdx].longitude,
      route[min(segmentIdx + 1, route.length - 1)].latitude,
      route[min(segmentIdx + 1, route.length - 1)].longitude,
    );

    return max(0, toPickup + pickupToDropoff - directSegment);
  }

  /// Haversine formula: distance between two lat/lng points in km
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * pi / 180;
}

/// An order matched to a driver's route with distance metadata.
class EnRouteOrder {
  const EnRouteOrder({
    required this.order,
    required this.distanceFromRoute,
    required this.detourKm,
    required this.routeSegmentIndex,
  });

  final CourierOrderModel order;

  /// Distance from the order's pickup to the nearest route segment (km)
  final double distanceFromRoute;

  /// Total detour distance if driver picks up this order (km)
  final double detourKm;

  /// Index of the route segment closest to the pickup
  final int routeSegmentIndex;
}
