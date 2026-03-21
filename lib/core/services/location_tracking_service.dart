import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Service for real-time driver location tracking.
/// Streams GPS position and updates Firestore.
class LocationTrackingService {
  LocationTrackingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  /// Start tracking and writing location to Firestore
  Future<void> startTracking(String userId) async {
    if (_isTracking) return;

    // Check and request permissions
    final permission = await _ensurePermissions();
    if (!permission) return;

    _isTracking = true;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // Update every 20 meters
      ),
    ).listen(
      (position) {
        _updateFirestoreLocation(userId, position);
      },
      onError: (e) {
        // Silently handle location errors
        _isTracking = false;
      },
    );
  }

  /// Stop tracking
  Future<void> stopTracking(String userId) async {
    _isTracking = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    // Clear location from Firestore
    try {
      await _firestore.collection('users').doc(userId).update({
        'location': FieldValue.delete(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Get current position (one-shot)
  Future<Position?> getCurrentPosition() async {
    final permission = await _ensurePermissions();
    if (!permission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Update location in Firestore
  Future<void> _updateFirestoreLocation(
      String userId, Position position) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'heading': position.heading,
        'speed': position.speed,
      });
    } catch (_) {}
  }

  /// Ensure location permissions are granted
  Future<bool> _ensurePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Clean up
  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }
}
