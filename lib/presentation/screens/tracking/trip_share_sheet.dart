import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class TripShareSheet extends ConsumerWidget {
  final RideModel ride;

  const TripShareSheet({super.key, required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Icon(Icons.share_location, color: AppTheme.primaryColor, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Share Your Trip',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Let friends and family track your ride in real-time',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Trip Info
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(Icons.my_location, 'From', ride.pickupAddress),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on, 'To', ride.dropoffAddress),
                  if (ride.driverName != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.person, 'Driver', ride.driverName!),
                  ],
                  if (ride.carModel != null && ride.carModel!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.directions_car, 'Vehicle', ride.carModel!),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Share Options
          Row(
            children: [
              Expanded(
                child: _buildShareButton(
                  context,
                  Icons.message,
                  'SMS',
                  () => _shareViaSMS(context, ride),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShareButton(
                  context,
                  Icons.share,
                  'More',
                  () => _shareGeneric(context, ride),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(color: Colors.white54)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _shareViaSMS(BuildContext context, RideModel ride) {
    final message = _buildShareMessage(ride);
    SharePlus.instance.share(ShareParams(text: message));
    Navigator.pop(context);
  }

  void _shareGeneric(BuildContext context, RideModel ride) {
    final message = _buildShareMessage(ride);
    SharePlus.instance.share(ShareParams(text: message, subject: 'My Fast Delivery Trip'));
    Navigator.pop(context);
  }

  String _buildShareMessage(RideModel ride) {
    return '''I'm on a trip with Fast Delivery!

🚗 From: ${ride.pickupAddress}
📍 To: ${ride.dropoffAddress}
${ride.driverName != null ? '👨‍✈️ Driver: ${ride.driverName}' : ''}
${ride.carModel != null && ride.carModel!.isNotEmpty ? '🚙 Vehicle: ${ride.carModel}' : ''}

Track my trip: https://fastdelivery.ng/track/${ride.id}''';
  }
}
