import 'dart:async';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/app_drawer.dart';
import 'package:fast_delivery/presentation/screens/booking/booking_sheet.dart';
import 'package:fast_delivery/presentation/common/platform_map_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Platform map widget handles map creation internally

  RideModel? _activeRide;
  StreamSubscription<RideModel?>? _rideSubscription;

  @override
  void initState() {
    super.initState();
    _checkAndStreamActiveRide();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAndStreamActiveRide() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final userId = ref.read(authServiceProvider).currentUser?.uid;
    if (userId != null) {
      if (kDebugMode) debugPrint('HomeScreen: Checking active ride for userId: $userId');
      
      final ride = await ref.read(rideServiceProvider).getActiveRideForUser(userId);
      if (ride != null && mounted) {
        if (kDebugMode) debugPrint('HomeScreen: Active ride found (${ride.id}). Starting stream.');
        _startListeningToRide(ride.id);
      }
    }
  }

  void _startListeningToRide(String rideId) {
    _rideSubscription?.cancel();
    _rideSubscription = ref.read(rideServiceProvider).streamRide(rideId).listen(
      (ride) {
        if (mounted) {
          if (kDebugMode) debugPrint('HomeScreen: Ride update received - status: ${ride?.status}');
          setState(() {
            _activeRide = ride;
          });
          
          // If ride is completed or cancelled, stop listening
          if (ride == null || ride.status == 'completed' || ride.status == 'cancelled') {
            _rideSubscription?.cancel();
            _rideSubscription = null;
            setState(() => _activeRide = null);
          }
        }
      },
      onError: (error) {
        if (kDebugMode) debugPrint('HomeScreen: Stream error: $error');
      },
    );
  }

  // Call this after booking a new ride
  void startTrackingRide(String rideId) {
    _startListeningToRide(rideId);
  }

  _onMapCreated(dynamic mapboxMap) {
    // Map instance available if needed for future functionality
  }

  // Get status display info based on ride status
  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {
          'title': 'Finding Driver',
          'subtitle': 'Looking for nearby drivers...',
          'icon': Icons.search,
          'color': Colors.orange,
        };
      case 'accepted':
        return {
          'title': 'Driver Accepted!',
          'subtitle': 'Driver is on the way to pick you up',
          'icon': Icons.check_circle,
          'color': Colors.blue,
        };
      case 'arrived':
        return {
          'title': 'Driver Arrived',
          'subtitle': 'Your driver is waiting at pickup',
          'icon': Icons.location_on,
          'color': Colors.purple,
        };
      case 'in_progress':
        return {
          'title': 'Trip in Progress',
          'subtitle': 'On the way to your destination',
          'icon': Icons.directions_car,
          'color': AppTheme.primaryColor,
        };
      case 'completed':
        return {
          'title': 'Trip Completed',
          'subtitle': 'You have arrived!',
          'icon': Icons.flag,
          'color': Colors.green,
        };
      default:
        return {
          'title': 'Ride Active',
          'subtitle': 'Tap to track your ride',
          'icon': Icons.directions_car,
          'color': AppTheme.primaryColor,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Map Background - uses platform-agnostic widget
          PlatformMapWidget(
            onMapCreated: _onMapCreated,
            initialLat: 6.5244,
            initialLng: 3.3792,
            initialZoom: 13.0,
          ),
          
          // Menu Button (Top Left)
          Positioned(
            top: 50,
            left: 24,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ).animate().fadeIn().slideX(),

          // Booking Sheet
          const BookingSheet(),

          // Active Ride Banner with Real-time Status Updates
          if (_activeRide != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _buildStatusBanner(_activeRide!),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(RideModel ride) {
    final statusInfo = _getStatusInfo(ride.status);
    final Color statusColor = statusInfo['color'];
    final bool isDarkText = statusColor == AppTheme.primaryColor || 
                            statusColor == Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkText ? Colors.black12 : Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusInfo['icon'],
                  color: isDarkText ? Colors.black : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusInfo['title'],
                      style: TextStyle(
                        color: isDarkText ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusInfo['subtitle'],
                      style: TextStyle(
                        color: isDarkText ? Colors.black87 : Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Cancel button
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDarkText ? Colors.black54 : Colors.white54,
                ),
                tooltip: 'Cancel ride',
                onPressed: () async {
                  try {
                    final userId = ref.read(authServiceProvider).currentUser?.uid;
                    if (userId != null) {
                      await ref.read(rideServiceProvider).cancelAllActiveRidesForUser(userId);
                    }
                    _rideSubscription?.cancel();
                    setState(() => _activeRide = null);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ride cancelled')),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error cancelling ride: $e');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Track button - full width
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go(
                  '/tracking', 
                  extra: {
                    'rideId': ride.id, 
                    'destinationName': ride.dropoffAddress,
                  },
                );
              },
              icon: const Icon(Icons.map, size: 18),
              label: const Text('TRACK RIDE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkText ? Colors.black : Colors.white,
                foregroundColor: isDarkText ? Colors.white : statusColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0);
  }
}
