import 'package:fast_delivery/core/models/investor_earnings_model.dart';
import 'package:fast_delivery/core/models/investor_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvestorWithdrawScreen extends ConsumerStatefulWidget {
  const InvestorWithdrawScreen({super.key});

  @override
  ConsumerState<InvestorWithdrawScreen> createState() =>
      _InvestorWithdrawScreenState();
}

class _InvestorWithdrawScreenState
    extends ConsumerState<InvestorWithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final investorAsync = ref.watch(currentInvestorProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            const BackgroundOrbs(),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: investorAsync.when(
                      data: (investor) {
                        if (investor == null) {
                          return const Center(
                            child: Text('Investor profile not found'),
                          );
                        }
                        return _buildContent(investor);
                      },
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Error: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.neomorphicShadow(),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Withdraw Funds',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(InvestorModel investor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(
            investor,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          _buildWithdrawForm(
            investor,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 24),
          _buildSectionTitle('Withdrawal History'),
          const SizedBox(height: 16),
          _buildWithdrawalHistory(
            investor,
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(InvestorModel investor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D26), AppTheme.primaryColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Available Balance',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                investor.walletBalance.toStringAsFixed(2),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawForm(InvestorModel investor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withdraw to Bank',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (investor.bankDetails != null) ...[
              _buildBankDetailsCard(investor.bankDetails!),
              const SizedBox(height: 20),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please add bank details in your profile first',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Amount',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white30),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    '₦',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid amount';
                }
                if (amount < 5000) {
                  return 'Minimum withdrawal is ₦5,000';
                }
                if (amount > 500000) {
                  return 'Maximum daily withdrawal is ₦500,000';
                }
                if (amount > investor.walletBalance) {
                  return 'Insufficient balance';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildQuickAmountButton('₦10K', 10000),
                const SizedBox(width: 8),
                _buildQuickAmountButton('₦50K', 50000),
                const SizedBox(width: 8),
                _buildQuickAmountButton('₦100K', 100000),
                const SizedBox(width: 8),
                _buildQuickAmountButton('All', investor.walletBalance),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Withdrawal Limits',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Minimum: ₦5,000\n• Maximum daily: ₦500,000\n• Processing time: Instant via Paystack',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: investor.bankDetails == null || _isProcessing
                    ? null
                    : () => _handleWithdraw(investor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Withdraw Funds',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailsCard(BankDetails bankDetails) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankDetails.bankName,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bankDetails.accountNumber,
                  style: GoogleFonts.sourceCodePro(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  bankDetails.accountName,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54,
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

  Widget _buildQuickAmountButton(String label, double amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          _amountController.text = amount.toInt().toString();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white30),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalHistory(InvestorModel investor) {
    return StreamBuilder<List<InvestorWithdrawalModel>>(
      stream: ref
          .read(investorServiceProvider)
          .getWithdrawalHistory(investor.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                const Icon(Icons.history, size: 48, color: Colors.white30),
                const SizedBox(height: 12),
                Text(
                  'No withdrawals yet',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final withdrawals = snapshot.data!;

        return Column(
          children: withdrawals.asMap().entries.map((entry) {
            return _buildWithdrawalCard(entry.value)
                .animate(delay: (entry.key * 50).ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.1, end: 0);
          }).toList(),
        );
      },
    );
  }

  Widget _buildWithdrawalCard(InvestorWithdrawalModel withdrawal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusColor(withdrawal.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getStatusIcon(withdrawal.status),
              color: _getStatusColor(withdrawal.status),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₦${withdrawal.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  withdrawal.bankName,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, y - h:mm a').format(withdrawal.createdAt),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(withdrawal.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              withdrawal.status.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                color: _getStatusColor(withdrawal.status),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWithdraw(InvestorModel investor) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);

      await ref
          .read(investorServiceProvider)
          .requestWithdrawal(investorId: investor.userId, amount: amount);

      if (!mounted) return;

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Withdrawal of ₦${amount.toStringAsFixed(0)} initiated!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _amountController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.sync;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}
