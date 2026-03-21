import 'package:flutter/material.dart';

/// Stub earnings service for drivers
class EarningsService {
  Future<double> getTotalEarnings(String driverId) async {
    debugPrint('EarningsService.getTotalEarnings (stub)');
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> getEarningsHistory(String driverId) async {
    debugPrint('EarningsService.getEarningsHistory (stub)');
    return [];
  }
}
