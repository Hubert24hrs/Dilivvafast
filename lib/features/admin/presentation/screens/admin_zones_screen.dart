import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/booking/domain/entities/zone_model.dart';

/// Provider for all zones
final zonesProvider = StreamProvider<List<ZoneModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('zones')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
          (snap) => snap.docs.map((d) => ZoneModel.fromFirestore(d)).toList());
});

class AdminZonesScreen extends ConsumerWidget {
  const AdminZonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Delivery Zones',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF9500),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCreateDialog(context, ref),
      ),
      body: zonesAsync.when(
        data: (zones) {
          if (zones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 12),
                  const Text('No delivery zones configured',
                      style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: zones.length,
            itemBuilder: (_, i) => _buildZoneCard(context, ref, zones[i]),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  Widget _buildZoneCard(
      BuildContext context, WidgetRef ref, ZoneModel zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: zone.isActive
              ? const Color(0xFFFF6B00).withValues(alpha: 0.2)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.place,
                    color: Color(0xFFFF9500), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    Text(zone.city,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: zone.isActive,
                activeThumbColor: const Color(0xFF4CAF50),
                inactiveThumbColor: Colors.white24,
                onChanged: (v) {
                  ref
                      .read(firestoreProvider)
                      .collection('zones')
                      .doc(zone.id)
                      .update({'isActive': v});
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rate info
          Row(
            children: [
              _rateBadge('Base Fare',
                  '₦${zone.baseFare.toStringAsFixed(0)}'),
              const SizedBox(width: 10),
              _rateBadge('Per KM',
                  '₦${zone.perKmRate.toStringAsFixed(0)}'),
              const SizedBox(width: 10),
              _rateBadge('Surge ×',
                  zone.currentSurgeMultiplier.toStringAsFixed(1)),
              const SizedBox(width: 10),
              _rateBadge('Surge at',
                  '${zone.surgeThreshold} orders'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rateBadge(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E21),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9)),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameC = TextEditingController();
    final baseFareC = TextEditingController(text: '500');
    final perKmC = TextEditingController(text: '100');
    final surgeThresholdC = TextEditingController(text: '5');
    var selectedCity = 'Lagos';

    const cities = ['Lagos', 'Abuja', 'Kano', 'Port Harcourt'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1D1E33),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Delivery Zone',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _dialogField(nameC, 'Zone Name (e.g. Victoria Island)'),
                const SizedBox(height: 12),
                // City dropdown
                Row(
                  children: [
                    Text('City:',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedCity,
                      dropdownColor: const Color(0xFF1D1E33),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      items: cities
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedCity = v ?? 'Lagos'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _dialogField(baseFareC, 'Base Fare (₦)',
                    keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _dialogField(perKmC, 'Per KM Rate (₦)',
                    keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _dialogField(surgeThresholdC,
                    'Surge Threshold (concurrent orders)',
                    keyboard: TextInputType.number),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameC.text.trim().isEmpty) return;

                      await ref
                          .read(firestoreProvider)
                          .collection('zones')
                          .add(ZoneModel(
                            id: '',
                            name: nameC.text.trim(),
                            city: selectedCity,
                            baseFare: double.tryParse(
                                    baseFareC.text.trim()) ??
                                500,
                            perKmRate: double.tryParse(
                                    perKmC.text.trim()) ??
                                100,
                            surgeThreshold: int.tryParse(
                                    surgeThresholdC.text.trim()) ??
                                5,
                            createdAt: DateTime.now(),
                          ).toFirestore());

                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9500),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Zone',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController c, String hint,
      {TextInputType keyboard = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
