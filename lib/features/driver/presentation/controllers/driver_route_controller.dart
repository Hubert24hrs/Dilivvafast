import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/services/route_matching_service.dart';


/// State for the driver route + en-route order discovery.
class DriverRouteState {
  const DriverRouteState({
    this.isOnline = false,
    this.originAddress = '',
    this.originLat = 0,
    this.originLng = 0,
    this.destinationAddress = '',
    this.destinationLat = 0,
    this.destinationLng = 0,
    this.hasRoute = false,
    this.routePolyline = const [],
    this.enRouteOrders = const [],
    this.activeOrderId,
    this.isLoading = false,
    this.error,
  });

  final bool isOnline;
  final String originAddress;
  final double originLat;
  final double originLng;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final bool hasRoute;
  final List<GeoPoint> routePolyline;
  final List<EnRouteOrder> enRouteOrders;
  final String? activeOrderId;
  final bool isLoading;
  final String? error;

  DriverRouteState copyWith({
    bool? isOnline,
    String? originAddress,
    double? originLat,
    double? originLng,
    String? destinationAddress,
    double? destinationLat,
    double? destinationLng,
    bool? hasRoute,
    List<GeoPoint>? routePolyline,
    List<EnRouteOrder>? enRouteOrders,
    String? activeOrderId,
    bool? isLoading,
    String? error,
  }) {
    return DriverRouteState(
      isOnline: isOnline ?? this.isOnline,
      originAddress: originAddress ?? this.originAddress,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      hasRoute: hasRoute ?? this.hasRoute,
      routePolyline: routePolyline ?? this.routePolyline,
      enRouteOrders: enRouteOrders ?? this.enRouteOrders,
      activeOrderId: activeOrderId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get enRouteCount => enRouteOrders.length;
  double get totalPotentialEarnings =>
      enRouteOrders.fold(0.0, (total, e) => total + e.order.driverEarnings);
}

class DriverRouteController extends Notifier<DriverRouteState> {
  final _routeService = RouteMatchingService();

  @override
  DriverRouteState build() => const DriverRouteState();

  void toggleOnline() {
    state = state.copyWith(isOnline: !state.isOnline);
    ref.read(driverOnlineProvider.notifier).toggle();
  }

  void setOrigin(String address, double lat, double lng) {
    state = state.copyWith(
      originAddress: address,
      originLat: lat,
      originLng: lng,
    );
  }

  void setDestination(String address, double lat, double lng) {
    state = state.copyWith(
      destinationAddress: address,
      destinationLat: lat,
      destinationLng: lng,
    );
  }

  /// Build a simple route from origin to destination and find en-route orders
  Future<void> buildRouteAndFindOrders() async {
    if (state.originLat == 0 || state.destinationLat == 0) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Build a simplified straight-line route
      // In production, use a routing API (Mapbox/Google) for real polylines
      final polyline = _buildSimpleRoute(
        state.originLat,
        state.originLng,
        state.destinationLat,
        state.destinationLng,
      );

      // Get pending orders from Firestore
      final pendingOrders =
          ref.read(pendingOrdersProvider).value ?? [];

      // Find en-route matches
      final enRouteOrders = _routeService.findEnRouteOrders(
        routePolyline: polyline,
        pendingOrders: pendingOrders,
        radiusKm: 2.0,
      );

      state = state.copyWith(
        hasRoute: true,
        routePolyline: polyline,
        enRouteOrders: enRouteOrders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to build route: $e',
      );
    }
  }

  /// Accept an en-route order by assigning this driver to it
  Future<void> acceptOrder(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final courierRepo = ref.read(courierRepositoryProvider);
      final result = await courierRepo.assignDriver(orderId, userId);

      result.fold(
        (failure) =>
            state = state.copyWith(isLoading: false, error: failure.message),
        (_) {
          // Remove accepted order from en-route list
          final updated = state.enRouteOrders
              .where((e) => e.order.id != orderId)
              .toList();
          state = state.copyWith(
            isLoading: false,
            enRouteOrders: updated,
            activeOrderId: orderId,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Decline an en-route order (just hide from local list)
  void declineOrder(String orderId) {
    final updated =
        state.enRouteOrders.where((e) => e.order.id != orderId).toList();
    state = state.copyWith(enRouteOrders: updated);
  }

  void clearRoute() {
    state = state.copyWith(
      hasRoute: false,
      routePolyline: [],
      enRouteOrders: [],
      destinationAddress: '',
      destinationLat: 0,
      destinationLng: 0,
    );
  }

  /// Build a simple interpolated route between two points
  List<GeoPoint> _buildSimpleRoute(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const steps = 10;
    return List.generate(steps + 1, (i) {
      final t = i / steps;
      return GeoPoint(
        lat1 + (lat2 - lat1) * t,
        lng1 + (lng2 - lng1) * t,
      );
    });
  }
}

final driverRouteControllerProvider =
    NotifierProvider<DriverRouteController, DriverRouteState>(
        DriverRouteController.new);
