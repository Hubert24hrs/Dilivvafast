import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/platform_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverNavigationScreen extends ConsumerStatefulWidget {
  final RideModel? ride;
  final CourierModel? courier;

  const DriverNavigationScreen({
    super.key,
    this.ride,
    this.courier,
  });

  @override
  ConsumerState<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends ConsumerState<DriverNavigationScreen> {
  PlatformMapboxMap? _mapboxMap;
  String _currentStatus = 'accepted'; 
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _firestoreUpdateTimer;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    if (widget.ride?.status != null) {
      _currentStatus = widget.ride!.status;
      // Map 'pending' (if passed by mistake) to 'accepted' for this screen
      if (_currentStatus == 'pending') _currentStatus = 'accepted';
    }
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _firestoreUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    if (kIsWeb) return; // Skip on web
    
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _lastPosition = position;
        _updateMapLocation(position);
      },
    );

    // Update Firestore every 10 seconds to avoid spamming writes
    _firestoreUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_lastPosition != null && widget.ride != null) {
        _updateDriverLocationInFirestore(_lastPosition!);
      }
    });
  }

  Future<void> _updateDriverLocationInFirestore(Position position) async {
    try {
      final location = GeoPoint(position.latitude, position.longitude);
      
      if (widget.ride != null) {
        await ref.read(rideServiceProvider).updateRideStatus(
          widget.ride!.id, 
          _currentStatus,
          driverLocation: location,
        );
      } else if (widget.courier != null) {
        final driverId = ref.read(authServiceProvider).currentUser?.uid ?? 'driver_1';
        await ref.read(databaseServiceProvider).updateCourierStatus(
          widget.courier!.id, 
          _currentStatus, 
          driverId,
          driverLocation: location,
        );
      }
    } catch (e) {
      debugPrint('Error updating driver location: $e');
    }
  }

  void _updateMapLocation(Position position) {
    // Ideally update a puck or marker on the map
    // For now, we can just center the camera if in navigation mode
    // But let's not force camera updates too aggressively to allow user panning
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // If no ride/courier, show error
    if (widget.ride == null && widget.courier == null) {
      return const Scaffold(body: Center(child: Text('Error: No ride data')));
    }

    // If courier, we might not have a stream yet (mock), so keep existing logic or wrap similarly
    // For now, focusing on RIDE flow as per user request.
    if (widget.courier != null) {
      return _buildCourierView();
    }

    final rideStream = ref.watch(rideServiceProvider).streamRide(widget.ride!.id);

    return Scaffold(
      body: StreamBuilder<RideModel?>(
        stream: rideStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final ride = snapshot.data;
          if (ride == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final status = ride.status;
          
          // Update local status for logic if needed, but better to use 'ride.status' directly
          _currentStatus = status;

          return Stack(
            children: [
              PlatformMapWidget(
                onMapCreated: _onMapCreated,
                initialLat: ride.pickupLocation.latitude,
                initialLng: ride.pickupLocation.longitude,
                initialZoom: 13.0,
              ),
              
              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => context.pop(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getStatusText(status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Ride Request',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final phone = ride.userPhone;
                                    if (phone == null || phone.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No phone number available')),
                                      );
                                      return;
                                    }
                                    final Uri launchUri = Uri(
                                      scheme: 'tel',
                                      path: phone, 
                                    );
                                    if (await canLaunchUrl(launchUri)) {
                                      await launchUrl(launchUri);
                                    }
                                  },
                                  icon: const Icon(Icons.phone, size: 18),
                                  label: const Text('CALL'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    context.push('/chat', extra: {
                                      'rideId': ride.id,
                                      'otherUserName': 'Passenger',
                                    });
                                  },
                                  icon: const Icon(Icons.chat, size: 18),
                                  label: const Text('CHAT'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final lat = ride.dropoffLocation.latitude;
                                    final lng = ride.dropoffLocation.longitude;
                                    final uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
                                    debugPrint('Attempting to launch: $uri');
                                    
                                    if (await canLaunchUrl(uri)) {
                                      debugPrint('Launching native navigation...');
                                      await launchUrl(uri);
                                    } else {
                                      debugPrint('Native navigation failed. Trying fallback...');
                                      // Fallback for iOS or if scheme not found
                                      final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                                      debugPrint('Attempting fallback: $webUri');
                                      
                                      if (await canLaunchUrl(webUri)) {
                                        debugPrint('Launching fallback...');
                                        await launchUrl(webUri, mode: LaunchMode.externalApplication);
                                      } else {
                                        debugPrint('Could not launch fallback either.');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not open Maps')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.navigation, size: 18),
                                  label: const Text('NAV'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    side: const BorderSide(color: Colors.blueAccent),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _advanceState(ride),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                disabledBackgroundColor: Colors.grey,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : Text(
                                    _getNextButtonText(status),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Info Sheet (Steps)
              Positioned(
                bottom: 30,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStepRow(Icons.my_location, 'Pickup', status == 'accepted'),
                        if (ride.stopLocations.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (int i = 0; i < ride.stopLocations.length; i++)
                            _buildStepRow(Icons.stop_circle_outlined, 'Stop ${i + 1}', false),
                        ],
                        const SizedBox(height: 8),
                        _buildStepRow(Icons.flag, 'Dropoff', status == 'in_progress'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

    // Keep existing courier view logic separate or refactor later
  Widget _buildCourierView() {
    // Use streamCourier to get real-time updates for this specific courier
    final courierStream = ref.watch(databaseServiceProvider).streamCourier(widget.courier!.id);

    return Scaffold(
      body: StreamBuilder<CourierModel?>(
        stream: courierStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final courier = snapshot.data ?? widget.courier!;
          final status = courier.status;
          _currentStatus = status;
          
          debugPrint('CourierNavigation: status=$status');

          return Stack(
            children: [
              PlatformMapWidget(
                onMapCreated: _onMapCreated,
                initialLat: courier.pickupLocation.latitude,
                initialLng: courier.pickupLocation.longitude,
                initialZoom: 13.0,
              ),
              
              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => context.pop(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getCourierStatusText(status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Courier: ${courier.packageSize}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final Uri launchUri = Uri(
                                      scheme: 'tel',
                                      path: courier.receiverPhone, 
                                    );
                                    if (await canLaunchUrl(launchUri)) {
                                      await launchUrl(launchUri);
                                    }
                                  },
                                  icon: const Icon(Icons.phone, size: 16),
                                  label: const Text('CALL'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Chat with customer
                                    context.push('/chat', extra: {
                                      'rideId': courier.id,
                                      'otherUserName': courier.receiverName,
                                    });
                                  },
                                  icon: const Icon(Icons.chat, size: 16),
                                  label: const Text('CHAT'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: BorderSide(color: AppTheme.primaryColor),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final lat = courier.dropoffLocation.latitude;
                                    final lng = courier.dropoffLocation.longitude;
                                    final uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    } else {
                                      final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                                      if (await canLaunchUrl(webUri)) {
                                        await launchUrl(webUri, mode: LaunchMode.externalApplication);
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.navigation, size: 16),
                                  label: const Text('NAV'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    side: const BorderSide(color: Colors.blueAccent),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _advanceCourierState(courier),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                disabledBackgroundColor: Colors.grey,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : Text(
                                    _getNextCourierButtonText(status),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Info Sheet
              Positioned(
                bottom: 30,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStepRow(Icons.my_location, 'Pickup: ${courier.pickupAddress}', status == 'accepted'),
                        const SizedBox(height: 8),
                        _buildStepRow(Icons.flag, 'Dropoff: ${courier.dropoffAddress}', status == 'picked_up'),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white54, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Receiver: ${courier.receiverName} (${courier.receiverPhone})',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getCourierStatusText(String status) {
    if (status == 'accepted') return 'Heading to Pickup';
    if (status == 'arrived') return 'Arrived at Pickup';
    if (status == 'in_transit') return 'Heading to Dropoff';
    if (status == 'delivered') return 'Package Delivered';
    return 'Completed';
  }

  String _getNextCourierButtonText(String status) {
    if (status == 'accepted') return 'I ARRIVED';
    if (status == 'arrived') return 'START TRIP';
    if (status == 'in_transit') return 'CONFIRM DELIVERY';
    return 'COMPLETE';
  }

  Future<void> _advanceCourierState(CourierModel courier) async {
    setState(() => _isLoading = true);
    
    try {
      String nextStatus = '';
      // New status flow: accepted → arrived → in_transit → delivered
      if (courier.status == 'accepted') {
        nextStatus = 'arrived';
      } else if (courier.status == 'arrived') {
        nextStatus = 'in_transit';
      } else if (courier.status == 'in_transit') {
        nextStatus = 'delivered';
      }

      debugPrint('DriverNavigation: Courier Transitioning to nextStatus=$nextStatus');

      if (nextStatus.isNotEmpty) {
        final driverId = ref.read(authServiceProvider).currentUser?.uid ?? 'driver_1';
        await ref.read(databaseServiceProvider).updateCourierStatus(courier.id, nextStatus, driverId);
        
        // Trigger notification for the customer
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.notifyCourierStatusUpdate(
          courierId: courier.id,
          status: nextStatus,
          deliveryInfo: courier.receiverName,
        );
        
        if (nextStatus == 'delivered') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery Confirmed!')));
            context.pop();
          }
        }
      }
    } catch (e) {
      debugPrint('DriverNavigation: Error updating courier status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getStatusText(String status) {
    if (status == 'accepted') return 'Heading to Pickup';
    if (status == 'arrived') return 'Waiting for Passenger';
    if (status == 'in_progress') return 'Heading to Dropoff';
    return 'Trip Completed';
  }

  String _getNextButtonText(String status) {
    if (status == 'accepted') return 'ARRIVED AT PICKUP';
    if (status == 'arrived') return 'START TRIP';
    if (status == 'in_progress') return 'COMPLETE TRIP';
    return 'COMPLETE';
  }

  Future<void> _advanceState(RideModel ride) async {
    setState(() => _isLoading = true);
    
    try {
      String nextStatus = '';
      if (ride.status == 'accepted') {
        nextStatus = 'arrived';
      } else if (ride.status == 'arrived') {
        nextStatus = 'in_progress';
      } else if (ride.status == 'in_progress') {
        nextStatus = 'completed';
      }

      debugPrint('DriverNavigation: Transitioning to nextStatus=$nextStatus');

      if (nextStatus.isNotEmpty) {
        await ref.read(rideServiceProvider).updateRideStatus(ride.id, nextStatus);
        
        // Trigger notification for the passenger
        final notificationService = ref.read(notificationServiceProvider);
        final driverName = ref.read(authServiceProvider).currentUser?.displayName ?? 'Your driver';
        await notificationService.notifyRideStatusUpdate(
          rideId: ride.id,
          status: nextStatus,
          driverName: driverName,
        );
        
        if (nextStatus == 'completed') {
          if (mounted) context.pop();
        }
      }
    } catch (e) {
      debugPrint('DriverNavigation: Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(dynamic mapboxMap) {
    if (kIsWeb) return; // Skip on web
    _mapboxMap = mapboxMap as PlatformMapboxMap?;
    _renderRoute();
  }

  Future<void> _renderRoute() async {
    // Skip route rendering on web and if map not available  
    if (kIsWeb || _mapboxMap == null) return;

    // Note: Route rendering is only supported on mobile with full Mapbox
    // Web version shows placeholder map only
    // The actual route drawing code would need mapbox types which aren't available on web
  }

  Widget _buildStepRow(IconData icon, String text, bool isActive) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isActive ? AppTheme.primaryColor : Colors.white54),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
