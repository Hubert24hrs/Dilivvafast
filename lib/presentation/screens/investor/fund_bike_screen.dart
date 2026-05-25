import 'package:fast_delivery/core/models/bike_model.dart';
import 'package:fast_delivery/presentation/common/empty_state_widget.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class FundBikeScreen extends ConsumerStatefulWidget {
  const FundBikeScreen({super.key});

  @override
  ConsumerState<FundBikeScreen> createState() => _FundBikeScreenState();
}

class _FundBikeScreenState extends ConsumerState<FundBikeScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'honda', 'tvs', 'bajaj'];

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(availableBikeCampaignsProvider);

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
                    child: campaignsAsync.when(
                      data: (bikes) => _buildCampaignList(bikes),
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
              'Fund a Bike',
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

  Widget _buildCampaignList(List<BikeModel> bikes) {
    // Filter bikes
    final filtered = _selectedFilter == 'all'
        ? bikes
        : bikes.where((b) => b.make.toLowerCase() == _selectedFilter).toList();

    return Column(
      children: [
        _buildFilterChips().animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 16),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildCampaignCard(filtered[index])
                        .animate(delay: (index * 100).ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                filter == 'all' ? 'All Bikes' : filter.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: AppTheme.surfaceColor,
              selectedColor: const Color(0xFF3949AB),
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampaignCard(BikeModel bike) {
    // Calculate HP terms
    const interestRate = 0.20; // 20%
    const termMonths = 18;
    final totalInterest = bike.purchasePrice * interestRate * (termMonths / 12);
    final totalRepayment = bike.purchasePrice + totalInterest;
    final monthlyDeduction = totalRepayment / termMonths;
    final expectedMonthlyReturn =
        monthlyDeduction * 0.5; // 50% goes to investor

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFundingSheet(bike),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, Color(0xFF00FF94)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.motorcycle,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bike.displayName,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bike.id,
                            style: GoogleFonts.sourceCodePro(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        'AVAILABLE',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoItem(
                            'Purchase Price',
                            '₦${_formatAmount(bike.purchasePrice)}',
                          ),
                          _buildInfoItem('Interest Rate', '20% p.a.'),
                          _buildInfoItem('Term', '$termMonths months'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.3),
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Est. Monthly Return: ',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '₦${_formatAmount(expectedMonthlyReturn)}',
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFF3949AB),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showFundingSheet(bike),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.primaryForeground,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Fund This Bike',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: EmptyStateWidget(
        title: 'No bikes available',
        message: _selectedFilter == 'all'
            ? 'There are currently no bikes available for funding.'
            : 'No ${_selectedFilter.toUpperCase()} bikes available matching your filter.',
        icon: Icons.search_off,
        buttonText: _selectedFilter == 'all' ? null : 'Clear Filter',
        onButtonPressed: _selectedFilter == 'all'
            ? null
            : () => setState(() => _selectedFilter = 'all'),
      ),
    );
  }

  void _showFundingSheet(BikeModel bike) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FundingBottomSheet(bike: bike),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _FundingBottomSheet extends ConsumerStatefulWidget {
  final BikeModel bike;

  const _FundingBottomSheet({required this.bike});

  @override
  ConsumerState<_FundingBottomSheet> createState() =>
      _FundingBottomSheetState();
}

class _FundingBottomSheetState extends ConsumerState<_FundingBottomSheet> {
  int _currentStep = 0;
  bool _agreedToTerms = false;
  bool _isProcessing = false;
  final _signaturePoints = <Offset>[];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withValues(alpha: 0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildStepIndicator(),
          Expanded(child: _buildStepContent()),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 20),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white30,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStepDot(0, 'Review'),
          Expanded(child: _buildStepLine(0)),
          _buildStepDot(1, 'Sign'),
          Expanded(child: _buildStepLine(1)),
          _buildStepDot(2, 'Confirm'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3949AB) : Colors.white12,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF3949AB) : Colors.white30,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isActive ? const Color(0xFF3949AB) : Colors.white12,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildReviewStep();
      case 1:
        return _buildSignatureStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildReviewStep() {
    const interestRate = 0.20;
    const termMonths = 18;
    final totalInterest =
        widget.bike.purchasePrice * interestRate * (termMonths / 12);
    final totalRepayment = widget.bike.purchasePrice + totalInterest;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review HP Agreement',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.bike.displayName,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildReviewItem('Bike ID', widget.bike.id),
          _buildReviewItem(
            'Purchase Price',
            '₦${widget.bike.purchasePrice.toStringAsFixed(0)}',
          ),
          _buildReviewItem('Interest Rate', '20% per annum'),
          _buildReviewItem('Term Duration', '$termMonths months'),
          _buildReviewItem(
            'Total Interest',
            '₦${totalInterest.toStringAsFixed(0)}',
          ),
          _buildReviewItem(
            'Total Repayment',
            '₦${totalRepayment.toStringAsFixed(0)}',
            isHighlight: true,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Revenue Split',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Investor: 50% of each ride\n• Rider: 40% of each ride\n• App Fee: 10% of each ride',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _agreedToTerms,
            onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
            title: Text(
              'I agree to the terms and conditions',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFF3949AB),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: isHighlight ? const Color(0xFF3949AB) : Colors.white,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: isHighlight ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digital Signature',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign below to confirm your investment',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white30, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _signaturePoints.add(details.localPosition);
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _signaturePoints.add(Offset.infinite);
                    });
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(_signaturePoints),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _signaturePoints.clear();
              });
            },
            icon: const Icon(Icons.clear, color: Colors.white70),
            label: Text(
              'Clear',
              style: GoogleFonts.plusJakartaSans(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to Fund!',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You are about to fund ${widget.bike.displayName}',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildConfirmItem(
                  'Amount',
                  '₦${widget.bike.purchasePrice.toStringAsFixed(0)}',
                ),
                const Divider(color: Colors.white12, height: 24),
                _buildConfirmItem('Payment Method', 'Paystack (Mock)'),
              ],
            ),
          ),
          const Spacer(),
          if (_isProcessing)
            const CircularProgressIndicator(color: Color(0xFF3949AB))
          else
            Text(
              'Tap "Complete Funding" to proceed',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildConfirmItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing
                    ? null
                    : () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.primaryForeground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 2 ? 'Complete Funding' : 'Next',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextStep() async {
    if (_currentStep == 0) {
      if (!_agreedToTerms) {
        _showSnackBar('Please agree to the terms and conditions');
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_signaturePoints.length < 10) {
        _showSnackBar('Please provide your signature');
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      // Complete funding
      await _completeFunding();
    }
  }

  Future<void> _completeFunding() async {
    setState(() => _isProcessing = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('User not logged in');

      // Fund the bike
      await ref
          .read(investorServiceProvider)
          .fundBike(
            investorId: userId,
            bikeId: widget.bike.id,
            principalAmount: widget.bike.purchasePrice,
            interestRate: 0.20,
            termMonths: 18,
          );

      if (!mounted) return;

      // Show success and close
      _showSnackBar('Bike funded successfully!', isSuccess: true);
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;
      Navigator.of(context).pop();
      context.pop(); // Return to dashboard
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Funding failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].isFinite && points[i + 1].isFinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
