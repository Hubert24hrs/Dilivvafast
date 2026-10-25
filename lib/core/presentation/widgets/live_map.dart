import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import 'package:dilivvafast/core/config/app_config.dart';

/// A real street map, inDrive-style: light streets, a pulsing "you are here"
/// puck, and optional pickup / drop-off markers joined by a line.
///
/// Mapbox only runs on Android and iOS, and only with a token. Everywhere
/// else — widget tests, desktop, web, or a build missing MAPBOX_ACCESS_TOKEN
/// — this renders [_MapPlaceholder] instead of crashing, so screens that use
/// it stay testable on the host.
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
      if (!(Platform.isAndroid || Platform.isIOS)) return false;
    } catch (_) {
      return false;
    }
    try {
      return AppConfig.instance.isMapboxConfigured;
    } catch (_) {
      // dotenv not loaded — e.g. under test.
      return false;
    }
  }

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  MapboxMap? _map;
  CircleAnnotationManager? _circles;
  PolylineAnnotationManager? _lines;

  bool get _hasPickup => widget.pickupLat != null && widget.pickupLng != null;
  bool get _hasDropoff =>
      widget.dropoffLat != null && widget.dropoffLng != null;
  bool get _hasDriver => widget.driverLat != null && widget.driverLng != null;

  Point _point(double lat, double lng) =>
      Point(coordinates: Position(lng, lat));

  Point get _center {
    if (widget.centerLat != null && widget.centerLng != null) {
      return _point(widget.centerLat!, widget.centerLng!);
    }
    if (_hasPickup && _hasDropoff) {
      return _point(
        (widget.pickupLat! + widget.dropoffLat!) / 2,
        (widget.pickupLng! + widget.dropoffLng!) / 2,
      );
    }
    if (_hasPickup) return _point(widget.pickupLat!, widget.pickupLng!);
    return _point(LiveMap.defaultLat, LiveMap.defaultLng);
  }

  /// Zoom out far enough to fit both markers once a route exists.
  double get _zoom {
    if (!(_hasPickup && _hasDropoff)) return widget.zoom;
    final span = [
      (widget.pickupLat! - widget.dropoffLat!).abs(),
      (widget.pickupLng! - widget.dropoffLng!).abs(),
    ].reduce((a, b) => a > b ? a : b);
    if (span > 0.5) return 9;
    if (span > 0.2) return 10.5;
    if (span > 0.08) return 11.5;
    if (span > 0.03) return 12.5;
    return 13.5;
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    try {
      await map.location.updateSettings(
        LocationComponentSettings(
          enabled: widget.showUserLocation,
          pulsingEnabled: true,
          pulsingColor: const Color(0xFF2E7DF6).toARGB32(),
        ),
      );
      // The compass and scale bar clash with the floating controls.
      await map.compass.updateSettings(CompassSettings(enabled: false));
      await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
      _circles = await map.annotations.createCircleAnnotationManager();
      _lines = await map.annotations.createPolylineAnnotationManager();
      await _drawRoute();
    } catch (e) {
      debugPrint('LiveMap: map setup failed: $e');
    }
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
    final driverMoved =
        old.driverLat != widget.driverLat || old.driverLng != widget.driverLng;
    if (_map == null) return;
    if (!moved) {
      // The courier moving should redraw the marker, not yank the camera
      // away from wherever the customer has panned to.
      if (driverMoved) _drawRoute();
      return;
    }
    _map!
        .easeTo(
          CameraOptions(
            center: _center,
            zoom: _zoom,
            padding: MbxEdgeInsets(
              top: 0,
              left: 0,
              bottom: widget.bottomPadding,
              right: 0,
            ),
          ),
          MapAnimationOptions(duration: 600),
        )
        .catchError((Object e) => debugPrint('LiveMap: easeTo failed: $e'));
    _drawRoute();
  }

  Future<void> _drawRoute() async {
    final circles = _circles;
    final lines = _lines;
    if (circles == null || lines == null) return;
    try {
      await circles.deleteAll();
      await lines.deleteAll();
      if (_hasPickup) {
        await circles.create(
          CircleAnnotationOptions(
            geometry: _point(widget.pickupLat!, widget.pickupLng!),
            circleRadius: 8,
            circleColor: const Color(0xFF12805C).toARGB32(),
            circleStrokeWidth: 3,
            circleStrokeColor: Colors.white.toARGB32(),
          ),
        );
      }
      if (_hasDropoff) {
        await circles.create(
          CircleAnnotationOptions(
            geometry: _point(widget.dropoffLat!, widget.dropoffLng!),
            circleRadius: 8,
            circleColor: const Color(0xFFFF6B00).toARGB32(),
            circleStrokeWidth: 3,
            circleStrokeColor: Colors.white.toARGB32(),
          ),
        );
      }
      if (_hasDriver) {
        await circles.create(
          CircleAnnotationOptions(
            geometry: _point(widget.driverLat!, widget.driverLng!),
            circleRadius: 10,
            circleColor: const Color(0xFF2E7DF6).toARGB32(),
            circleStrokeWidth: 4,
            circleStrokeColor: Colors.white.toARGB32(),
          ),
        );
      }
      if (_hasPickup && _hasDropoff) {
        await lines.create(
          PolylineAnnotationOptions(
            geometry: LineString(
              coordinates: [
                Position(widget.pickupLng!, widget.pickupLat!),
                Position(widget.dropoffLng!, widget.dropoffLat!),
              ],
            ),
            lineColor: const Color(0xFF1F2937).toARGB32(),
            lineWidth: 4,
            lineOpacity: 0.8,
          ),
        );
      }
    } catch (e) {
      debugPrint('LiveMap: drawing route failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!LiveMap.isSupported) {
      return _MapPlaceholder(
        hasRoute: _hasPickup && _hasDropoff,
        bottomPadding: widget.bottomPadding,
      );
    }
    return MapWidget(
      key: const ValueKey('live-map'),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      cameraOptions: CameraOptions(
        center: _center,
        zoom: _zoom,
        padding: MbxEdgeInsets(
          top: 0,
          left: 0,
          bottom: widget.bottomPadding,
          right: 0,
        ),
      ),
      onMapCreated: _onMapCreated,
    );
  }
}

/// Stand-in used where Mapbox cannot run. Light, street-like, and honest
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
