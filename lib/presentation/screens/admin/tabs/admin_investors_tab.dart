import 'package:fast_delivery/core/models/investor_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';

import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminInvestorsTab extends ConsumerWidget {
  const AdminInvestorsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<InvestorModel>>(
      stream: ref.watch(adminServiceProvider).getInvestors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final investors = snapshot.data ?? [];

        if (investors.isEmpty) {
          return const Center(
            child: Text(
              'No investors found',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: investors.length,
          itemBuilder: (context, index) {
            return _buildInvestorCard(investors[index]);
          },
        );
      },
    );
  }

  Widget _buildInvestorCard(InvestorModel investor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investor.displayName ?? 'Unknown Investor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        investor.email,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  _buildKycStatusChip(investor.kycStatus),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat('Invested', '₦${investor.totalInvested.toStringAsFixed(2)}'),
                  _buildStat('Wallet', '₦${investor.walletBalance.toStringAsFixed(2)}'),
                  _buildStat('Bikes', '${investor.activeBikes}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildKycStatusChip(String status) {
    Color color;
    switch (status) {
      case 'verified':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
