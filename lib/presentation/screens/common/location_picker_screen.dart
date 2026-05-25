import 'package:flutter/material.dart';
import 'package:dilivvafast/presentation/common/platform_map_widget.dart';

class LocationPickerScreen extends StatelessWidget {
  const LocationPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
      ),
      body: PlatformMapWidget(
        onMapCreated: (_) {},
        initialLat: 6.5244, // Default to Lagos
        initialLng: 3.3792,
        initialZoom: 14.0,
      ),
    );
  }
}
