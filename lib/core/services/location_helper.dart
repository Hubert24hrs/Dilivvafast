import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// Robust location helper with GPS, geocoding, and error handling.
///
/// Addresses come from the phone's own geocoder (Google's, on Android) — it
/// needs no API key. When it is unavailable (offline, no Play services, or
/// under test) a short list of well-known Nigerian locations is used instead.
class LocationHelper {
  LocationHelper();

  static const double lagosLat = 6.5244;
  static const double lagosLng = 3.3792;

  static final _geocoder = geo.Geocoding();

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
  /// Falls back to the nearest well-known place, then to the coordinates.
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final marks = await _geocoder
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 8));
      if (marks.isNotEmpty) {
        final label = describePlacemark(marks.first);
        if (label.isNotEmpty) return label;
      }
    } catch (e) {
      debugPrint('LocationHelper.reverseGeocode error: $e');
    }
    return _matchNearestKnownLocation(lat, lng) ??
        '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  /// "12 Admiralty Way, Lekki Phase 1, Lagos" from a placemark's parts,
  /// skipping blanks and repeats (geocoders often echo the street as the name).
  @visibleForTesting
  static String describePlacemark(geo.Placemark p) {
    final parts = <String>[];
    void add(String? v) {
      final t = v?.trim() ?? '';
      if (t.isEmpty) return;
      if (parts.any((e) => e.toLowerCase() == t.toLowerCase())) return;
      // A bare plus-code ("6CV7+2M") reads as noise to a customer.
      if (RegExp(r'^[0-9A-Z]{4}\+[0-9A-Z]{2,3}$').hasMatch(t)) return;
      parts.add(t);
    }

    add(p.name != p.street ? p.name : null);
    add(p.street);
    add(p.subLocality);
    add(p.locality ?? p.subAdministrativeArea);
    add(p.administrativeArea);
    return parts.take(4).join(', ');
  }

  // ==================== FORWARD GEOCODING (SEARCH) ====================

  /// Search for addresses matching [query], within Nigeria.
  Future<List<GeocodedAddress>> searchAddresses(String query) async {
    final q = query.trim();
    if (q.isEmpty) return _defaultLocations;

    final lower = q.toLowerCase();
    final known = _defaultLocations
        .where((loc) => loc.address.toLowerCase().contains(lower))
        .toList();

    final found = <GeocodedAddress>[];
    try {
      final hits = await _geocoder
          .locationFromAddress(lower.contains('nigeria') ? q : '$q, Nigeria')
          .timeout(const Duration(seconds: 8));
      for (final hit in hits.take(5)) {
        String label = q;
        try {
          final marks = await _geocoder
              .placemarkFromCoordinates(hit.latitude, hit.longitude)
              .timeout(const Duration(seconds: 5));
          if (marks.isNotEmpty) {
            final described = describePlacemark(marks.first);
            if (described.isNotEmpty) label = described;
          }
        } catch (_) {
          // Keep what the customer typed as the label.
        }
        found.add(
          GeocodedAddress(
            address: label,
            lat: hit.latitude,
            lng: hit.longitude,
          ),
        );
      }
    } catch (e) {
      // NoResultFoundException is the normal "nothing matched" answer.
      debugPrint('LocationHelper.searchAddresses: $e');
    }

    // Geocoder hits first, then any well-known place that matches by name.
    final seen = <String>{};
    return [
      for (final a in [...found, ...known])
        if (seen.add(a.address.toLowerCase())) a,
    ];
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
    GeocodedAddress(address: 'Lekki Phase 1, Lagos', lat: 6.4479, lng: 3.4737),
    GeocodedAddress(
      address: 'Victoria Island, Lagos',
      lat: 6.4281,
      lng: 3.4219,
    ),
    GeocodedAddress(address: 'Ikeja, Lagos', lat: 6.6018, lng: 3.3515),
    GeocodedAddress(address: 'Surulere, Lagos', lat: 6.5059, lng: 3.3598),
    GeocodedAddress(address: 'Yaba, Lagos', lat: 6.5158, lng: 3.3817),
    GeocodedAddress(address: 'Ajah, Lagos', lat: 6.4670, lng: 3.5860),
    GeocodedAddress(address: 'Ikoyi, Lagos', lat: 6.4490, lng: 3.4310),
    GeocodedAddress(address: 'Marina, Lagos Island', lat: 6.4474, lng: 3.3903),
    GeocodedAddress(address: 'Wuse 2, Abuja', lat: 9.0643, lng: 7.4892),
    GeocodedAddress(address: 'Garki, Abuja', lat: 9.0388, lng: 7.4918),
    GeocodedAddress(address: 'Maitama, Abuja', lat: 9.0826, lng: 7.4953),
    GeocodedAddress(address: 'GRA, Port Harcourt', lat: 4.8156, lng: 7.0498),
    GeocodedAddress(address: 'Sabon Gari, Kano', lat: 12.0022, lng: 8.5127),
    GeocodedAddress(address: 'Gbagada, Lagos', lat: 6.5538, lng: 3.3847),
    GeocodedAddress(address: 'Ogba, Lagos', lat: 6.6260, lng: 3.3408),
    GeocodedAddress(address: 'Festac Town, Lagos', lat: 6.4676, lng: 3.2850),
    GeocodedAddress(address: 'Maryland, Lagos', lat: 6.5731, lng: 3.3640),
    GeocodedAddress(address: 'Oshodi, Lagos', lat: 6.5568, lng: 3.3418),
  ];

  /// Show a dialog prompting the user to enable location services.
  static Future<void> showLocationServicesDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Location Services Disabled',
          style: TextStyle(color: context.palette.textPrimary),
        ),
        content: Text(
          'Please enable location services in your device settings '
          'to use automatic location detection.',
          style: TextStyle(color: context.palette.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.palette.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Open Settings',
              style: TextStyle(color: context.palette.onBrand),
            ),
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
        backgroundColor: context.palette.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Location Permission Required',
          style: TextStyle(color: context.palette.textPrimary),
        ),
        content: Text(
          'We need access to your location to show your pickup address. '
          'Please grant location permission in your app settings.',
          style: TextStyle(color: context.palette.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.palette.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Open Settings',
              style: TextStyle(color: context.palette.onBrand),
            ),
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
