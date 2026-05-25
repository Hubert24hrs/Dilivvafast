import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:fast_delivery/presentation/common/platform_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CourierTrackingScreen extends ConsumerStatefulWidget {
  final String? courierId;

  const CourierTrackingScreen({super.key, this.courierId});

  @override
  ConsumerState<CourierTrackingScreen> createState() => _CourierTrackingScreenState();
}

class _CourierTrackingScreenState extends ConsumerState<CourierTrackingScreen> {
  // ignore: unused_field - assigned in onMapCreated for potential future use
  PlatformMapboxMap? _mapboxMap;

  _onMapCreated(dynamic mapboxMap) async {
    _mapboxMap = mapboxMap as PlatformMapboxMap?;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.courierId == null) {
      return const Scaffold(body: Center(child: Text('No courier ID provided')));
    }

    final courierStream = ref.watch(databaseServiceProvider).streamCourier(widget.courierId!);

    return Scaffold(
      body: Stack(
        children: [
          // Map Background - uses platform-agnostic widget
          PlatformMapWidget(
            onMapCreated: _onMapCreated,
            initialLat: 6.5244,
            initialLng: 3.3792,
            initialZoom: 13.0,
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
            ),
          ),

          // Courier Details Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<CourierModel?>(
              stream: courierStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                final courier = snapshot.data;
                if (courier == null) {
                  return GlassCard(
                    child: const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                    ),
                  );
                }

                return _buildCourierDetailsSheet(courier);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourierDetailsSheet(CourierModel courier) {
    final status = courier.status;
    final hasDriver = courier.riderId != null && courier.riderId!.isNotEmpty;

    return GlassCard(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Status Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusSubtitle(status),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Activity Timeline
            _buildActivityTimeline(courier),
            const SizedBox(height: 24),

            // Package Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.inventory_2, 'Package', courier.packageSize),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.my_location, 'From', courier.pickupAddress),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.flag, 'To', courier.dropoffAddress),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.attach_money, 'Price', '₦${courier.price.toStringAsFixed(0)}'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            if (hasDriver)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Call receiver using their phone number
                        final phoneNumber = courier.receiverPhone.replaceAll(RegExp(r'[^\d+]'), '');
                        if (phoneNumber.isNotEmpty) {
                          final uri = Uri.parse('tel:$phoneNumber');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not launch phone dialer')),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No phone number available')),
                          );
                        }
                      },
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('CALL'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to chat screen with courier ID
                        context.push('/chat', extra: {
                          'recipientId': courier.riderId,
                          'recipientName': 'Dispatch Rider',
                          'courierId': courier.id,
                        });
                      },
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('CHAT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),

            if (!hasDriver && status == 'pending')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Looking for nearby dispatch riders...',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTimeline(CourierModel courier) {
    final timeFormat = DateFormat('HH:mm');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Timeline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Order Placed
          _buildTimelineItem(
            icon: Icons.receipt_long,
            title: 'Order Placed',
            time: timeFormat.format(courier.createdAt),
            isCompleted: true,
            isFirst: true,
          ),
          
          // Driver Accepted
          _buildTimelineItem(
            icon: Icons.check_circle,
            title: 'Driver Accepted',
            time: courier.acceptedAt != null 
              ? timeFormat.format(courier.acceptedAt!) 
              : null,
            isCompleted: courier.acceptedAt != null,
          ),
          
          // Driver Arrived
          _buildTimelineItem(
            icon: Icons.location_on,
            title: 'Driver Arrived',
            time: courier.arrivedAt != null 
              ? timeFormat.format(courier.arrivedAt!) 
              : null,
            isCompleted: courier.arrivedAt != null,
          ),
          
          // Trip Started
          _buildTimelineItem(
            icon: Icons.directions_car,
            title: 'Trip Started',
            time: courier.tripStartedAt != null 
              ? timeFormat.format(courier.tripStartedAt!) 
              : null,
            isCompleted: courier.tripStartedAt != null,
          ),
          
          // Delivered
          _buildTimelineItem(
            icon: Icons.flag,
            title: 'Delivered',
            time: courier.tripEndedAt != null 
              ? timeFormat.format(courier.tripEndedAt!) 
              : null,
            isCompleted: courier.tripEndedAt != null,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    String? time,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector and icon
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top connector line
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 8,
                    color: isCompleted ? AppTheme.primaryColor : Colors.white24,
                  ),
                // Icon circle
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted 
                      ? AppTheme.primaryColor 
                      : Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted 
                        ? AppTheme.primaryColor 
                        : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: isCompleted ? Colors.black : Colors.white38,
                  ),
                ),
                // Bottom connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppTheme.primaryColor : Colors.white24,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isCompleted ? Colors.white : Colors.white38,
                      fontSize: 14,
                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (time != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'arrived': return Colors.purple;
      case 'in_transit': return AppTheme.primaryColor;
      case 'delivered': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty;
      case 'accepted': return Icons.person;
      case 'arrived': return Icons.location_on;
      case 'in_transit': return Icons.local_shipping;
      case 'delivered': return Icons.check_circle;
      default: return Icons.info;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'pending': return 'Finding Rider';
      case 'accepted': return 'Rider Assigned';
      case 'arrived': return 'Rider Arrived';
      case 'in_transit': return 'Package in Transit';
      case 'delivered': return 'Delivered!';
      default: return 'Processing';
    }
  }

  String _getStatusSubtitle(String status) {
    switch (status) {
      case 'pending': return 'We\'re finding a dispatch rider nearby';
      case 'accepted': return 'Rider is heading to pickup';
      case 'arrived': return 'Rider has arrived at pickup location';
      case 'in_transit': return 'Your package is on the way';
      case 'delivered': return 'Successfully delivered';
      default: return 'Please wait';
    }
  }
}
