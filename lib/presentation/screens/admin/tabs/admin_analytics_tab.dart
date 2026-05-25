import 'package:fast_delivery/core/providers/providers.dart';

import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAnalyticsTab extends ConsumerWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ref.watch(adminServiceProvider).getAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};
        final revenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        final activeRides = (data['activeRides'] as num?)?.toInt() ?? 0;
        final totalDrivers = (data['totalDrivers'] as num?)?.toInt() ?? 0;
        final totalInvestors = (data['totalInvestors'] as num?)?.toInt() ?? 0;

        return GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          padding: const EdgeInsets.all(16),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              title: 'Total Revenue',
              value: '₦${revenue.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.greenAccent,
            ),
            _buildStatCard(
              title: 'Active Rides',
              value: activeRides.toString(),
              icon: Icons.directions_bike,
              color: Colors.blueAccent,
            ),
            _buildStatCard(
              title: 'Total Drivers',
              value: totalDrivers.toString(),
              icon: Icons.people,
              color: Colors.orangeAccent,
            ),
            _buildStatCard(
              title: 'Investors',
              value: totalInvestors.toString(),
              icon: Icons.trending_up,
              color: Colors.purpleAccent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
