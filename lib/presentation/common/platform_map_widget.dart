import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// Type Aliases for Cross-Platform compatibility
typedef PlatformMapboxMap = MapboxMap;
typedef PlatformCircleAnnotationManager = CircleAnnotationManager;
typedef PlatformCircleAnnotation = CircleAnnotation;
typedef PlatformPoint = Point;
typedef PlatformPosition = Position;

class PlatformMapWidget extends StatelessWidget {
  final Function(dynamic) onMapCreated;
  final double initialLat;
  final double initialLng;
  final double initialZoom;

  const PlatformMapWidget({
    super.key,
    required this.onMapCreated,
    required this.initialLat,
    required this.initialLng,
    required this.initialZoom,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (Platform.environment.containsKey('FLUTTER_TEST'))) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.map, color: Colors.white54, size: 48),
              SizedBox(height: 16),
              Text(
                "Map not supported in Test/Web",
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return MapWidget(
      onMapCreated: (MapboxMap mapboxMap) => onMapCreated(mapboxMap),
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(initialLng, initialLat)),
        zoom: initialZoom,
      ),
    );
  }
}
