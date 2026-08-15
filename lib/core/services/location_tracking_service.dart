import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Outcome of asking for location access, so the UI can explain what to do.
enum LocationPermissionResult {
  /// Foreground and background both granted — tracking survives backgrounding.
  granted,

  /// Foreground only. Tracking works while the driver has the app open, but
  /// stops once they switch to a navigation app.
  foregroundOnly,

  /// Refused, or location services are switched off entirely.
  denied,

  /// Refused permanently — only the system settings screen can undo this.
  deniedForever,
}

/// Real-time driver location tracking.
///
/// While a driver is on duty their position is written to two places:
///
///  * their own user document, which admins watch on the live operations map;
///  * the active order, which is the only copy the *customer* can read —
///    firestore.rules deliberately keeps one user from reading another's
///    profile, so tracking cannot go through the users collection.
class LocationTrackingService {
  LocationTrackingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  String? _activeOrderId;

  bool get isTracking => _isTracking;

  /// The order currently being broadcast to, if any.
  String? get activeOrderId => _activeOrderId;

  /// Start tracking and writing location to Firestore.
  ///
  /// Pass [orderId] when the driver is on an active delivery so the customer's
  /// tracking map updates. Returns false if permission was refused.
  Future<bool> startTracking(String userId, {String? orderId}) async {
    _activeOrderId = orderId;

    if (_isTracking) return true;

    final permission = await ensurePermissions();
    if (permission == LocationPermissionResult.denied ||
        permission == LocationPermissionResult.deniedForever) {
      return false;
    }

    _isTracking = true;

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 20, // Update every 20 meters
          ),
        ).listen(
          (position) => _publishLocation(userId, position),
          onError: (Object e) {
            debugPrint('Location stream error: $e');
            _isTracking = false;
          },
        );

    return true;
  }

  /// Point tracking at a different delivery without restarting the GPS stream.
  void setActiveOrder(String? orderId) => _activeOrderId = orderId;

  /// Stop tracking and clear the driver's published position.
  Future<void> stopTracking(String userId) async {
    _isTracking = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _activeOrderId = null;

    try {
      await _firestore.collection('users').doc(userId).update({
        'location': FieldValue.delete(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Could not clear driver location: $e');
    }
  }

  /// Get current position (one-shot).
  Future<Position?> getCurrentPosition() async {
    final permission = await ensurePermissions();
    if (permission == LocationPermissionResult.denied ||
        permission == LocationPermissionResult.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Could not read current position: $e');
      return null;
    }
  }

  Future<void> _publishLocation(String userId, Position position) async {
    final point = GeoPoint(position.latitude, position.longitude);

    try {
      await _firestore.collection('users').doc(userId).update({
        'location': point,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'heading': position.heading,
        'speed': position.speed,
      });
    } catch (e) {
      debugPrint('Could not publish driver location: $e');
    }

    final orderId = _activeOrderId;
    if (orderId == null) return;

    try {
      await _firestore.collection('orders').doc(orderId).update({
        'driverLocation': point,
        'driverLocationUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Could not publish location to order $orderId: $e');
    }
  }

  /// Ensure location permission, escalating to background access.
  ///
  /// Android 10+ only grants background ("Allow all the time") access on a
  /// second, separate request, and Google Play requires a prominent in-app
  /// disclosure before it is asked for — show that screen before calling this.
  /// Foreground-only is not treated as failure: the driver can still work,
  /// they just stop broadcasting once they leave the app.
  Future<LocationPermissionResult> ensurePermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionResult.denied;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return LocationPermissionResult.denied;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionResult.deniedForever;
    }

    if (permission == LocationPermission.whileInUse) {
      // Second prompt: "Allow all the time". Users often decline, which is
      // fine — we degrade to foreground-only rather than blocking the driver.
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always
        ? LocationPermissionResult.granted
        : LocationPermissionResult.foregroundOnly;
  }

  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    _activeOrderId = null;
  }
}
