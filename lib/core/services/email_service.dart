import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:dilivvafast/core/models/ride_model.dart';
import 'package:dilivvafast/core/services/receipt_service.dart';

class EmailService {
  final ReceiptService _receiptService = ReceiptService();

  // Send receipt email using real SMTP settings from .env
  Future<bool> sendReceiptEmail({
    required String recipientEmail,
    required RideModel ride,
    String? recipientName,
  }) async {
    if (kIsWeb) {
      debugPrint('EmailService: Real SMTP is disabled for Web builds.');
      return sendReceiptEmailMock(
        recipientEmail: recipientEmail,
        ride: ride,
        recipientName: recipientName,
      );
    }

    try {
      final host = dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
      final port = int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
      final username = dotenv.env['SMTP_USERNAME'] ?? '';
      final password = dotenv.env['SMTP_PASSWORD'] ?? '';
      final senderName = dotenv.env['SENDER_NAME'] ?? 'Dilivvafast';
      final senderEmail = dotenv.env['SENDER_EMAIL'] ?? 'noreply@dilivvafast.ng';

      if (username.isEmpty || password.isEmpty) {
        debugPrint('EmailService: SMTP credentials are not configured in .env. Falling back to mock email.');
        return sendReceiptEmailMock(
          recipientEmail: recipientEmail,
          ride: ride,
          recipientName: recipientName,
        );
      }

      // Generate PDF receipt path
      final pdfPath = await _receiptService.generateReceipt(ride);
      final pdfFile = io.File(pdfPath);

      // Setup SMTP server (using Gmail helper or custom SMTP server)
      SmtpServer smtpServer;
      if (host.contains('gmail')) {
        smtpServer = gmail(username, password);
      } else {
        smtpServer = SmtpServer(
          host,
          port: port,
          ssl: port == 465,
          username: username,
          password: password,
        );
      }

      // Create email message
      final message = Message()
        ..from = Address(senderEmail, senderName)
        ..recipients.add(recipientEmail)
        ..subject = 'Your Dilivvafast Trip Receipt - ${ride.id.substring(0, 8).toUpperCase()}'
        ..html = _buildEmailHtml(ride, recipientName);

      // Attach PDF receipt if it exists (mobile compatibility)
      if (await pdfFile.exists()) {
        message.attachments.add(FileAttachment(pdfFile, fileName: 'receipt_${ride.id.substring(0, 8)}.pdf'));
      }

      // Send the email
      final sendReport = await send(message, smtpServer);
      
      if (kDebugMode) {
        debugPrint('EmailService: Live email sent successfully: ${sendReport.toString()}');
      }

      return true;
    } catch (e) {
      debugPrint('EmailService: Live email sending failed: $e');
      return false;
    }
  }

  // Mock email sending for testing (doesn't require SMTP)
  Future<bool> sendReceiptEmailMock({
    required String recipientEmail,
    required RideModel ride,
    String? recipientName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (kDebugMode) {
      debugPrint('=== MOCK EMAIL SENT ===');
      debugPrint('To: $recipientEmail');
      debugPrint('Subject: Your Dilivvafast Trip Receipt - ${ride.id.substring(0, 8).toUpperCase()}');
      debugPrint('Attachment: receipt_${ride.id.substring(0, 8)}.pdf');
      debugPrint('========================');
    }

    return true;
  }

  // Helper to build a clean HTML template for the email body
  String _buildEmailHtml(RideModel ride, String? recipientName) {
    final name = recipientName ?? 'Valued Customer';
    final fare = ride.fare.toStringAsFixed(0);
    return '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
      <div style="text-align: center; margin-bottom: 20px;">
        <h2 style="color: #00D66C; margin: 0;">DILIVVAFAST RECEIPT</h2>
        <p style="color: #666; font-size: 14px;">Thanks for delivery with us, $name!</p>
      </div>
      
      <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
        <table style="width: 100%; font-size: 14px;">
          <tr>
            <td style="color: #666; padding: 5px 0;">Trip ID:</td>
            <td style="text-align: right; font-weight: bold; padding: 5px 0;">${ride.id.toUpperCase()}</td>
          </tr>
          <tr>
            <td style="color: #666; padding: 5px 0;">Date:</td>
            <td style="text-align: right; padding: 5px 0;">${DateTime.now().toLocal().toString().substring(0, 16)}</td>
          </tr>
          <tr>
            <td style="color: #666; padding: 5px 0;">Payment Method:</td>
            <td style="text-align: right; padding: 5px 0; text-transform: capitalize;">${ride.paymentMethod}</td>
          </tr>
        </table>
      </div>
      
      <div style="border-top: 2px solid #eee; border-bottom: 2px solid #eee; padding: 15px 0; margin-bottom: 20px;">
        <table style="width: 100%; font-size: 16px;">
          <tr style="font-weight: bold;">
            <td style="color: #333;">Total Fare:</td>
            <td style="text-align: right; color: #00D66C;">₦$fare</td>
          </tr>
        </table>
      </div>
      
      <div style="text-align: center; color: #999; font-size: 12px; margin-top: 30px;">
        <p>© ${DateTime.now().year} Dilivvafast Technologies. All rights reserved.</p>
        <p>If you have any questions, contact support in the app.</p>
      </div>
    </div>
    ''';
  }
}
