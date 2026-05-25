import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/services/email_service.dart';
import 'package:fast_delivery/core/services/receipt_service.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HistoryDetailsScreen extends StatelessWidget {
  final RideModel? ride;
  final CourierModel? courier;

  const HistoryDetailsScreen({
    super.key,
    this.ride,
    this.courier,
  });

  @override
  Widget build(BuildContext context) {
    if (ride == null && courier == null) {
      return const Scaffold(body: Center(child: Text('Error: No data provided')));
    }

    final isRide = ride != null;
    final date = isRide ? ride!.createdAt : courier!.createdAt;
    final price = isRide ? ride!.price : courier!.price;
    final status = isRide ? ride!.status : courier!.status;
    final pickup = isRide ? ride!.pickupAddress : courier!.pickupAddress;
    final dropoff = isRide ? ride!.dropoffAddress : courier!.dropoffAddress;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isRide ? 'Ride Details' : 'Delivery Details',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₦${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, y • h:mm a').format(date),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Route
            const Text(
              'Route',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildLocationRow(Icons.my_location, 'Pickup', pickup, Colors.green),
            _buildDottedLine(),
            _buildLocationRow(Icons.location_on, 'Dropoff', dropoff, Colors.red),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Specific Details
            if (!isRide) ...[
              const Text(
                'Package Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Package Size', courier!.packageSize),
              _buildDetailRow('Receiver Name', courier!.receiverName),
              _buildDetailRow('Receiver Phone', courier!.receiverPhone),
            ],

            if (isRide && ride!.driverName != null) ...[
              const Text(
                'Driver Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride!.driverName!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${ride!.carModel} • ${ride!.plateNumber}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            
            // Download Receipt Button
            if (isRide && status == 'completed') ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating receipt...')),
                    );
                    try {
                      final receiptService = ReceiptService();
                      final path = await receiptService.generateReceipt(ride!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Receipt saved to: $path')),
                        );
                        // In production, use open_file or share_plus to open/share
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('DOWNLOAD RECEIPT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showEmailDialog(context, ride!),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('EMAIL RECEIPT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDottedLine() {
    return Container(
      margin: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
      height: 20,
      width: 2,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showEmailDialog(BuildContext context, RideModel ride) {
    final emailController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Email Receipt'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      if (emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter an email')),
                        );
                        return;
                      }

                      setDialogState(() => isSending = true);

                      // Use mock email for now (replace with real SMTP later)
                      final emailService = EmailService();
                      final success = await emailService.sendReceiptEmailMock(
                        recipientEmail: emailController.text.trim(),
                        ride: ride,
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Receipt sent to ${emailController.text}'
                                  : 'Failed to send email',
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
              ),
              child: isSending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
