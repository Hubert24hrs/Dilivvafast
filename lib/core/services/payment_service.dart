import 'package:flutter/material.dart';

class PaymentService {
  Future<void> initialize() async {
    // Mock initialization
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<bool> chargeCard({
    required BuildContext context,
    required double amount,
    required String email,
    String reference = '',
  }) async {
    // Mock payment flow
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing Payment of ₦$amount...'),
          ],
        ),
      ),
    );

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      
      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Successful'),
          content: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    return true;
  }
}
