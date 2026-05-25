import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/screens/booking/booking_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'map_view_stub.dart'
    if (dart.library.io) 'map_view_mobile.dart'
    if (dart.library.html) 'map_view_web.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ignore: unused_field
  dynamic _mapboxMap; // Dynamic to avoid mobile-only types

  _onMapCreated(dynamic mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map View (Conditional)
          MapView(onMapCreated: _onMapCreated),

          // Overlay UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        shape: BoxShape.circle,
                        boxShadow: [AppTheme.glowShadow(AppTheme.primaryColor)],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Booking Sheet
          const Align(
            alignment: Alignment.bottomCenter,
            child: BookingSheet(),
          ),
        ],
      ),
    );
  }
}
