import 'package:flutter/material.dart';

/// Stub Paystack payment service — implement with flutter_paystack_plus
class PaystackService {
  Future<void> initialize() async {
    debugPrint('PaystackService initialized (stub)');
  }

  Future<bool> chargeCard({
    required String email,
    required double amount,
    required String reference,
  }) async {
    debugPrint('PaystackService.chargeCard called (stub): $amount');
    return true;
  }
}
