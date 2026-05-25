import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart';

class MapView extends StatefulWidget {
  final Function(dynamic)? onMapCreated;

  const MapView({super.key, this.onMapCreated});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // ignore: unused_field - stored for potential map operations
  mapbox.MapboxMap? _mapboxMap;

  _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    widget.onMapCreated?.call(mapboxMap);

    // Request Permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      // Enable Location Component
      await mapboxMap.location.updateSettings(
        mapbox.LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
        ),
      );

      // Get current position and move camera
      final position = await Geolocator.getCurrentPosition();
      mapboxMap.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(position.longitude, position.latitude)),
          zoom: 14.0,
        ),
        mapbox.MapAnimationOptions(duration: 2000),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return mapbox.MapWidget(
      key: const ValueKey("mapWidget"),
      onMapCreated: _onMapCreated,
      styleUri: mapbox.MapboxStyles.DARK,
      cameraOptions: mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(3.3792, 6.5244)), // Default to Lagos
        zoom: 12.0,
        pitch: 45.0,
      ),
    );
  }
}
