import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/services/promo_service.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Provider for PromoService
final promoServiceProvider = Provider<PromoService>((ref) => PromoService());

class PromoScreen extends ConsumerStatefulWidget {
  const PromoScreen({super.key});

  @override
  ConsumerState<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends ConsumerState<PromoScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _resultMessage;
  bool? _isSuccess;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _applyPromoCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
      _isSuccess = null;
    });

    final userId = ref.read(currentUserIdProvider) ?? 'guest';
    final result = await ref.read(promoServiceProvider).validatePromoCode(
      code,
      userId,
      1000.0, // Mock order amount for validation
    );

    setState(() {
      _isLoading = false;
      _resultMessage = result.message;
      _isSuccess = result.success;
    });

    if (result.success) {
      _codeController.clear();
      // In real app, you'd store this in state for checkout
    }
  }

  @override
  Widget build(BuildContext context) {
    final availablePromos = ref.read(promoServiceProvider).getAvailablePromos();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Promotions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promo Code Input
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter Promo Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeController,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'e.g., WELCOME50',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  filled: true,
                                  fillColor: Colors.white10,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _applyPromoCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                    )
                                  : const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        if (_resultMessage != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                _isSuccess == true ? Icons.check_circle : Icons.error,
                                color: _isSuccess == true ? Colors.green : Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _resultMessage!,
                                  style: TextStyle(
                                    color: _isSuccess == true ? Colors.green : Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 32),

                // Available Promos
                const Text(
                  'AVAILABLE PROMOTIONS',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                ...availablePromos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final promo = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      onTap: () {
                        _codeController.text = promo['code'];
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.local_offer, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    promo['code'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    promo['description'],
                                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                          ],
                        ),
                      ),
                    ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideX(begin: 0.1, end: 0),
                  );
                }),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}
