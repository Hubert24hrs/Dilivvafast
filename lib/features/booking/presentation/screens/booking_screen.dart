import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fast_delivery/features/booking/presentation/controllers/booking_controller.dart';
import 'package:fast_delivery/features/booking/presentation/widgets/address_search_field.dart';
import 'package:fast_delivery/features/booking/presentation/widgets/fare_breakdown_card.dart';
import 'package:fast_delivery/features/booking/presentation/widgets/package_form.dart';
import 'package:fast_delivery/features/courier/domain/entities/courier_order_model.dart';

class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key});

  static const _stepTitles = [
    'Pickup Location',
    'Dropoff Location',
    'Package Details',
    'Review & Pay',
  ];



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);

    // Navigate to tracking when order is created
    ref.listen<BookingState>(bookingControllerProvider, (prev, next) {
      if (next.createdOrderId != null && prev?.createdOrderId == null) {
        _showSuccessDialog(context, next.createdOrderId!, next.fareBreakdown?.totalFare ?? 0);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (state.step > 0) {
              controller.previousStep();
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _stepTitles[state.step],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Step indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${state.step + 1}/4',
              style: const TextStyle(
                color: Color(0xFF00F0FF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          _buildProgressBar(state.step),

          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStepContent(state, controller),
            ),
          ),

          // Error banner
          if (state.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom button
          _buildBottomButton(state, controller),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= step;
          final isCurrent = i == step;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive
                    ? const Color(0xFF00F0FF)
                    : const Color(0xFF1D1E33),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                          blurRadius: 6,
                        )
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(BookingState state, BookingController controller) {
    return switch (state.step) {
      0 => _PickupStep(key: const ValueKey('pickup'), state: state, controller: controller),
      1 => _DropoffStep(key: const ValueKey('dropoff'), state: state, controller: controller),
      2 => _PackageStep(key: const ValueKey('package'), state: state, controller: controller),
      3 => _ReviewStep(key: const ValueKey('review'), state: state, controller: controller),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildBottomButton(BookingState state, BookingController controller) {
    final canProceed = switch (state.step) {
      0 => state.canProceedFromPickup,
      1 => state.canProceedFromDropoff,
      2 => state.canProceedFromPackage,
      3 => state.fareBreakdown != null && !state.isSubmitting,
      _ => false,
    };

    final isLastStep = state.step == 3;
    final buttonText = isLastStep ? 'Confirm & Book' : 'Continue';
    final buttonIcon = isLastStep ? Icons.check_circle : Icons.arrow_forward;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canProceed
                ? () {
                    if (isLastStep) {
                      controller.submitOrder();
                    } else {
                      controller.nextStep();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed
                  ? const Color(0xFF00F0FF)
                  : const Color(0xFF1D1E33),
              foregroundColor:
                  canProceed ? const Color(0xFF0A0E21) : Colors.white38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: canProceed ? 4 : 0,
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFF0A0E21),
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(buttonIcon, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String orderId, double fare) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00F0FF),
                      const Color(0xFF00F0FF).withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: const Icon(Icons.check, color: Color(0xFF0A0E21), size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your delivery has been placed.\nA rider will be assigned shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₦${fare.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/customer/orders');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: const Color(0xFF0A0E21),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Track Order',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================== STEP WIDGETS ========================

class _PickupStep extends StatelessWidget {
  const _PickupStep({
    super.key,
    required this.state,
    required this.controller,
  });
  final BookingState state;
  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(
            icon: Icons.my_location,
            title: 'Where should we pick up?',
            subtitle: 'Enter the pickup address for your package',
          ),
          const SizedBox(height: 24),
          AddressSearchField(
            label: 'Enter pickup address',
            icon: Icons.location_on,
            initialAddress: state.pickupAddress,
            onAddressSelected: controller.setPickup,
          ),
          const SizedBox(height: 16),
          // Use current location button
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Use geolocator to get current location
              controller.setPickup('Current Location, Lagos', 6.5244, 3.3792);
            },
            icon: const Icon(Icons.gps_fixed, size: 18),
            label: const Text('Use current location'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00F0FF),
              side: const BorderSide(color: Color(0xFF00F0FF), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropoffStep extends StatelessWidget {
  const _DropoffStep({
    super.key,
    required this.state,
    required this.controller,
  });
  final BookingState state;
  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(
            icon: Icons.flag,
            title: 'Where should we deliver?',
            subtitle: 'Enter the dropoff address for your package',
          ),
          const SizedBox(height: 24),

          // Show pickup summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFF00F0FF), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'From: ${state.pickupAddress}',
                    style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          AddressSearchField(
            label: 'Enter dropoff address',
            icon: Icons.flag,
            initialAddress: state.dropoffAddress,
            onAddressSelected: controller.setDropoff,
          ),
        ],
      ),
    );
  }
}

class _PackageStep extends StatelessWidget {
  const _PackageStep({
    super.key,
    required this.state,
    required this.controller,
  });
  final BookingState state;
  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(
            icon: Icons.inventory_2,
            title: 'Package Details',
            subtitle: 'Tell us about your package and the recipient',
          ),
          const SizedBox(height: 24),
          PackageForm(
            selectedCategory: state.packageCategory,
            weight: state.packageWeight,
            onCategoryChanged: controller.setPackageCategory,
            onWeightChanged: controller.setPackageWeight,
            onDescriptionChanged: controller.setPackageDescription,
            onRecipientNameChanged: controller.setRecipientName,
            onRecipientPhoneChanged: controller.setRecipientPhone,
            onNotesChanged: controller.setNotes,
          ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.state,
    required this.controller,
  });
  final BookingState state;
  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(
            icon: Icons.fact_check,
            title: 'Review & Confirm',
            subtitle: 'Double-check your delivery details',
          ),
          const SizedBox(height: 24),

          // Route summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _routeRow(Icons.location_on, 'Pickup', state.pickupAddress,
                    const Color(0xFF00F0FF)),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 2,
                        height: 6,
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
                _routeRow(Icons.flag, 'Dropoff', state.dropoffAddress,
                    const Color(0xFFFF00AA)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Package summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _detailRow('Package', state.packageDescription),
                _detailRow('Category', state.packageCategory.name),
                if (state.packageWeight > 0)
                  _detailRow('Weight', '${state.packageWeight} kg'),
                _detailRow('Recipient', state.recipientName),
                _detailRow('Phone', state.recipientPhone),
                _detailRow(
                    'Distance', '${state.distanceKm.toStringAsFixed(1)} km'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment method
          _buildPaymentSelector(state, controller),
          const SizedBox(height: 16),

          // Promo code
          _buildPromoInput(controller),
          const SizedBox(height: 16),

          // Fare breakdown
          FareBreakdownCard(
            breakdown: state.fareBreakdown,
            isLoading: state.isCalculatingFare,
          ),
        ],
      ),
    );
  }

  Widget _routeRow(IconData icon, String label, String addr, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
              Text(addr,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          Flexible(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelector(
      BookingState state, BookingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Method',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: PaymentMethod.values.map((m) {
              final isSelected = m == state.paymentMethod;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.setPaymentMethod(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00F0FF)
                            : Colors.white12,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _paymentIcon(m),
                          color: isSelected
                              ? const Color(0xFF00F0FF)
                              : Colors.white54,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.name[0].toUpperCase() + m.name.substring(1),
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00F0FF)
                                : Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoInput(BookingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.local_offer,
              color: Color(0xFFFF00AA), size: 20),
          hintText: 'Enter promo code',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: TextButton(
            onPressed: () => controller.calculateFare(),
            child: const Text('Apply',
                style: TextStyle(color: Color(0xFFFF00AA), fontSize: 13)),
          ),
        ),
        onChanged: controller.setPromoCode,
        textCapitalization: TextCapitalization.characters,
      ),
    );
  }

  IconData _paymentIcon(PaymentMethod m) {
    return switch (m) {
      PaymentMethod.wallet => Icons.account_balance_wallet,
      PaymentMethod.card => Icons.credit_card,
      PaymentMethod.cash => Icons.money,
    };
  }
}

// ======================== SHARED WIDGETS ========================

Widget _buildHeroCard({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF00F0FF).withValues(alpha: 0.08),
          const Color(0xFFFF00AA).withValues(alpha: 0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
          ),
          child: Icon(icon, color: const Color(0xFF00F0FF), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      ],
    ),
  );
}
