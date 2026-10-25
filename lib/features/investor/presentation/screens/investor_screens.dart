import 'package:flutter/material.dart';

import 'package:dilivvafast/core/presentation/components/app_drawer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/utils/friendly_error.dart';

class InvestorHomeScreen extends ConsumerWidget {
  const InvestorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investorAsync = ref.watch(currentInvestorProvider);
    final bikesAsync = ref.watch(investorBikesProvider);
    final earningsAsync = ref.watch(investorEarningsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Investor')),
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
                  Text(
                    'Portfolio Value',
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  investorAsync.when(
                    loading: () => Text(
                      '...',
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontSize: 28,
                      ),
                    ),
                    error: (_, _) => Text(
                      '₦0',
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontSize: 28,
                      ),
                    ),
                    data: (inv) => Text(
                      '₦${(inv?.totalInvested ?? 0).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _miniStat(
                        context,
                        'Bikes',
                        '${bikesAsync.value?.length ?? 0}',
                        Icons.two_wheeler,
                      ),
                      const SizedBox(width: 20),
                      _miniStat(
                        context,
                        'Earnings',
                        '₦${earningsAsync.value?.fold(0.0, (s, e) => s + e.amount).toStringAsFixed(0) ?? '0'}',
                        Icons.trending_up,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bikes section
            Text(
              'My Bikes',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            bikesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: context.palette.brand),
              ),
              error: (e, _) => Text(
                friendlyError(e),
                style: TextStyle(color: context.palette.danger),
              ),
              data: (bikes) {
                if (bikes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.palette.surfaceRaised,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'No bikes in portfolio',
                        style: TextStyle(color: context.palette.textSecondary),
                      ),
                    ),
                  );
                }
                return Column(
                  children: bikes
                      .map(
                        (bike) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.palette.surfaceRaised,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.palette.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.two_wheeler,
                                color: context.palette.brand,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${bike.make} ${bike.model}',
                                      style: TextStyle(
                                        color: context.palette.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      bike.plateNumber,
                                      style: TextStyle(
                                        color: context.palette.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                bike.status.name,
                                style: TextStyle(
                                  color: bike.status.name == 'active'
                                      ? const Color(0xFF4CAF50)
                                      : context.palette.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: context.palette.textSecondary, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 10,
              ),
            ),
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
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        title: Text(
          'My Bikes',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: bikesAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.brand),
        ),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (bikes) {
          if (bikes.isEmpty) {
            return Center(
              child: Text(
                'No bikes',
                style: TextStyle(color: context.palette.textSecondary),
              ),
            );
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
                  color: context.palette.surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.two_wheeler,
                          color: context.palette.brand,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${b.make} ${b.model}',
                          style: TextStyle(
                            color: context.palette.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Value: ₦${b.purchasePrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Status: ${b.status.name}',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                          ),
                        ),
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
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        title: Text(
          'Earnings',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: earningsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.brand),
        ),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (earnings) {
          if (earnings.isEmpty) {
            return Center(
              child: Text(
                'No earnings yet',
                style: TextStyle(color: context.palette.textSecondary),
              ),
            );
          }
          final total = earnings.fold(0.0, (s, e) => s + e.amount);
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.palette.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Color(0xFF4CAF50),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Total: ₦${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                        color: context.palette.surfaceRaised,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.palette.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order: ${e.orderId}',
                                  style: TextStyle(
                                    color: context.palette.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}',
                                  style: TextStyle(
                                    color: context.palette.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+₦${e.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
