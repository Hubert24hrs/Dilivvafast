import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';

import 'package:fast_delivery/presentation/screens/courier/package_details_sheet.dart';
import 'package:fast_delivery/presentation/screens/courier/propose_price_sheet.dart';
import 'package:fast_delivery/presentation/screens/courier/route_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourierScreen extends ConsumerStatefulWidget {
  const CourierScreen({super.key});

  @override
  ConsumerState<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends ConsumerState<CourierScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  String _selectedSize = 'Motorcycle';
  bool _isLoading = false;

  // Courier Request Data
  Map<String, dynamic>? _packageDetails;
  double _price = 0.0;
  double _recommendedPrice = 1500.0; // Default recommended price
  String _dropoffAddress = '';
  // Payment details are captured in _openProposePrice and passed to request

  
  // Multi-stop support
  final List<String> _additionalStops = [];
  
  // Current pickup address
  String _currentAddress = 'Fetching location...';  
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _calculateRecommendedPrice();
  }

  void _calculateRecommendedPrice() {
    // Calculate recommended price based on vehicle type
    // This is a simplified calculation - in production, use distance-based pricing
    setState(() {
      if (_selectedSize == 'Car') {
        _recommendedPrice = 2500.0;
      } else {
        _recommendedPrice = 1500.0; // Motorcycle
      }
    });
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final position = await ref.read(locationServiceProvider).determinePosition();
      final address = await ref.read(locationServiceProvider).getAddressFromCoordinates(
        position.latitude, 
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _currentAddress = address ?? 'Current Location';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Location unavailable';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _requestCourier() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to request a courier')),
      );
      return;
    }

    if (_dropoffAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }

    if (_price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please propose a price')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Get Current Location (Mocking Pickup for now if empty)
      final position = await ref.read(locationServiceProvider).determinePosition();
      if (!mounted) return;

      // 2. Process Payment (Only if not Cash and not Receiver Pays)
      // For now, we'll skip actual payment integration for 'Cash' or 'Receiver Pays'
      // If 'Transfer' or Card, we would trigger payment here.
      
      // 3. Create Courier Request
      final courier = CourierModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        pickupLocation: GeoPoint(position.latitude, position.longitude),
        dropoffLocation: const GeoPoint(6.5244, 3.3792), // Mock Dropoff Coords for now
        pickupAddress: _pickupController.text.isEmpty ? 'Current Location' : _pickupController.text,
        dropoffAddress: _dropoffAddress,
        packageSize: _packageDetails?['description'] ?? _selectedSize, // Use description or vehicle type
        receiverName: 'Receiver', // Could be added to PackageDetails
        receiverPhone: _packageDetails?['recipientPhone'] ?? '',
        price: _price,
        recommendedPrice: _recommendedPrice,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      await ref.read(databaseServiceProvider).createCourierRequest(courier);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Courier Requested Successfully!')),
        );
        // Navigate to courier tracking screen with courier ID
        context.go('/courier-tracking?courierId=${courier.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _openRouteEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteEntrySheet(
        onSave: (address) {
          setState(() {
            _dropoffAddress = address;
            _dropoffController.text = address;
          });
        },
      ),
    );
  }

  void _openPackageDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PackageDetailsSheet(
        onSave: (data) {
          setState(() => _packageDetails = data);
        },
      ),
    );
  }

  void _openProposePrice() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProposePriceSheet(
        recommendedPrice: _recommendedPrice,
        onSave: (data) {
          setState(() {
            _price = data['price'];
            // Payment method and receiver pays info used only in the sheet display
          });
        },
      ),
    );
  }

  void _showAddStopsDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Add Stop', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter stop address',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_additionalStops.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Current Stops:', style: TextStyle(color: Colors.white70)),
              ..._additionalStops.asMap().entries.map((e) => ListTile(
                dense: true,
                title: Text('${e.key + 1}. ${e.value}', style: const TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  onPressed: () {
                    setState(() => _additionalStops.removeAt(e.key));
                    Navigator.pop(context);
                    _showAddStopsDialog();
                  },
                ),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty && _additionalStops.length < 3) {
                setState(() => _additionalStops.add(controller.text.trim()));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stop added: ${controller.text}')),
                );
              } else if (_additionalStops.length >= 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Maximum 3 stops allowed')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Add Stop'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Global Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          
          // Background Orbs
          const BackgroundOrbs(),
          
          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: AppTheme.surfaceColor,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
            ),
          ),

          // Main Content Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: GlassCard(
              opacity: 0.95,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Courier delivery',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Vehicle Selection
                    Row(
                      children: [
                        _buildVehicleOption('Car', Icons.directions_car),
                        const SizedBox(width: 12),
                        _buildVehicleOption('Motorcycle', Icons.two_wheeler),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Current Location Display
                    Row(
                      children: [
                        const Icon(Icons.my_location, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isLoadingLocation
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : Text(
                                  _currentAddress,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // To Input with Add Stops
                    GestureDetector(
                      onTap: _openRouteEntry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.white54),
                            const SizedBox(width: 12),
                            Text(
                              _dropoffAddress.isEmpty ? 'To' : _dropoffAddress,
                              style: TextStyle(
                                color: _dropoffAddress.isEmpty ? Colors.white54 : Colors.white,
                                fontSize: 16,
                                fontWeight: _dropoffAddress.isEmpty ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showAddStopsDialog,
                              child: Row(
                                children: [
                                  Text(
                                    _additionalStops.isEmpty ? 'Add stops' : '${_additionalStops.length} stop(s)',
                                    style: TextStyle(
                                      color: _additionalStops.isEmpty ? Colors.white54 : AppTheme.primaryColor,
                                      fontSize: 14,
                                      fontWeight: _additionalStops.isEmpty ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _additionalStops.isEmpty ? Icons.add : Icons.edit,
                                    color: _additionalStops.isEmpty ? Colors.white54 : AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Order Details
                    _buildListTile(
                      'Package details', 
                      Icons.tune, 
                      onTap: _openPackageDetails,
                      subtitle: _packageDetails != null ? 'Details added' : null,
                    ),
                    const SizedBox(height: 8),
                    
                    // Offer your fare
                    _buildListTile(
                      'Propose your price', 
                      Icons.money,
                      onTap: _openProposePrice,
                      subtitle: _price > 0 ? '₦${_price.toStringAsFixed(0)}' : null,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestCourier,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor, // Neon Green
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.black) 
                          : const Text(
                              'Find a courier',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleOption(String label, IconData icon) {
    final isSelected = _selectedSize == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSize = label);
        _calculateRecommendedPrice();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 18,
              color: isSelected ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, {VoidCallback? onTap, String? subtitle}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
