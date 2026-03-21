import 'package:flutter/material.dart';

/// Stub email service
class EmailService {
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    debugPrint('EmailService.sendEmail called (stub): to=$to, subject=$subject');
    return true;
  }
}
