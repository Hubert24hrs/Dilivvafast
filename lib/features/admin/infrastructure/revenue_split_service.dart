import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub revenue split service
class RevenueSplitService {
  RevenueSplitService(this._ref);

  // ignore: unused_field
  final Ref _ref;

  Future<Map<String, double>> calculateSplit({
    required double totalAmount,
    required String rideId,
  }) async {
    debugPrint('RevenueSplitService.calculateSplit (stub)');
    return {
      'driver': totalAmount * 0.7,
      'platform': totalAmount * 0.2,
      'investor': totalAmount * 0.1,
    };
  }
}
