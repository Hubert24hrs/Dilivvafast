import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BookingSheet extends ConsumerStatefulWidget {
  const BookingSheet({super.key});

  @override
  ConsumerState<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<BookingSheet> {
  bool _isLoading = false;
  final TextEditingController _destinationController = TextEditingController();
  String _paymentMethod = 'wallet'; // 'wallet' or 'card'
  final double _ridePrice = 2500.0;

  Future<void> _bookRide() async {
    debugPrint('BookingSheet: _bookRide START');
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(authServiceProvider).currentUser?.uid;
      debugPrint('BookingSheet: userId=$userId');
      if (userId == null) throw Exception('Please login to book a ride');
      
      final user = await ref.read(databaseServiceProvider).getUser(userId);
      debugPrint('BookingSheet: user=${user?.email}');
      if (user == null) throw Exception('User not found');

      // Handle payment based on selected method
      bool paymentSuccess = false;
      debugPrint('BookingSheet: paymentMethod=$_paymentMethod');
      
      if (_paymentMethod == 'wallet') {
        // Check wallet balance
        debugPrint('BookingSheet: walletBalance=${user.walletBalance}, ridePrice=$_ridePrice');
        if (user.walletBalance < _ridePrice) {
          debugPrint('BookingSheet: INSUFFICIENT BALANCE');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Insufficient balance. Your balance: ₦${user.walletBalance.toStringAsFixed(0)}'),
                action: SnackBarAction(
                  label: 'Add Funds',
                  onPressed: () => context.push('/add-card'),
                ),
              ),
            );
          }
          return;
        }
        paymentSuccess = true;
        debugPrint('BookingSheet: paymentSuccess=true (wallet)');
      } else {
        // Card payment via Paystack
        if (!mounted) return;
        final paystackService = ref.read(paystackServiceProvider);
        paymentSuccess = await paystackService.chargeCard(
          context: context,
          amount: _ridePrice,
          email: user.email,
          onSuccess: (ref) => debugPrint('Ride payment completed: $ref'),
          onCancel: (ref) => debugPrint('Ride payment cancelled: $ref'),
        );
        debugPrint('BookingSheet: paymentSuccess=$paymentSuccess (card)');
      }

      if (!paymentSuccess) {
        debugPrint('BookingSheet: PAYMENT FAILED - returning');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Deduct from wallet if wallet payment
      if (_paymentMethod == 'wallet') {
        debugPrint('BookingSheet: Deducting from wallet...');
        await ref.read(databaseServiceProvider).addWalletTransaction(
          userId: userId,
          amount: -_ridePrice,
          type: 'ride_payment',
          description: 'Ride to ${_destinationController.text.isEmpty ? 'Victoria Island' : _destinationController.text}',
        );
        debugPrint('BookingSheet: Wallet deduction complete!');
      }

      // Mock coordinates (lat, lng)
      debugPrint('BookingSheet: Creating mock coordinates...');
      const mockDestLat = 6.4281;
      const mockDestLng = 3.4241;
      const mockPickupLat = 6.5244;
      const mockPickupLng = 3.3792;

      debugPrint('BookingSheet: Creating RideModel...');
      final ride = RideModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        pickupLocation: GeoPoint(mockPickupLat, mockPickupLng),
        dropoffLocation: GeoPoint(mockDestLat, mockDestLng),
        pickupAddress: 'Current Location',
        dropoffAddress: _destinationController.text.isEmpty ? 'Victoria Island' : _destinationController.text,
        price: _ridePrice,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      debugPrint('BookingSheet: Calling createRide with id=${ride.id}...');
      await ref.read(rideServiceProvider).createRide(ride);
      debugPrint('BookingSheet: createRide completed!');

      if (mounted) {
        debugPrint('BookingSheet: Navigating to tracking with rideId=${ride.id}');
        // Use query params for web URL persistence, extra for full data
        context.go(
          '/tracking?rideId=${ride.id}&dest=${Uri.encodeComponent(ride.dropoffAddress)}', 
          extra: {
            'destinationName': ride.dropoffAddress,
            'rideId': ride.id,
          },
        );
      }
    } catch (e) {
      debugPrint('BookingSheet: ERROR - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return GlassCard(
          opacity: 0.95,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Service Selector (Centered and Spaced)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildServiceTab('Ride', true),
                        const SizedBox(width: 24), // Increased spacing
                        _buildServiceTab('Couriers', false, onTap: () => context.go('/courier')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Destination Input (Read Only - Navigates to Search)
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final result = await context.push('/destination-search');
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            _destinationController.text = result['name'] ?? '';
                            // We could also store the location coordinates here if returned
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppTheme.primaryColor),
                            const SizedBox(width: 16),
                            Text(
                              _destinationController.text.isEmpty 
                                ? 'Where to?' 
                                : _destinationController.text,
                              style: TextStyle(
                                color: _destinationController.text.isEmpty 
                                  ? Colors.white.withValues(alpha: 0.7) 
                                  : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.schedule, size: 14, color: Colors.white70),
                                  SizedBox(width: 4),
                                  Text(
                                    'Later',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Recent Places (Optional - for quick access)
                    const SizedBox(height: 24),
                    _buildRecentItem('First Bank Lekki', '3 Chris Efunyemi Onanuga Street'),
                    _buildRecentItem('15 Nike Art Gallery Road', 'Lagos, Nigeria'),
                    
                    const SizedBox(height: 24),
                    
                    // Price Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Fare', style: TextStyle(color: Colors.white70)),
                          Text(
                            '₦${_ridePrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Payment Method Selector
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _paymentMethod = 'wallet'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'wallet' 
                                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                  : Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _paymentMethod == 'wallet' 
                                    ? AppTheme.primaryColor 
                                    : Colors.white12,
                                  width: _paymentMethod == 'wallet' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    color: _paymentMethod == 'wallet' 
                                      ? AppTheme.primaryColor 
                                      : Colors.white70,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Wallet',
                                    style: TextStyle(
                                      color: _paymentMethod == 'wallet' 
                                        ? AppTheme.primaryColor 
                                        : Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _paymentMethod = 'card'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'card' 
                                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                  : Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _paymentMethod == 'card' 
                                    ? AppTheme.primaryColor 
                                    : Colors.white12,
                                  width: _paymentMethod == 'card' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.credit_card,
                                    color: _paymentMethod == 'card' 
                                      ? AppTheme.primaryColor 
                                      : Colors.white70,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Card',
                                    style: TextStyle(
                                      color: _paymentMethod == 'card' 
                                        ? AppTheme.primaryColor 
                                        : Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Book Ride Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _bookRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_paymentMethod == 'wallet' ? Icons.account_balance_wallet : Icons.credit_card, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'PAY ₦${_ridePrice.toStringAsFixed(0)} & BOOK',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentItem(String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white10,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.access_time, color: Colors.white70, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      onTap: () => context.push('/destination-search'),
    );
  }

  Widget _buildServiceTab(String label, bool isSelected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
    );
  }
}
