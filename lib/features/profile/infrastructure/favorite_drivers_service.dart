import 'package:flutter/material.dart';

/// Stub favorite drivers service
class FavoriteDriversService {
  Future<List<String>> getFavoriteDriverIds(String userId) async {
    debugPrint('FavoriteDriversService.getFavoriteDriverIds (stub)');
    return [];
  }

  Future<void> addFavoriteDriver({
    required String userId,
    required String driverId,
  }) async {
    debugPrint('FavoriteDriversService.addFavoriteDriver (stub)');
  }

  Future<void> removeFavoriteDriver({
    required String userId,
    required String driverId,
  }) async {
    debugPrint('FavoriteDriversService.removeFavoriteDriver (stub)');
  }
}
