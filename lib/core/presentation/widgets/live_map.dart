import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A real street map (Google Maps), inDrive-style: the blue "you are here"
/// dot, and optional pickup / drop-off markers joined by a line, plus the
/// courier's live position while a delivery is under way.
///
/// Google Maps only runs on Android and iOS. Everywhere else — widget tests,
/// desktop, web — this renders [_MapPlaceholder] instead of crashing, so the
/// screens that use it stay testable on the host.
///
/// The Android key comes from MAPS_API_KEY at build time (see
/// android/app/build.gradle.kts).
class LiveMap extends StatefulWidget {
  const LiveMap({
    super.key,
    this.centerLat,
    this.centerLng,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.driverLat,
    this.driverLng,
    this.zoom = 15,
    this.showUserLocation = true,
    this.bottomPadding = 0,
  });

  final double? centerLat;
  final double? centerLng;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  /// The assigned courier's live position, from driver_locations.
  final double? driverLat;
  final double? driverLng;
  final double zoom;
  final bool showUserLocation;

  /// Height of anything overlapping the bottom of the map (a sheet), so the
  /// camera centres in the visible part rather than behind the sheet.
  final double bottomPadding;

  /// Lagos Island — a sensible default before the device location arrives.
  static const double defaultLat = 6.4541;
  static const double defaultLng = 3.3947;

  static bool get isSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  GoogleMapController? _map;

  bool get _hasPickup => widget.pickupLat != null && widget.pickupLng != null;
  bool get _hasDropoff =>
      widget.dropoffLat != null && widget.dropoffLng != null;
  bool get _hasDriver => widget.driverLat != null && widget.driverLng != null;
  bool get _hasRoute => _hasPickup && _hasDropoff;

  LatLng get _center {
    if (widget.centerLat != null && widget.centerLng != null) {
      return LatLng(widget.centerLat!, widget.centerLng!);
    }
    if (_hasRoute) {
      return LatLng(
        (widget.pickupLat! + widget.dropoffLat!) / 2,
        (widget.pickupLng! + widget.dropoffLng!) / 2,
      );
    }
    if (_hasPickup) return LatLng(widget.pickupLat!, widget.pickupLng!);
    return const LatLng(LiveMap.defaultLat, LiveMap.defaultLng);
  }

  /// Zoom out far enough to fit both markers once a route exists.
  double get _zoom {
    if (!_hasRoute) return widget.zoom;
    final span = [
      (widget.pickupLat! - widget.dropoffLat!).abs(),
      (widget.pickupLng! - widget.dropoffLng!).abs(),
    ].reduce(math.max);
    if (span > 0.5) return 9;
    if (span > 0.2) return 10.5;
    if (span > 0.08) return 11.5;
    if (span > 0.03) return 12.5;
    return 13.5;
  }

  Set<Marker> get _markers => {
    if (_hasPickup)
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat!, widget.pickupLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ),
    if (_hasDropoff)
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(widget.dropoffLat!, widget.dropoffLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Drop-off'),
      ),
    if (_hasDriver)
      Marker(
        markerId: const MarkerId('courier'),
        position: LatLng(widget.driverLat!, widget.driverLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your courier'),
        zIndexInt: 2,
      ),
  };

  Set<Polyline> get _lines => {
    if (_hasRoute)
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(widget.pickupLat!, widget.pickupLng!),
          LatLng(widget.dropoffLat!, widget.dropoffLng!),
        ],
        color: const Color(0xCC1F2937),
        width: 4,
      ),
  };

  CameraUpdate get _cameraUpdate {
    if (_hasRoute) {
      final south = math.min(widget.pickupLat!, widget.dropoffLat!);
      final north = math.max(widget.pickupLat!, widget.dropoffLat!);
      final west = math.min(widget.pickupLng!, widget.dropoffLng!);
      final east = math.max(widget.pickupLng!, widget.dropoffLng!);
      // Identical points make a zero-size box, which the SDK rejects.
      if (north - south > 1e-5 || east - west > 1e-5) {
        return CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(south, west),
            northeast: LatLng(north, east),
          ),
          64,
        );
      }
    }
    return CameraUpdate.newLatLngZoom(_center, _zoom);
  }

  void _onMapCreated(GoogleMapController controller) {
    _map = controller;
    if (_hasRoute) _moveCamera();
  }

  void _moveCamera() {
    final map = _map;
    if (map == null) return;
    map
        .animateCamera(_cameraUpdate)
        .catchError(
          (Object e) => debugPrint('LiveMap: camera move failed: $e'),
        );
  }

  @override
  void didUpdateWidget(covariant LiveMap old) {
    super.didUpdateWidget(old);
    final moved =
        old.centerLat != widget.centerLat ||
        old.centerLng != widget.centerLng ||
        old.pickupLat != widget.pickupLat ||
        old.dropoffLat != widget.dropoffLat ||
        old.pickupLng != widget.pickupLng ||
        old.dropoffLng != widget.dropoffLng;
    // The courier moving only redraws their marker (markers are rebuilt from
    // the widget on every build); it must not yank the camera away from
    // wherever the customer has panned to.
    if (moved) _moveCamera();
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!LiveMap.isSupported) {
      return _MapPlaceholder(
        hasRoute: _hasRoute,
        bottomPadding: widget.bottomPadding,
      );
    }
    return GoogleMap(
      key: const ValueKey('live-map'),
      initialCameraPosition: CameraPosition(target: _center, zoom: _zoom),
      onMapCreated: _onMapCreated,
      markers: _markers,
      polylines: _lines,
      myLocationEnabled: widget.showUserLocation,
      // The screens draw their own locate-me button over the map.
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      buildingsEnabled: true,
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
    );
  }
}

/// Stand-in used where Google Maps cannot run. Light, street-like, and honest
/// about being a placeholder rather than imitating a real location.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.hasRoute, required this.bottomPadding});

  final bool hasRoute;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF1F3),
      child: CustomPaint(
        painter: _StreetPainter(),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Center(
            child: Icon(
              hasRoute ? Icons.route_rounded : Icons.my_location_rounded,
              size: 28,
              color: const Color(0xFF2E7DF6),
            ),
          ),
        ),
      ),
    );
  }
}

class _StreetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 10;
    final minor = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;
    for (var y = 40.0; y < size.height; y += 120) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 30), road);
    }
    for (var x = 30.0; x < size.width; x += 90) {
      canvas.drawLine(Offset(x, 0), Offset(x - 20, size.height), minor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
