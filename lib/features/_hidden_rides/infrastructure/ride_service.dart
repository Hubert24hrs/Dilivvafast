import 'package:flutter/material.dart';
import 'package:dilivvafast/features/_hidden_rides/domain/entities/ride_model.dart';

/// Stub ride service
class RideService {
  Stream<List<RideModel>> getAvailableRides() {
    debugPrint('RideService.getAvailableRides (stub)');
    return Stream.value([]);
  }

  Future<void> acceptRide({
    required String rideId,
    required String driverId,
  }) async {
    debugPrint('RideService.acceptRide (stub)');
  }

  Future<void> cancelRide(String rideId) async {
    debugPrint('RideService.cancelRide (stub)');
  }
}
