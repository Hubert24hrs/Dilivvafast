import 'package:flutter/material.dart';

class PaymentService {
  Future<void> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  Future<bool> chargeCard({
    required BuildContext context,
    required double amount,
    required String email,
    String reference = '',
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing Payment of \u20A6$amount...'),
          ],
        ),
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.pop(context);

      await showDialog<void>(
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
