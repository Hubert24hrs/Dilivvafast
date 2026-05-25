import 'package:fast_delivery/core/providers/providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserIdProvider) != null
        ? ref.watch(databaseServiceProvider).getUserStream(ref.watch(currentUserIdProvider)!)
        : const Stream.empty();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Profile Header
          StreamBuilder(
            stream: userAsync,
            builder: (context, snapshot) {
              final name = snapshot.data?.displayName ?? 'User';
              final email = snapshot.data?.email ?? '';
              
              return InkWell(
                onTap: () {
                  context.pop(); // Close drawer
                  context.push('/profile');
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black12)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: snapshot.data?.photoUrl != null
                            ? NetworkImage(snapshot.data!.photoUrl!)
                            : null,
                        child: snapshot.data?.photoUrl == null
                            ? const Icon(Icons.person, size: 30, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                             Text(
                              email.isNotEmpty ? email : 'My account',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50), // Green
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.black54),
                    ],
                  ),
                ),
              );
            },
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.wallet, 
                  title: 'Payment', 
                  onTap: () {
                    context.pop();
                    context.go('/wallet');
                  },
                ),
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.tag, 
                  title: 'Promotions', 
                  subtitle: 'Enter promo code',
                  isNew: true,
                  onTap: () {
                    context.pop();
                    context.go('/promo');
                  },
                ),
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.clockRotateLeft, 
                  title: 'History', 
                  onTap: () {
                    context.pop();
                    context.go('/history');
                  },
                ),
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.gift, 
                  title: 'Refer & Earn', 
                  onTap: () {
                    context.pop();
                    context.go('/referral');
                  },
                ),
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.briefcase, 
                  title: 'Expense Your Rides', 
                  onTap: () {},
                ),
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.circleQuestion, 
                  title: 'Support', 
                  onTap: () {},
                ),
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.gear, 
                  title: 'Settings', 
                  onTap: () {
                    context.pop();
                    context.go('/settings');
                  },
                ),
                _buildMenuItem(
                  context, 
                  icon: FontAwesomeIcons.circleInfo, 
                  title: 'About', 
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Become a driver Banner
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () {
                context.pop();
                context.push('/driver-selection');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9), // Light green
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Become a driver',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Earn money on your schedule',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          // Investor Mode Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: InkWell(
              onTap: () {
                context.pop();
                context.push('/investor');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.chartLine,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Investor Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fund bikes & earn returns',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon, 
    required String title, 
    String? subtitle, 
    bool isNew = false,
    required VoidCallback onTap
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54, size: 20),
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isNew) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      subtitle: subtitle != null ? Text(
        subtitle,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 12,
        ),
      ) : null,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
