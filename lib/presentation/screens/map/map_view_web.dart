import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MapView extends StatelessWidget {
  final Function(dynamic)? onMapCreated;

  const MapView({super.key, this.onMapCreated});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Mapbox 3D is not supported on Web',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please use a mobile emulator for the full 3D experience.',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
