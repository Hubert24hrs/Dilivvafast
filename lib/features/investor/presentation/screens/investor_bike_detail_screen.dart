import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/investor/domain/entities/bike_model.dart';
import 'package:dilivvafast/features/investor/presentation/widgets/earnings_chart.dart';

/// Provider for a single bike by ID
final bikeDetailProvider =
    StreamProvider.family<BikeModel?, String>((ref, bikeId) {
  return ref
      .watch(firestoreProvider)
      .collection('bikes')
      .doc(bikeId)
      .snapshots()
      .map((snap) => snap.exists ? BikeModel.fromFirestore(snap) : null);
});

/// Provider for bike earnings (last 30 days) based on the assigned rider's deliveries.
final bikeEarningsProvider =
    FutureProvider.family<Map<DateTime, double>, String>((ref, bikeId) async {
  final firestore = ref.watch(firestoreProvider);
  final bikeSnap = await firestore.collection('bikes').doc(bikeId).get();
  final riderId = bikeSnap.data()?['riderId'] as String?;
  if (riderId == null) return {};

  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day)
      .subtract(const Duration(days: 29));

  final ordersSnap = await firestore
      .collection('orders')
      .where('driverId', isEqualTo: riderId)
      .where('status', isEqualTo: 'delivered')
      .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .get();

  final data = <DateTime, double>{};
  for (var i = 0; i < 30; i++) {
    final day = start.add(Duration(days: i));
    data[DateTime(day.year, day.month, day.day)] = 0;
  }

  for (final doc in ordersSnap.docs) {
    final deliveredAt = (doc.data()['deliveredAt'] as Timestamp?)?.toDate();
    final earnings =
        (doc.data()['driverEarnings'] as num?)?.toDouble() ?? 0;
    if (deliveredAt != null) {
      final key =
          DateTime(deliveredAt.year, deliveredAt.month, deliveredAt.day);
      data[key] = (data[key] ?? 0) + earnings;
    }
  }

  return data;
});

class InvestorBikeDetailScreen extends ConsumerWidget {
  const InvestorBikeDetailScreen({super.key, required this.bikeId});
  final String bikeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeAsync = ref.watch(bikeDetailProvider(bikeId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Bike Details',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: bikeAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (bike) {
          if (bike == null) {
            return const Center(
                child: Text('Bike not found',
                    style: TextStyle(color: Colors.white54)));
          }
          return _buildBody(bike);
        },
      ),
    );
  }

  Widget _buildBody(BikeModel bike) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bike hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF9800).withValues(alpha: 0.12),
                  const Color(0xFFFF9500).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF9800).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                // Bike icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor(bike.status).withValues(alpha: 0.15),
                  ),
                  child: Icon(Icons.two_wheeler,
                      color: _statusColor(bike.status), size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  '${bike.make} ${bike.model}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${bike.year} · ${bike.plateNumber}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14),
                ),
                const SizedBox(height: 12),

                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(bike.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          _statusColor(bike.status).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _statusLabel(bike.status),
                    style: TextStyle(
                      color: _statusColor(bike.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Repayment progress
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Repayment Progress',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: bike.repaymentProgress.clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: const Color(0xFF0A0E21),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      bike.repaymentProgress >= 1.0
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF9800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₦${bike.repaidAmount.toStringAsFixed(0)} paid',
                      style: const TextStyle(
                          color: Color(0xFF4CAF50), fontSize: 12),
                    ),
                    Text(
                      '₦${bike.remainingRepayment.toStringAsFixed(0)} remaining',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    _statCard('Purchase',
                        '₦${bike.purchasePrice.toStringAsFixed(0)}'),
                    const SizedBox(width: 10),
                    _statCard('Monthly',
                        '₦${bike.monthlyInstalment.toStringAsFixed(0)}'),
                    const SizedBox(width: 10),
                    _statCard('Commission',
                        '${(bike.commissionRate * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Assigned rider
          if (bike.riderId != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.person,
                        color: Color(0xFF4CAF50), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assigned Rider',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        Text('Rider ID: ${bike.riderId!.substring(0, 8)}...',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Earnings chart (live data from Firestore)
          Builder(
            builder: (context) {
              // Access ref via ProviderScope.containerOf or use a Consumer
              return Consumer(
                builder: (context, ref, _) {
                  final earningsAsync = ref.watch(bikeEarningsProvider(bikeId));
                  return earningsAsync.when(
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFFF9800))),
                    ),
                    error: (e, _) => SizedBox(
                      height: 200,
                      child: Center(
                          child: Text('Chart error: $e',
                              style:
                                  const TextStyle(color: Colors.redAccent))),
                    ),
                    data: (earningsData) => EarningsChart(
                      title: 'Earnings (Last 30 Days)',
                      data: earningsData,
                      lineColor: const Color(0xFFFF9800),
                      height: 200,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E21),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Color(0xFFFF9800),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BikeStatus status) {
    return switch (status) {
      BikeStatus.pendingFunding => const Color(0xFFFF9800),
      BikeStatus.funded => const Color(0xFFFF6B00),
      BikeStatus.assigned => const Color(0xFF4CAF50),
      BikeStatus.active => const Color(0xFF4CAF50),
      BikeStatus.maintenance => const Color(0xFFFF5252),
      BikeStatus.decommissioned => Colors.white38,
    };
  }

  String _statusLabel(BikeStatus status) {
    return switch (status) {
      BikeStatus.pendingFunding => 'Pending Funding',
      BikeStatus.funded => 'Funded',
      BikeStatus.assigned => 'Assigned',
      BikeStatus.active => 'Active',
      BikeStatus.maintenance => 'Maintenance',
      BikeStatus.decommissioned => 'Decommissioned',
    };
  }

}
