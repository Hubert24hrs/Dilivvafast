import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/services/referral_service.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

// Provider for ReferralService
final referralServiceProvider = Provider<ReferralService>((ref) => ReferralService());

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final TextEditingController _codeController = TextEditingController();
  ReferralStats? _stats;
  String? _userCode;
  bool _isLoading = true;
  bool _isApplying = false;
  String? _resultMessage;
  bool? _isSuccess;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadReferralData() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final code = await ref.read(referralServiceProvider).getOrCreateReferralCode(userId);
      final stats = await ref.read(referralServiceProvider).getReferralStats(userId);
      
      if (mounted) {
        setState(() {
          _userCode = code;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _applyReferralCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isApplying = true;
      _resultMessage = null;
      _isSuccess = null;
    });

    final result = await ref.read(referralServiceProvider).applyReferralCode(userId, code);

    setState(() {
      _isApplying = false;
      _resultMessage = result.message;
      _isSuccess = result.success;
    });

    if (result.success) {
      _codeController.clear();
      _loadReferralData(); // Refresh stats
    }
  }

  void _shareReferralCode() {
    if (_userCode == null) return;
    SharePlus.instance.share(
      ShareParams(
        text: 'Join Fast Delivery with my referral code $_userCode and we both get ₦100! Download: https://fastdelivery.ng/download',
        subject: 'Fast Delivery Referral',
      ),
    );
  }

  void _copyCode() {
    if (_userCode == null) return;
    Clipboard.setData(ClipboardData(text: _userCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Refer & Earn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            child: SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Your Referral Code Card
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.card_giftcard, color: AppTheme.primaryColor, size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                'Your Referral Code',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _userCode ?? '------',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _copyCode,
                                    icon: const Icon(Icons.copy, size: 18),
                                    label: const Text('Copy'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white10,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _shareReferralCode,
                                    icon: const Icon(Icons.share, size: 18),
                                    label: const Text('Share'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn().scale(delay: 100.ms),

                      const SizedBox(height: 24),

                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Referrals',
                              '${_stats?.referralCount ?? 0}',
                              Icons.people,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Earnings',
                              '₦${_stats?.totalEarnings.toStringAsFixed(0) ?? '0'}',
                              Icons.account_balance_wallet,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 32),

                      // Enter Referral Code
                      const Text(
                        'HAVE A REFERRAL CODE?',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: _codeController,
                                style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
                                textCapitalization: TextCapitalization.characters,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: 'Enter code',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  filled: true,
                                  fillColor: Colors.white10,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isApplying ? null : _applyReferralCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: _isApplying
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                        )
                                      : const Text('Apply Code', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              if (_resultMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _resultMessage!,
                                  style: TextStyle(
                                    color: _isSuccess == true ? Colors.green : Colors.red,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 32),

                      // How it works
                      const Text(
                        'HOW IT WORKS',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildHowItWorksItem('1', 'Share your unique code with friends'),
                      _buildHowItWorksItem('2', 'They sign up using your code'),
                      _buildHowItWorksItem('3', 'You both get ₦100 bonus!'),
                    ],
                  ),
                ),
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
