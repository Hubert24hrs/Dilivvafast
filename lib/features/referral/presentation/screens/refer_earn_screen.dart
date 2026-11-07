import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dilivvafast/core/constants/app_constants.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';

/// Invite friends with your code, and see who joined.
///
/// There is no cash reward: referral bonuses used to be paid into the in-app
/// wallet, which no longer exists — customers pay couriers directly.
class ReferEarnScreen extends ConsumerWidget {
  const ReferEarnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final referralCode = currentUser?.referralCode ?? '---';
    final uid = ref.watch(currentUserIdProvider) ?? '';

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Invite friends'),
        backgroundColor: context.palette.surfaceRaised,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.card_giftcard, size: 80, color: context.palette.brand),
            const SizedBox(height: 16),
            Text(
              'Invite your friends',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Share Dilivvafast with friends who send packages. They can enter your code when they sign up, and you will see them here once they join.',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Code Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.palette.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.palette.brand.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'YOUR REFERRAL CODE',
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        referralCode,
                        style: TextStyle(
                          color: context.palette.brand,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          color: context.palette.textSecondary,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Referral code copied to clipboard!',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  final text =
                      'Send packages across town with Dilivvafast — name your '
                      'price and pick your courier. Sign up with my code '
                      '$referralCode: ${AppConstants.playStoreUrl}';
                  // ignore: deprecated_member_use
                  Share.share(text);
                },
                icon: const Icon(Icons.share),
                label: const Text(
                  'Share Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'YOUR REFERRALS',
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: ref
                  .watch(firestoreProvider)
                  .collection('referrals')
                  // By referrer: the rules can prove that query only returns
                  // this user's referrals. Listing by code was always denied,
                  // so the list never loaded. `referrerId` is filled in by
                  // onReferralCreated.
                  .where('referrerId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: context.palette.brand,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Card(
                    color: context.palette.surfaceRaised,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No one has joined with your code yet.',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    final done = status == 'completed';

                    return Card(
                      color: context.palette.surfaceRaised,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: context.palette.brand,
                          child: Icon(
                            Icons.person,
                            color: context.palette.onBrand,
                          ),
                        ),
                        title: Text(
                          'Referral #${d.id.substring(0, 6)}',
                          style: TextStyle(color: context.palette.textPrimary),
                        ),
                        subtitle: Text(
                          done
                              ? 'Joined and made a delivery'
                              : 'Joined — no delivery yet',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
