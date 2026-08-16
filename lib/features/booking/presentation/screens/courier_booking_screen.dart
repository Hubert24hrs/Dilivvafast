import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/widgets/delivery_map_widget.dart';
import 'package:dilivvafast/core/services/fare_calculator_service.dart';
import 'package:dilivvafast/core/services/location_helper.dart';
import 'package:dilivvafast/features/booking/presentation/controllers/courier_booking_controller.dart';
import 'package:dilivvafast/features/booking/presentation/widgets/address_search_field.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

/// Map-based courier booking screen with a draggable bottom sheet.
///
/// Shows a map preview on top and a bottom sheet containing:
/// vehicle type selector, pickup/dropoff, package details,
/// proposed price, and "Find a courier" button.
class CourierBookingScreen extends ConsumerStatefulWidget {
  const CourierBookingScreen({super.key});

  @override
  ConsumerState<CourierBookingScreen> createState() =>
      _CourierBookingScreenState();
}

class _CourierBookingScreenState extends ConsumerState<CourierBookingScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize location on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courierBookingControllerProvider.notifier).initializeLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courierBookingControllerProvider);
    final controller = ref.read(courierBookingControllerProvider.notifier);

    // Listen for order creation and navigate to matching screen
    ref.listen<CourierBookingState>(courierBookingControllerProvider, (
      prev,
      next,
    ) {
      if (next.createdOrderId != null && prev?.createdOrderId == null) {
        context.push('/matching/${next.createdOrderId}');
      }
      if (next.error != null && prev?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        controller.clearError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Stack(
        children: [
          // Map area (top portion)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              children: [
                DeliveryMapWidget(
                  height: MediaQuery.of(context).size.height * 0.45,
                  pickupLat: state.hasPickup ? state.pickupLat : null,
                  pickupLng: state.hasPickup ? state.pickupLng : null,
                  dropoffLat: state.hasDropoff ? state.dropoffLat : null,
                  dropoffLng: state.hasDropoff ? state.dropoffLng : null,
                  pickupLabel: 'Pickup',
                  dropoffLabel: 'Dropoff',
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  child: _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => context.pop(),
                  ),
                ),
              ],
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.58,
            minChildSize: 0.40,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF141629),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title
                    const Text(
                      'Courier delivery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle type selector
                    _VehicleTypeSelector(
                      selected: state.vehicleType,
                      onChanged: controller.setVehicleType,
                    ),
                    const SizedBox(height: 16),

                    // Pickup location row
                    _PickupLocationRow(
                      displayText: state.pickupDisplayText,
                      isLoading: state.isLoadingLocation,
                      hasLocation: state.hasPickup,
                      onTap: () => _showPickupSearch(context, controller),
                      onRetryLocation: () => controller.initializeLocation(),
                      locationStatus: state.locationStatus,
                    ),
                    const SizedBox(height: 12),

                    // Destination field
                    AddressSearchField(
                      label: 'To',
                      icon: Icons.search,
                      initialAddress: state.dropoffAddress.isNotEmpty
                          ? state.dropoffAddress
                          : null,
                      onAddressSelected: controller.setDropoff,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Add stops',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.add,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Package details (expandable)
                    _PackageDetailsSection(
                      isExpanded: state.packageDetailsExpanded,
                      hasDetails: state.hasPackageDetails,
                      packageDescription: state.packageDescription,
                      onToggle: controller.togglePackageDetails,
                      onDescriptionChanged: controller.setPackageDescription,
                      onCategoryChanged: controller.setPackageCategory,
                      onWeightChanged: controller.setPackageWeight,
                      onRecipientNameChanged: controller.setRecipientName,
                      onRecipientPhoneChanged: controller.setRecipientPhone,
                      selectedCategory: state.packageCategory,
                    ),
                    const SizedBox(height: 12),

                    // Propose your price
                    _ProposePriceRow(
                      currentPrice: state.proposedPrice,
                      fareBreakdown: state.fareBreakdown,
                      onPriceChanged: controller.setProposedPrice,
                    ),
                    const SizedBox(height: 20),

                    // Find a courier button
                    _FindCourierButton(
                      canSubmit: state.canFindCourier,
                      isSubmitting: state.isSubmitting,
                      onPressed: () async {
                        final orderId = await controller.submitOrder();
                        if (orderId != null && context.mounted) {
                          context.push('/matching/$orderId');
                        }
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPickupSearch(
    BuildContext context,
    CourierBookingController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141629),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set pickup location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AddressSearchField(
              label: 'Enter pickup address',
              icon: Icons.location_on,
              onAddressSelected: (addr, lat, lng) {
                controller.setPickup(addr, lat, lng);
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                controller.initializeLocation();
              },
              icon: const Icon(Icons.gps_fixed, size: 18),
              label: const Text('Use current location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B00),
                side: const BorderSide(color: Color(0xFFFF6B00)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================== SUB-WIDGETS ========================

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _VehicleTypeSelector extends StatelessWidget {
  const _VehicleTypeSelector({required this.selected, required this.onChanged});
  final VehicleType selected;
  final ValueChanged<VehicleType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _VehicleChip(
          icon: Icons.directions_car,
          label: 'Car',
          isSelected: selected == VehicleType.car,
          onTap: () => onChanged(VehicleType.car),
        ),
        const SizedBox(width: 10),
        _VehicleChip(
          icon: Icons.two_wheeler,
          label: 'Motorcycle',
          isSelected: selected == VehicleType.motorcycle,
          onTap: () => onChanged(VehicleType.motorcycle),
        ),
      ],
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D1E33) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B00) : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF6B00) : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF6B00) : Colors.white54,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupLocationRow extends StatelessWidget {
  const _PickupLocationRow({
    required this.displayText,
    required this.isLoading,
    required this.hasLocation,
    required this.onTap,
    required this.onRetryLocation,
    required this.locationStatus,
  });
  final String displayText;
  final bool isLoading;
  final bool hasLocation;
  final VoidCallback onTap;
  final VoidCallback onRetryLocation;
  final LocationStatus locationStatus;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasLocation
                ? const Color(0xFFFF6B00).withValues(alpha: 0.3)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.radio_button_checked,
              color: hasLocation ? const Color(0xFF4CAF50) : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isLoading
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF6B00),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      displayText,
                      style: TextStyle(
                        color: hasLocation ? Colors.white : Colors.white54,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (!hasLocation && !isLoading)
              GestureDetector(
                onTap: () {
                  if (locationStatus == LocationStatus.servicesDisabled) {
                    LocationHelper.showLocationServicesDialog(context);
                  } else if (locationStatus ==
                      LocationStatus.permissionDeniedForever) {
                    LocationHelper.showPermissionDeniedDialog(context);
                  } else {
                    onRetryLocation();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Enable',
                    style: TextStyle(
                      color: Color(0xFFFF6B00),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackageDetailsSection extends StatelessWidget {
  const _PackageDetailsSection({
    required this.isExpanded,
    required this.hasDetails,
    required this.packageDescription,
    required this.onToggle,
    required this.onDescriptionChanged,
    required this.onCategoryChanged,
    required this.onWeightChanged,
    required this.onRecipientNameChanged,
    required this.onRecipientPhoneChanged,
    required this.selectedCategory,
  });
  final bool isExpanded;
  final bool hasDetails;
  final String packageDescription;
  final VoidCallback onToggle;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<PackageCategory> onCategoryChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<String> onRecipientNameChanged;
  final ValueChanged<String> onRecipientPhoneChanged;
  final PackageCategory selectedCategory;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Colors.white54, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Package details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hasDetails)
                        Text(
                          'Details added',
                          style: TextStyle(
                            color: const Color(0xFF4CAF50),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                  color: Colors.white38,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {}, // prevent parent toggle
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      hint: 'What are you sending?',
                      icon: Icons.inventory_2,
                      onChanged: onDescriptionChanged,
                    ),
                    const SizedBox(height: 10),
                    // Category chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: PackageCategory.values.map((cat) {
                        final isSelected = cat == selectedCategory;
                        return GestureDetector(
                          onTap: () => onCategoryChanged(cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(
                                      0xFFFF6B00,
                                    ).withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF6B00)
                                    : Colors.white12,
                              ),
                            ),
                            child: Text(
                              cat.name[0].toUpperCase() + cat.name.substring(1),
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFF6B00)
                                    : Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      hint: 'Weight (kg)',
                      icon: Icons.fitness_center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,1}'),
                        ),
                      ],
                      onChanged: (val) {
                        final w = double.tryParse(val) ?? 0.0;
                        onWeightChanged(w);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      hint: 'Recipient name',
                      icon: Icons.person_outline,
                      onChanged: onRecipientNameChanged,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      hint: 'Recipient phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      onChanged: onRecipientPhoneChanged,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFFF6B00), size: 18),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        textCapitalization: textCapitalization,
      ),
    );
  }
}

class _ProposePriceRow extends StatelessWidget {
  const _ProposePriceRow({
    required this.currentPrice,
    required this.fareBreakdown,
    required this.onPriceChanged,
  });
  final double currentPrice;
  final FareBreakdown? fareBreakdown;
  final ValueChanged<double> onPriceChanged;

  @override
  Widget build(BuildContext context) {
    final displayPrice = currentPrice > 0
        ? '₦${currentPrice.toStringAsFixed(0)}'
        : (fareBreakdown != null
              ? '₦${fareBreakdown!.totalFare.toStringAsFixed(0)}'
              : '');

    return GestureDetector(
      onTap: () => _showPriceDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calculate_outlined,
              color: Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Propose your price',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (displayPrice.isNotEmpty)
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        color: Color(0xFFFF6B00),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  void _showPriceDialog(BuildContext context) {
    final textController = TextEditingController(
      text: currentPrice > 0 ? currentPrice.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Propose your price',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fareBreakdown != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Suggested: ₦${fareBreakdown!.totalFare.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixText: '₦ ',
                prefixStyle: const TextStyle(
                  color: Color(0xFFFF6B00),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                hintText: '0',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFF6B00)),
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(textController.text) ?? 0.0;
              onPriceChanged(val);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Set Price',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _FindCourierButton extends StatelessWidget {
  const _FindCourierButton({
    required this.canSubmit,
    required this.isSubmitting,
    required this.onPressed,
  });
  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canSubmit && !isSubmitting ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit
              ? const Color(0xFF00E676)
              : const Color(0xFF1D1E33),
          foregroundColor: canSubmit ? const Color(0xFF0A0E21) : Colors.white38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canSubmit ? 4 : 0,
        ),
        child: isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF0A0E21),
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Find a courier',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
