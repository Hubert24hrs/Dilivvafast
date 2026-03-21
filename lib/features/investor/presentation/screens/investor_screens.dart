import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fast_delivery/core/providers/providers.dart';

class InvestorHomeScreen extends ConsumerWidget {
  const InvestorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investorAsync = ref.watch(currentInvestorProvider);
    final bikesAsync = ref.watch(investorBikesProvider);
    final earningsAsync = ref.watch(investorEarningsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: const Text('Investor Dashboard',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A148C).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Portfolio Value',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  investorAsync.when(
                    loading: () => const Text('...',
                        style: TextStyle(color: Colors.white, fontSize: 28)),
                    error: (_, __) => const Text('₦0',
                        style: TextStyle(color: Colors.white, fontSize: 28)),
                    data: (inv) => Text(
                      '₦${(inv?.totalInvested ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _miniStat('Bikes', '${bikesAsync.value?.length ?? 0}',
                          Icons.two_wheeler),
                      const SizedBox(width: 20),
                      _miniStat(
                          'Earnings',
                          '₦${earningsAsync.value?.fold(0.0, (s, e) => s + e.amount).toStringAsFixed(0) ?? '0'}',
                          Icons.trending_up),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bikes section
            const Text('My Bikes',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            bikesAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: Color(0xFF00F0FF))),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: Colors.redAccent)),
              data: (bikes) {
                if (bikes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1E33),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('No bikes in portfolio',
                          style: TextStyle(color: Colors.white54)),
                    ),
                  );
                }
                return Column(
                  children: bikes
                      .map((bike) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D1E33),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.two_wheeler,
                                    color: Color(0xFF00F0FF), size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${bike.make} ${bike.model}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14)),
                                      Text(
                                          bike.plateNumber,
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Text(
                                  bike.status.name,
                                  style: TextStyle(
                                      color: bike.status.name == 'active'
                                          ? const Color(0xFF4CAF50)
                                          : Colors.white38,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class InvestorBikesScreen extends ConsumerWidget {
  const InvestorBikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(investorBikesProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('My Bikes',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: bikesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bikes) {
          if (bikes.isEmpty) {
            return const Center(
                child: Text('No bikes',
                    style: TextStyle(color: Colors.white54)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bikes.length,
            itemBuilder: (context, i) {
              final b = bikes[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1E33),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.two_wheeler,
                            color: Color(0xFF00F0FF), size: 24),
                        const SizedBox(width: 10),
                        Text('${b.make} ${b.model}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Value: ₦${b.purchasePrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        Text('Status: ${b.status.name}',
                            style: const TextStyle(
                                color: Color(0xFF4CAF50), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class InvestorEarningsScreen extends ConsumerWidget {
  const InvestorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(investorEarningsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Earnings',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: earningsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (earnings) {
          if (earnings.isEmpty) {
            return const Center(
                child: Text('No earnings yet',
                    style: TextStyle(color: Colors.white54)));
          }
          final total = earnings.fold(0.0, (s, e) => s + e.amount);
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1E33),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.trending_up,
                        color: Color(0xFF4CAF50), size: 28),
                    const SizedBox(width: 12),
                    Text('Total: ₦${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: earnings.length,
                  itemBuilder: (context, i) {
                    final e = earnings[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1E33),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money,
                              color: Color(0xFF4CAF50), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order: ${e.orderId}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13)),
                                Text(
                                    '${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}',
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text('+₦${e.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
