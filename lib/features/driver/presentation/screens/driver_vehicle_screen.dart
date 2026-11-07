import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';

class DriverVehicleScreen extends ConsumerStatefulWidget {
  const DriverVehicleScreen({super.key});

  @override
  ConsumerState<DriverVehicleScreen> createState() =>
      _DriverVehicleScreenState();
}

class _DriverVehicleScreenState extends ConsumerState<DriverVehicleScreen> {
  final _plateCtrl = TextEditingController();
  String _selectedVehicle = 'motorcycle';
  bool _isSaving = false;

  /// Stored values are the ones dispatch and firestore.rules match on (and
  /// the driver application writes): a bike job goes to `motorcycle` and
  /// `bicycle`, a car job to `car` and `van`. This screen used to save
  /// display labels such as "Motorcycle (Box)", which matched neither — a
  /// courier who tapped Save stopped receiving and could not offer on jobs.
  static const _vehicleTypes = {
    'motorcycle': 'Motorcycle',
    'bicycle': 'Bicycle',
    'car': 'Car',
    'van': 'Van',
  };

  /// Reads both the stored values and the labels older builds saved.
  static String? canonicalVehicle(String? value) {
    final v = (value ?? '').toLowerCase();
    if (_vehicleTypes.containsKey(v)) return v;
    if (v.contains('motorcycle') || v.contains('keke')) return 'motorcycle';
    if (v.contains('bicycle')) return 'bicycle';
    if (v.contains('van')) return 'van';
    if (v.contains('car')) return 'car';
    return null;
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      _selectedVehicle = canonicalVehicle(user.vehicleType) ?? 'motorcycle';
      _plateCtrl.text = user.vehiclePlate ?? '';
    }
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveVehicleDetails() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(firestoreProvider).collection('users').doc(uid).update({
        'vehicleType': _selectedVehicle,
        'vehiclePlate': _plateCtrl.text.trim().toUpperCase(),
        'updatedAt': DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vehicle details updated successfully'),
            backgroundColor: context.palette.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating vehicle details: $e'),
            backgroundColor: context.palette.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Vehicle Details'),
        backgroundColor: context.palette.surfaceRaised,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.directions_bike_outlined,
              size: 64,
              color: context.palette.brand,
            ),
            const SizedBox(height: 16),
            Text(
              'Dispatch Vehicle Information',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ensure your vehicle type and license plate number match your physical delivery vehicle.',
              style: TextStyle(color: context.palette.textSecondary),
            ),
            const SizedBox(height: 24),
            Card(
              color: context.palette.surfaceRaised,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Category',
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVehicle,
                      dropdownColor: context.palette.surfaceRaised,
                      style: TextStyle(color: context.palette.textPrimary),
                      items: [
                        for (final v in _vehicleTypes.entries)
                          DropdownMenuItem(value: v.key, child: Text(v.value)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedVehicle = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Plate Number / Registration Code',
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _plateCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(color: context.palette.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'e.g. KJA-123XY',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveVehicleDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.palette.onBrand,
                        ),
                      )
                    : const Text(
                        'Save Vehicle Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
