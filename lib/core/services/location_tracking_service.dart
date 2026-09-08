import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:dilivvafast/core/constants/firestore_constants.dart';

/// Real-time driver location tracking.
///
/// Position is published to `driver_locations/{driverId}`, NOT onto the
/// driver's `users` document. Customers need to see where their courier is,
/// and the rule that allowed that previously exposed the whole user record —
/// email, phone, wallet balance, FCM token — to every signed-in customer.
/// `driver_locations` carries only presence and coordinates, and firestore.rules
/// rejects any write to it containing an identifying field.
class LocationTrackingService {
  LocationTrackingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  DateTime? _lastWrite;

  /// Floor on how often a position is written, on top of the 20 m distance
  /// filter. A courier in stop-start traffic would otherwise generate a write
  /// per GPS fix, which costs money and drains the handset battery.
  static const Duration _minWriteInterval = Duration(seconds: 10);

  bool get isTracking => _isTracking;

  CollectionReference<Map<String, dynamic>> get _presenceRef =>
      _firestore.collection(FirestoreConstants.driverLocations);

  /// Start publishing position. Safe to call repeatedly.
  Future<void> startTracking(String userId) async {
    if (_isTracking) return;

    final permission = await _ensurePermissions();
    if (!permission) return;

    _isTracking = true;

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 20, // metres
          ),
        ).listen(
          (position) {
            if (!_shouldWrite()) return;
            // Fire-and-forget by design, but errors are surfaced in debug rather
            // than swallowed silently.
            unawaited(_publishLocation(userId, position));
          },
          onError: (Object e) {
            debugPrint('LocationTrackingService: position stream error: $e');
            _isTracking = false;
          },
          cancelOnError: false,
        );
  }

  /// Stop tracking and take the driver off the live map.
  Future<void> stopTracking(String userId) async {
    _isTracking = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastWrite = null;

    try {
      await _presenceRef.doc(userId).set({
        'driverId': userId,
        'isOnline': false,
        'isAvailable': false,
        'location': FieldValue.delete(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('LocationTrackingService: stopTracking write failed: $e');
    }
  }

  /// Get current position (one-shot).
  Future<Position?> getCurrentPosition() async {
    final permission = await _ensurePermissions();
    if (!permission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('LocationTrackingService: getCurrentPosition failed: $e');
      return null;
    }
  }

  bool _shouldWrite() {
    final now = DateTime.now();
    final last = _lastWrite;
    if (last != null && now.difference(last) < _minWriteInterval) return false;
    _lastWrite = now;
    return true;
  }

  Future<void> _publishLocation(String userId, Position position) async {
    // Reject obviously impossible fixes rather than publishing them to
    // customers as a courier teleporting across the map.
    if (position.latitude.abs() > 90 || position.longitude.abs() > 180) return;
    if (position.latitude == 0 && position.longitude == 0) return;

    try {
      await _presenceRef.doc(userId).set({
        'driverId': userId,
        'location': GeoPoint(position.latitude, position.longitude),
        'heading': position.heading,
        'speed': position.speed,
        'isOnline': true,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('LocationTrackingService: location write failed: $e');
    }
  }

  /// Ensure foreground location permission is granted.
  ///
  /// Foreground ("while in use") only. The app does not declare or request
  /// ACCESS_BACKGROUND_LOCATION, so no Google Play prominent-disclosure screen
  /// is required and none exists. If background tracking is ever added, read
  /// PLAY_STORE.md before writing the code — the disclosure has to ship with
  /// it, not after.
  Future<bool> _ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Clean up.
  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }
}
