import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dilivvafast/core/providers/providers.dart';

class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen>
    with WidgetsBindingObserver {
  final _amountController = TextEditingController();
  bool _isProcessing = false;
  int? _selectedPreset;

  /// Reference of the checkout the user was last sent to. Kept so we can verify
  /// it when they come back from the Paystack page.
  String? _pendingReference;

  /// Whether the "complete your payment" dialog is currently on screen.
  bool _isPendingDialogOpen = false;

  static const _presets = [1000, 2000, 5000, 10000, 20000, 50000];

  /// Must match MIN_TOP_UP_NAIRA in functions/src/index.ts.
  static const _minimumAmount = 100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the Paystack checkout page — settle the payment.
    if (state == AppLifecycleState.resumed && _pendingReference != null) {
      _verifyPendingPayment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Fund Wallet',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B00).withValues(alpha: 0.12),
                    const Color(0xFFFF9500).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Text('Current Balance',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  ref.watch(walletBalanceProvider).when(
                        loading: () => const SizedBox(
                          height: 38,
                          width: 38,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF6B00),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        error: (_, _) => const Text(
                          'Unavailable',
                          style: TextStyle(color: Colors.white54, fontSize: 20),
                        ),
                        data: (balance) => Text(
                          '₦${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Amount input
            const Text('Enter Amount',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
                onChanged: (_) => setState(() => _selectedPreset = null),
                decoration: InputDecoration(
                  prefixText: '₦ ',
                  prefixStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  hintText: '0',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 24),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Preset amounts
            const Text('Quick Select',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _presets.map((amount) {
                final isSelected = _selectedPreset == amount;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPreset = amount;
                      _amountController.text = amount.toString();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B00).withValues(alpha: 0.15)
                          : const Color(0xFF1D1E33),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF6B00)
                            : Colors.white12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '₦${_formatAmount(amount)}',
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFFF6B00)
                            : Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Payment method
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00C853).withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.credit_card,
                        color: Color(0xFF00C853), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Paystack',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text('Card, Bank Transfer, USSD',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle,
                      color: Color(0xFF00C853), size: 22),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: const Color(0xFF0A0E21),
                  disabledBackgroundColor:
                      const Color(0xFFFF6B00).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFF0A0E21),
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Security note
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(width: 4),
                  Text(
                    'Secured by Paystack',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toString();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _handlePayment() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < _minimumAmount) {
      _showError('Minimum amount is ₦$_minimumAmount');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // The backend creates the Paystack transaction and owns the reference —
      // the app never handles a Paystack key.
      final result = await ref
          .read(paymentRepositoryProvider)
          .initializePayment(amount: amount);

      final session = result.fold(
        (failure) {
          _showError(failure.message);
          return null;
        },
        (session) => session,
      );
      if (session == null) return;

      final uri = Uri.parse(session.authorizationUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showError('Could not open the payment page');
        return;
      }

      _pendingReference = session.reference;
      if (mounted) _showPendingDialog();
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Ask the backend to confirm the pending reference and credit the wallet.
  ///
  /// Runs when the user returns to the app and when they tap "I've paid".
  /// Calling it repeatedly is safe: the Cloud Function credits a given
  /// reference at most once.
  Future<void> _verifyPendingPayment() async {
    final reference = _pendingReference;
    if (reference == null || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final result = await ref
          .read(paymentRepositoryProvider)
          .verifyPayment(reference);

      result.fold(
        (failure) => _showError(failure.message),
        (verification) {
          _pendingReference = null;
          if (!mounted) return;
          if (_isPendingDialogOpen) {
            _isPendingDialogOpen = false;
            Navigator.of(context).pop();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(verification.message),
              backgroundColor: const Color(0xFF00C853),
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Shown while the user is completing payment in the browser.
  ///
  /// The wallet is credited by the backend (webhook, or the verify call this
  /// dialog triggers), so this only reports status — it never claims success on
  /// its own.
  void _showPendingDialog() {
    _isPendingDialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.hourglass_top,
                  color: Color(0xFFFF6B00),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Complete your payment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Finish the payment in your browser, then come back here. '
                'We check automatically when you return.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _verifyPendingPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: const Color(0xFF0A0E21),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "I've completed payment",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  _isPendingDialogOpen = false;
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _isPendingDialogOpen = false);
  }
}
