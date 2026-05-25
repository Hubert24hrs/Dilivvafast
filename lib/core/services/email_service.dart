// import 'dart:io';
// import 'package:mailer/mailer.dart';
// import 'package:mailer/smtp_server.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  // SMTP Configuration is handled by backend services
  // This service provides a stub for web compatibility

  // Send receipt email
  Future<bool> sendReceiptEmail({
    required String recipientEmail,
    required RideModel ride,
    String? recipientName,
  }) async {
    // WEB COMPATIBILITY: functionality disabled
    debugPrint('EmailService: sendReceiptEmail called for $recipientEmail. (Disabled for Web Build)');
    return true; /*
    try {
      // Generate PDF receipt
      final pdfPath = await _receiptService.generateReceipt(ride);
      final pdfFile = File(pdfPath);

      if (!await pdfFile.exists()) {
        throw Exception('Failed to generate receipt PDF');
      }

      // Configure SMTP server
      // Note: For Gmail, you need to use App Passwords with 2FA enabled
      final smtpServer = gmail(_smtpUsername, _smtpPassword);

      // Create the email message
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(recipientEmail)
        ..subject = 'Your Fast Delivery Trip Receipt - ${ride.id.substring(0, 8).toUpperCase()}'
        ..html = _buildEmailHtml(ride, recipientName)
        ..attachments = [FileAttachment(pdfFile, fileName: 'receipt_${ride.id.substring(0, 8)}.pdf')];

      // Send the email
      final sendReport = await send(message, smtpServer);
      
      if (kDebugMode) {
        debugPrint('Email sent: ${sendReport.toString()}');
      }

      return true;
    } on MailerException catch (e) {
      if (kDebugMode) {
        debugPrint('Email sending failed: ${e.message}');
        for (var p in e.problems) {
          debugPrint('Problem: ${p.code}: ${p.msg}');
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Email error: $e');
      }
      return false;
    } */
  }

  // Mock email sending for testing (doesn't require SMTP)
  Future<bool> sendReceiptEmailMock({
    required String recipientEmail,
    required RideModel ride,
    String? recipientName,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (kDebugMode) {
      debugPrint('=== MOCK EMAIL SENT ===');
      debugPrint('To: $recipientEmail');
      debugPrint('Subject: Your Fast Delivery Trip Receipt - ${ride.id.substring(0, 8).toUpperCase()}');
      debugPrint('Attachment: receipt_${ride.id.substring(0, 8)}.pdf');
      debugPrint('========================');
    }

    // Generate the PDF anyway so we can show the path
    // final pdfPath = await _receiptService.generateReceipt(ride);
    // if (kDebugMode) {
    //   debugPrint('Receipt PDF generated at: $pdfPath');
    // }

    return true;
  }


}
