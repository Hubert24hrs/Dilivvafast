import 'package:fast_delivery/core/models/user_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _isCashEnabled = true;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final userStream = userId != null 
        ? ref.watch(databaseServiceProvider).getUserStream(userId)
        : const Stream<UserModel?>.empty();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassCard(
            borderRadius: 50,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/'),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const BackgroundOrbs(),
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: StreamBuilder<UserModel?>(
              stream: userStream,
              builder: (context, snapshot) {
                final balance = snapshot.data?.walletBalance ?? 0.0;
            
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 110, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Neon Balance Card
                  Center(
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.2),
                            AppTheme.secondaryColor.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: -5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Background Decor
                          Positioned(
                            top: -20,
                            right: -20,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.flash_on, color: AppTheme.primaryColor, size: 16),
                                          SizedBox(width: 6),
                                          Text('FAST BALANCE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.nfc, color: Colors.white24, size: 30),
                                  ],
                                ),
                                
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available Balance',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₦${balance.toStringAsFixed(0)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.0,
                                        shadows: [
                                          Shadow(color: AppTheme.primaryColor.withValues(alpha: 0.5), blurRadius: 20),
                                        ],
                                      ),
                                    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.8)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 32),
                  
                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.add,
                          label: 'Top Up',
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Top Up coming with Payments Integration'))),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.history,
                          label: 'History',
                          onTap: () => context.go('/wallet/transactions'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'PAYMENT METHODS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GlassCard(
                    child: Column(
                      children: [
                        _buildPaymentMethodTile(
                          icon: FontAwesomeIcons.moneyBill,
                          title: 'Cash',
                          subtitle: 'Pay at destination',
                          trailing: Switch(
                            value: _isCashEnabled,
                            onChanged: (val) => setState(() => _isCashEnabled = val),
                            activeColor: AppTheme.primaryColor,
                            inactiveThumbColor: Colors.white54,
                            activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        const Divider(height: 1, color: Colors.white10, indent: 60),
                        _buildPaymentMethodTile(
                          icon: FontAwesomeIcons.creditCard,
                          title: 'Debit / Credit Card',
                          subtitle: 'Add a new card',
                          onTap: () => context.go('/wallet/add-card'),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.2, end: 0, delay: 200.ms),

                  const SizedBox(height: 24),

                   InkWell(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon!'))),
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.work_outline, color: Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Set up Work Profile',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ).animate().slideY(begin: 0.2, end: 0, delay: 300.ms),

                  const SizedBox(height: 40),
                  
                  // Info Links
                  Center(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.help_outline, size: 16, color: Colors.white54),
                      label: const Text('Payment Help & Support', style: TextStyle(color: Colors.white54)),
                    ),
                  ),
                ],
              ),
            );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GlassCard(
      onTap: onTap,
      color: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 13),
      ),
      trailing: trailing,
    );
  }
}
