import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// Provider for referral stats
final _referralStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return {'referred': 0, 'earned': 0.0};

  final firestore = ref.watch(firestoreProvider);
  final referrals = await firestore
      .collection('users')
      .where('referredBy', isEqualTo: user.referralCode)
      .get();

  return {
    'referred': referrals.docs.length,
    'earned': referrals.docs.length * 500.0, // ₦500 per referral
  };
});

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(_referralStatsProvider);

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Refer & Earn',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.palette.brand.withValues(alpha: 0.12),
                    context.palette.brand.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.palette.brand.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.palette.brand.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      color: context.palette.brand,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Earn ₦500 per referral!',
                    style: TextStyle(
                      color: context.palette.onBrand,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share your code with friends. You both earn ₦500 when they complete their first delivery.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Referral code card
            userAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (user) {
                if (user == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceRaised,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.palette.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Referral Code',
                        style: TextStyle(
                          color: context.palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Code display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.surfaceBase,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.palette.brand.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.referralCode,
                              style: TextStyle(
                                color: context.palette.brand,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: context.palette.textMuted,
                                size: 20,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: user.referralCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Code copied!'),
                                    backgroundColor: Color(0xFF4CAF50),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Share button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            SharePlus.instance.share(
                              ShareParams(
                                text:
                                    'Join Dilivvafast and get ₦500! Use my referral code: '
                                    '${user.referralCode}\n\nDownload now: https://dilivvafast.com/download',
                              ),
                            );
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text(
                            'Share with Friends',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.palette.brand,
                            foregroundColor: context.palette.surfaceBase,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Stats
            statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (stats) => Row(
                children: [
                  _statCard(
                    context,
                    'Friends Referred',
                    '${stats['referred']}',
                    Icons.people,
                    context.palette.brand,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    context,
                    'Total Earned',
                    '₦${(stats['earned'] as double).toStringAsFixed(0)}',
                    Icons.monetization_on,
                    const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // How it works
            Text(
              'How it works',
              style: TextStyle(
                color: context.palette.onBrand,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _stepCard(
              context,
              '1',
              'Share your code',
              'Send your referral code to friends via any app',
            ),
            _stepCard(
              context,
              '2',
              'Friend signs up',
              'They create an account using your code',
            ),
            _stepCard(
              context,
              '3',
              'Both earn ₦500',
              'When they complete their 1st delivery, you both earn!',
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.palette.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.palette.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard(
    BuildContext context,
    String number,
    String title,
    String subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.palette.brand.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: context.palette.brand,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.palette.onBrand,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.palette.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
