import 'package:flutter/material.dart';

/// Stub rating service
class RatingService {
  Future<void> submitRating({
    required String rideId,
    required String fromUserId,
    required String toUserId,
    required double rating,
    String? comment,
  }) async {
    debugPrint('RatingService.submitRating (stub): $rating');
  }

  Future<double> getAverageRating(String userId) async {
    debugPrint('RatingService.getAverageRating (stub)');
    return 5.0;
  }
}
