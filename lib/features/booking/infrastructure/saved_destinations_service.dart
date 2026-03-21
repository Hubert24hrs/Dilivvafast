import 'package:flutter/material.dart';

/// Stub saved destinations service
class SavedDestinationsService {
  Future<List<Map<String, dynamic>>> getSavedDestinations(String userId) async {
    debugPrint('SavedDestinationsService.getSavedDestinations (stub)');
    return [];
  }

  Future<void> saveDestination({
    required String userId,
    required String name,
    required double lat,
    required double lng,
    required String address,
  }) async {
    debugPrint('SavedDestinationsService.saveDestination (stub): $name');
  }

  Future<void> deleteDestination({
    required String userId,
    required String destinationId,
  }) async {
    debugPrint('SavedDestinationsService.deleteDestination (stub)');
  }
}
