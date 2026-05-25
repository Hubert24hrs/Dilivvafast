import 'package:fast_delivery/core/models/earnings_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DriverEarningsScreen extends ConsumerStatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  ConsumerState<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends ConsumerState<DriverEarningsScreen> {
  bool _isWithdrawing = false;
  Map<String, double> _summary = {'today': 0, 'week': 0, 'month': 0, 'total': 0};
  double _availableBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadEarningsSummary();
  }

  Future<void> _loadEarningsSummary() async {
    final driverId = ref.read(currentUserIdProvider);
    if (driverId == null) return;

    final summary = await ref.read(earningsServiceProvider).getEarningsSummary(driverId);
    final balance = await ref.read(earningsServiceProvider).getAvailableBalance(driverId);

    if (mounted) {
      setState(() {
        _summary = summary;
        _availableBalance = balance;
      });
    }
  }

  void _showWithdrawalSheet() {
    final bankController = TextEditingController();
    final accountController = TextEditingController();
    final nameController = TextEditingController();
    final amountController = TextEditingController(text: _availableBalance.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Withdraw Earnings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available: ₦${_availableBalance.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.primaryColor, fontSize: 16),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: amountController,
                label: 'Amount (₦)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: bankController,
                label: 'Bank Name',
                hint: 'e.g., GTBank',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: accountController,
                label: 'Account Number',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: nameController,
                label: 'Account Name',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isWithdrawing
                      ? null
                      : () => _processWithdrawal(
                            double.tryParse(amountController.text) ?? 0,
                            bankController.text,
                            accountController.text,
                            nameController.text,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isWithdrawing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('WITHDRAW', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _processWithdrawal(
    double amount,
    String bankName,
    String accountNumber,
    String accountName,
  ) async {
    if (amount <= 0 || bankName.isEmpty || accountNumber.isEmpty || accountName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isWithdrawing = true);

    try {
      final driverId = ref.read(currentUserIdProvider);
      if (driverId == null) throw Exception('Not logged in');

      await ref.read(earningsServiceProvider).requestWithdrawal(
            driverId: driverId,
            amount: amount,
            bankName: bankName,
            accountNumber: accountNumber,
            accountName: accountName,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadEarningsSummary();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isWithdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverId = ref.watch(currentUserIdProvider);
    Stream<List<EarningsModel>>? earningsStream;
    if (driverId != null) {
      earningsStream = ref.watch(earningsServiceProvider).getDriverEarnings(driverId);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          'Earnings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            _buildBalanceCard(),
            const SizedBox(height: 24),

            // Summary Cards
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Today', _summary['today'] ?? 0, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('This Week', _summary['week'] ?? 0, Colors.orange)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSummaryCard('This Month', _summary['month'] ?? 0, Colors.purple)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('All Time', _summary['total'] ?? 0, Colors.green)),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Earnings
            Text(
              'Recent Earnings',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<EarningsModel>>(
              stream: earningsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final earnings = snapshot.data ?? [];

                if (earnings.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No earnings yet', style: TextStyle(color: Colors.grey)),
                          Text('Complete rides to start earning!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: earnings.length,
                  itemBuilder: (context, index) {
                    final earning = earnings[index];
                    return _buildEarningTile(earning);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '₦${_availableBalance.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _availableBalance > 0 ? _showWithdrawalSheet : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'WITHDRAW',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.show_chart, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            '₦${amount.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningTile(EarningsModel earning) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip #${earning.rideId.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  dateFormat.format(earning.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+₦${earning.netAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                earning.status.toUpperCase(),
                style: TextStyle(
                  color: earning.status == 'withdrawn' ? Colors.grey : Colors.green,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
