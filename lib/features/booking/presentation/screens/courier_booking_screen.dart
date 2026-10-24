import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/widgets/live_map.dart';
import 'package:dilivvafast/core/services/location_helper.dart';
import 'package:dilivvafast/features/booking/presentation/controllers/courier_booking_controller.dart';
import 'package:dilivvafast/features/booking/presentation/widgets/address_search_field.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _field = Color(0xFFF3F4F6);
const _lime = Color(0xFFC1F11D);

/// "Where to & for how much?" — booking with inDrive-style price offers.
///
/// The customer sets the route, then names their own fare. The server's
/// recommended fare is shown as guidance, the −/+ steppers move in ₦100
/// steps, and the field refuses to leave the band the backend enforces (see
/// NegotiationBounds). Submitting sends the request out; couriers answer with
/// offers on the next screen.
class CourierBookingScreen extends ConsumerStatefulWidget {
  const CourierBookingScreen({super.key});

  @override
  ConsumerState<CourierBookingScreen> createState() =>
      _CourierBookingScreenState();
}

class _CourierBookingScreenState extends ConsumerState<CourierBookingScreen> {
  final _offerCtrl = TextEditingController();
  final _offerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(courierBookingControllerProvider);
      final controller = ref.read(courierBookingControllerProvider.notifier);
      if (!state.hasPickup && !state.isLoadingLocation) {
        controller.initializeLocation();
      }
      if (state.canFindCourier && state.fareBreakdown == null) {
        controller.calculateFare();
      }
      _syncOfferField();
    });
    _offerFocus.addListener(() {
      if (!_offerFocus.hasFocus) _commitTypedOffer();
    });
  }

  @override
  void dispose() {
    _offerCtrl.dispose();
    _offerFocus.dispose();
    super.dispose();
  }

  void _syncOfferField() {
    if (_offerFocus.hasFocus) return;
    final offer = ref.read(courierBookingControllerProvider).effectiveOffer;
    _offerCtrl.text = offer > 0 ? offer.toStringAsFixed(0) : '';
  }

  void _commitTypedOffer() {
    final typed = double.tryParse(_offerCtrl.text.replaceAll(',', ''));
    final state = ref.read(courierBookingControllerProvider);
    final controller = ref.read(courierBookingControllerProvider.notifier);
    if (typed != null && typed > 0) {
      final bounds = state.bounds;
      controller.setProposedPrice(bounds == null ? typed : bounds.clamp(typed));
    }
    _syncOfferField();
  }

  Future<void> _submit() async {
    _commitTypedOffer();
    final controller = ref.read(courierBookingControllerProvider.notifier);
    final orderId = await controller.submitOrder();
    if (orderId != null && mounted) {
      context.push('/matching/$orderId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courierBookingControllerProvider);
    final controller = ref.read(courierBookingControllerProvider.notifier);
    final media = MediaQuery.of(context);

    ref.listen<CourierBookingState>(courierBookingControllerProvider, (
      prev,
      next,
    ) {
      // Price the route as soon as both ends are known.
      final routeChanged =
          prev?.dropoffLat != next.dropoffLat ||
          prev?.pickupLat != next.pickupLat ||
          prev?.dropoffLng != next.dropoffLng ||
          prev?.pickupLng != next.pickupLng;
      if (routeChanged && next.canFindCourier) controller.calculateFare();
      if (prev?.effectiveOffer != next.effectiveOffer) _syncOfferField();

      if (next.error != null && prev?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: context.palette.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        controller.clearError();
      }
    });

    final mapHeight = media.size.height * 0.34;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: mapHeight + 28,
            child: LiveMap(
              pickupLat: state.hasPickup ? state.pickupLat : null,
              pickupLng: state.hasPickup ? state.pickupLng : null,
              dropoffLat: state.hasDropoff ? state.dropoffLat : null,
              dropoffLng: state.hasDropoff ? state.dropoffLng : null,
              bottomPadding: 28,
            ),
          ),
          Positioned(
            top: media.padding.top + 10,
            left: 14,
            child: _CircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.go('/customer/home'),
            ),
          ),
          Positioned.fill(
            top: mapHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  media.padding.bottom + 20,
                ),
                children: [
                  _VehicleTabs(
                    selected: state.vehicleType,
                    onChanged: controller.setVehicleType,
                  ),
                  const SizedBox(height: 14),
                  _RouteCard(
                    state: state,
                    onEditPickup: () => _showPickupSearch(context, controller),
                    onDropoff: controller.setDropoff,
                    onRetryLocation: controller.initializeLocation,
                  ),
                  const SizedBox(height: 14),
                  _OfferPanel(
                    controller: _offerCtrl,
                    focusNode: _offerFocus,
                    state: state,
                    onStep: (delta) {
                      _offerFocus.unfocus();
                      controller.nudgeOffer(delta);
                    },
                  ),
                  const SizedBox(height: 14),
                  _PackageDetails(state: state, controller: controller),
                  const SizedBox(height: 12),
                  _PaymentPicker(
                    selected: state.paymentMethod,
                    onChanged: controller.setPaymentMethod,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 58,
                    child: FilledButton(
                      onPressed: state.canFindCourier && !state.isSubmitting
                          ? _submit
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _lime,
                        foregroundColor: _ink,
                        disabledBackgroundColor: _field,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _ink,
                              ),
                            )
                          : Text(
                              state.canFindCourier
                                  ? 'Find a courier'
                                  : 'Choose a destination',
                            ),
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

  void _showPickupSearch(
    BuildContext context,
    CourierBookingController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pickup point',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 16),
            AddressSearchField(
              label: 'Where should the courier collect from?',
              icon: Icons.trip_origin_rounded,
              onAddressSelected: (addr, lat, lng) {
                controller.setPickup(addr, lat, lng);
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                controller.initializeLocation();
              },
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Use my current location'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pieces ───────────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 48, height: 48, child: Icon(icon, color: _ink)),
      ),
    );
  }
}

class _VehicleTabs extends StatelessWidget {
  const _VehicleTabs({required this.selected, required this.onChanged});

  final CourierVehicle selected;
  final ValueChanged<CourierVehicle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final v in CourierVehicle.values) ...[
          Expanded(
            child: Material(
              color: v == selected ? const Color(0xFFD6ECFA) : _field,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(v),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        v == CourierVehicle.bike
                            ? Icons.two_wheeler_rounded
                            : Icons.directions_car_filled_rounded,
                        color: _ink,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        v.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (v != CourierVehicle.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.state,
    required this.onEditPickup,
    required this.onDropoff,
    required this.onRetryLocation,
  });

  final CourierBookingState state;
  final VoidCallback onEditPickup;
  final void Function(String, double, double) onDropoff;
  final VoidCallback onRetryLocation;

  @override
  Widget build(BuildContext context) {
    final locationProblem =
        !state.hasPickup &&
        !state.isLoadingLocation &&
        state.locationStatus != LocationStatus.granted;

    return Column(
      children: [
        Material(
          color: _field,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: locationProblem ? onRetryLocation : onEditPickup,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              child: Row(
                children: [
                  const Icon(
                    Icons.trip_origin_rounded,
                    color: Color(0xFF12805C),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.pickupDisplayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, color: _ink),
                    ),
                  ),
                  if (state.isLoadingLocation)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (locationProblem)
                    const Text(
                      'Retry',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AddressSearchField(
          label: 'To — where is it going?',
          icon: Icons.location_on_rounded,
          initialAddress: state.dropoffAddress.isNotEmpty
              ? state.dropoffAddress
              : null,
          onAddressSelected: onDropoff,
        ),
      ],
    );
  }
}

/// The inDrive-style fare offer: a big editable price, ₦100 steppers, and
/// the recommended fare and allowed range underneath.
class _OfferPanel extends StatelessWidget {
  const _OfferPanel({
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.onStep,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final CourierBookingState state;
  final ValueChanged<double> onStep;

  static const _step = 100.0;

  @override
  Widget build(BuildContext context) {
    final bounds = state.bounds;
    final offer = state.effectiveOffer;
    final atFloor = bounds != null && offer <= bounds.floor;
    final atCeiling = bounds != null && offer >= bounds.ceiling;
    final priced = bounds != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: _field,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offer your fare',
            style: TextStyle(fontSize: 14, color: _muted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                label: 'Lower offer by ₦100',
                onTap: priced && !atFloor ? () => onStep(-_step) : null,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: priced,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₦',
                    prefixStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                    hintText: state.isCalculatingFare ? '…' : '—',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                label: 'Raise offer by ₦100',
                onTap: priced && !atCeiling ? () => onStep(_step) : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              !priced
                  ? (state.isCalculatingFare
                        ? 'Working out a fair price…'
                        : 'Add a destination to see the recommended fare')
                  : 'Recommended ₦${bounds.recommended.toStringAsFixed(0)} · '
                        'you can offer ₦${bounds.floor.toStringAsFixed(0)}'
                        '–₦${bounds.ceiling.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
          ),
          if (priced && offer < bounds.recommended) ...[
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Lower offers can take longer to get a courier.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFFB54708)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: enabled ? _ink : const Color(0xFFD1D5DB)),
          ),
        ),
      ),
    );
  }
}

class _PackageDetails extends StatelessWidget {
  const _PackageDetails({required this.state, required this.controller});

  final CourierBookingState state;
  final CourierBookingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _field,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: state.packageDetailsExpanded,
          onExpansionChanged: (_) => controller.togglePackageDetails(),
          leading: const Icon(Icons.inventory_2_outlined, color: _ink),
          title: Text(
            state.hasPackageDetails
                ? state.packageDescription
                : 'Package & recipient',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, color: _ink),
          ),
          subtitle: Text(
            state.hasPackageDetails
                ? '${state.recipientName} · ${state.recipientPhone}'
                : 'Tell the courier what they are carrying',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 12.5),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: [
            _Input(
              label: 'What is it?',
              initial: state.packageDescription,
              onChanged: controller.setPackageDescription,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in PackageCategory.values)
                  ChoiceChip(
                    label: Text(c.name[0].toUpperCase() + c.name.substring(1)),
                    selected: state.packageCategory == c,
                    onSelected: (_) => controller.setPackageCategory(c),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _Input(
              label: "Recipient's name",
              initial: state.recipientName,
              onChanged: controller.setRecipientName,
            ),
            const SizedBox(height: 8),
            _Input(
              label: "Recipient's phone",
              initial: state.recipientPhone,
              keyboardType: TextInputType.phone,
              onChanged: controller.setRecipientPhone,
            ),
            const SizedBox(height: 8),
            _Input(
              label: 'Note for the courier (optional)',
              initial: state.notes,
              onChanged: controller.setNotes,
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    required this.initial,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(color: _ink),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PaymentPicker extends StatelessWidget {
  const _PaymentPicker({required this.selected, required this.onChanged});

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      PaymentMethod.wallet: ('Wallet', Icons.account_balance_wallet_outlined),
      PaymentMethod.cash: ('Cash', Icons.payments_outlined),
      PaymentMethod.card: ('Card', Icons.credit_card_outlined),
    };
    return Row(
      children: [
        for (final entry in labels.entries) ...[
          Expanded(
            child: ChoiceChip(
              avatar: Icon(entry.value.$2, size: 18),
              label: Text(entry.value.$1),
              selected: selected == entry.key,
              onSelected: (_) => onChanged(entry.key),
            ),
          ),
          if (entry.key != labels.keys.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
