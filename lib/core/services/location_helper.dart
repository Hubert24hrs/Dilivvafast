import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Robust location helper with GPS, geocoding, and error handling.
///
/// Wraps Geolocator and Mapbox Geocoding APIs with graceful fallbacks
/// for offline use or missing API keys.
class LocationHelper {
  LocationHelper();

  static const double lagosLat = 6.5244;
  static const double lagosLng = 3.3792;

  String? get _mapboxToken {
    try {
      final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
      if (token != null &&
          token.isNotEmpty &&
          token != 'your_mapbox_token_here') {
        return token;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ==================== GPS LOCATION ====================

  /// Check if location services are available and permissions granted.
  /// Returns a [LocationStatus] describing the current state.
  Future<LocationStatus> checkLocationStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationStatus.servicesDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      return LocationStatus.permissionDenied;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationStatus.permissionDeniedForever;
    }
    return LocationStatus.granted;
  }

  /// Request location permission. Returns true if granted.
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get the current device position.
  /// Returns null if location is unavailable; never throws.
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('LocationHelper.getCurrentPosition error: $e');
      return null;
    }
  }

  /// Get the current position, or fall back to Lagos coordinates.
  Future<({double lat, double lng})> getCurrentOrFallback() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return (lat: position.latitude, lng: position.longitude);
    }
    return (lat: lagosLat, lng: lagosLng);
  }

  // ==================== REVERSE GEOCODING ====================

  /// Convert coordinates to a human-readable address.
  /// Falls back to coordinate string if Mapbox unavailable.
  Future<String> reverseGeocode(double lat, double lng) async {
    final token = _mapboxToken;
    if (token != null) {
      try {
        final url =
            'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json'
            '?access_token=$token&limit=1&language=en';
        final response =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final features = data['features'] as List?;
          if (features != null && features.isNotEmpty) {
            return features[0]['place_name'] as String? ??
                '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
          }
        }
      } catch (e) {
        debugPrint('LocationHelper.reverseGeocode error: $e');
      }
    }
    // Fallback: try to match to known locations
    return _matchNearestKnownLocation(lat, lng) ??
        '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  // ==================== FORWARD GEOCODING (SEARCH) ====================

  /// Search for addresses matching [query].
  /// Uses Mapbox geocoding with fallback to hardcoded Nigerian locations.
  Future<List<GeocodedAddress>> searchAddresses(String query) async {
    if (query.trim().isEmpty) return _defaultLocations;

    final token = _mapboxToken;
    if (token != null) {
      try {
        final encoded = Uri.encodeComponent(query);
        final url =
            'https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json'
            '?access_token=$token&limit=8&language=en'
            '&country=NG&types=address,poi,place,locality,neighborhood';
        final response =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final features = data['features'] as List?;
          if (features != null && features.isNotEmpty) {
            return features.map((f) {
              final center = f['center'] as List;
              return GeocodedAddress(
                address: f['place_name'] as String? ?? query,
                lat: (center[1] as num).toDouble(),
                lng: (center[0] as num).toDouble(),
              );
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('LocationHelper.searchAddresses error: $e');
      }
    }

    // Fallback: filter hardcoded locations
    final lower = query.toLowerCase();
    return _defaultLocations
        .where((loc) => loc.address.toLowerCase().contains(lower))
        .toList();
  }

  // ==================== FALLBACK DATA ====================

  /// Match the nearest known location by distance.
  String? _matchNearestKnownLocation(double lat, double lng) {
    GeocodedAddress? nearest;
    double minDist = double.infinity;
    for (final loc in _defaultLocations) {
      final dist = Geolocator.distanceBetween(lat, lng, loc.lat, loc.lng);
      if (dist < minDist) {
        minDist = dist;
        nearest = loc;
      }
    }
    // Only return if within 5 km
    if (nearest != null && minDist < 5000) {
      return nearest.address;
    }
    return null;
  }

  /// Popular Nigerian locations for quick selection / offline fallback
  static final List<GeocodedAddress> _defaultLocations = [
    GeocodedAddress(
        address: 'Lekki Phase 1, Lagos', lat: 6.4479, lng: 3.4737),
    GeocodedAddress(
        address: 'Victoria Island, Lagos', lat: 6.4281, lng: 3.4219),
    GeocodedAddress(address: 'Ikeja, Lagos', lat: 6.6018, lng: 3.3515),
    GeocodedAddress(address: 'Surulere, Lagos', lat: 6.5059, lng: 3.3598),
    GeocodedAddress(address: 'Yaba, Lagos', lat: 6.5158, lng: 3.3817),
    GeocodedAddress(address: 'Ajah, Lagos', lat: 6.4670, lng: 3.5860),
    GeocodedAddress(address: 'Ikoyi, Lagos', lat: 6.4490, lng: 3.4310),
    GeocodedAddress(
        address: 'Marina, Lagos Island', lat: 6.4474, lng: 3.3903),
    GeocodedAddress(address: 'Wuse 2, Abuja', lat: 9.0643, lng: 7.4892),
    GeocodedAddress(address: 'Garki, Abuja', lat: 9.0388, lng: 7.4918),
    GeocodedAddress(address: 'Maitama, Abuja', lat: 9.0826, lng: 7.4953),
    GeocodedAddress(
        address: 'GRA, Port Harcourt', lat: 4.8156, lng: 7.0498),
    GeocodedAddress(
        address: 'Sabon Gari, Kano', lat: 12.0022, lng: 8.5127),
    GeocodedAddress(
        address: 'Gbagada, Lagos', lat: 6.5538, lng: 3.3847),
    GeocodedAddress(
        address: 'Ogba, Lagos', lat: 6.6260, lng: 3.3408),
    GeocodedAddress(
        address: 'Festac Town, Lagos', lat: 6.4676, lng: 3.2850),
    GeocodedAddress(
        address: 'Maryland, Lagos', lat: 6.5731, lng: 3.3640),
    GeocodedAddress(
        address: 'Oshodi, Lagos', lat: 6.5568, lng: 3.3418),
  ];

  /// Show a dialog prompting the user to enable location services.
  static Future<void> showLocationServicesDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Services Disabled',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Please enable location services in your device settings '
          'to use automatic location detection.',
          style: TextStyle(color: Colors.white60, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Open Settings',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show a dialog prompting the user to grant location permission.
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Permission Required',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'We need access to your location to show your pickup address. '
          'Please grant location permission in your app settings.',
          style: TextStyle(color: Colors.white60, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Open Settings',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// A geocoded address with coordinates.
class GeocodedAddress {
  final String address;
  final double lat;
  final double lng;

  const GeocodedAddress({
    required this.address,
    required this.lat,
    required this.lng,
  });
}

/// Location permission/service status.
enum LocationStatus {
  granted,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// Riverpod provider for LocationHelper.
final locationHelperProvider = Provider<LocationHelper>((ref) {
  return LocationHelper();
});
