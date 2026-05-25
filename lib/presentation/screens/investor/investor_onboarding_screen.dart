import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class InvestorOnboardingScreen extends ConsumerStatefulWidget {
  const InvestorOnboardingScreen({super.key});

  @override
  ConsumerState<InvestorOnboardingScreen> createState() =>
      _InvestorOnboardingScreenState();
}

class _InvestorOnboardingScreenState
    extends ConsumerState<InvestorOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form controllers
  final _bvnController = TextEditingController();
  final _ninController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _bvnController.dispose();
    _ninController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not logged in');

      final user = ref.read(authServiceProvider).currentUser;

      // Create investor profile
      await ref
          .read(investorServiceProvider)
          .createInvestorProfile(
            userId: userId,
            email: user?.email ?? '',
            displayName: user?.displayName,
            phone: user?.phoneNumber,
          );

      // Update KYC (mock verification - would call Paystack Verify in production)
      if (_bvnController.text.isNotEmpty && _ninController.text.isNotEmpty) {
        await ref
            .read(investorServiceProvider)
            .updateKycStatus(
              userId: userId,
              bvnVerified: true, // Mock: In production, verify via Paystack
              ninVerified: true,
            );
      }

      // Update bank details
      if (_accountNumberController.text.isNotEmpty) {
        await ref
            .read(investorServiceProvider)
            .updateBankDetails(
              userId: userId,
              bankName: _bankNameController.text,
              accountNumber: _accountNumberController.text,
              accountName: _accountNameController.text,
            );
      }

      if (mounted) {
        context.go('/investor/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_currentPage > 0) {
                          _previousPage();
                        } else {
                          context.pop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Become an Investor',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),

              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? AppTheme.primaryColor
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildWelcomePage(),
                    _buildKycPage(),
                    _buildBankDetailsPage(),
                    _buildConfirmationPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Icon
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.3),
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ).animate().scale(delay: 200.ms),
          const SizedBox(height: 32),
          Text(
            'Fund Bikes, Earn Returns',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Invest in dispatch bikes through hire-purchase agreements and earn steady returns from rider earnings.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureItem(
            icon: Icons.motorcycle,
            title: 'Fund Bikes',
            description: 'Invest in bikes for riders who need them',
          ),
          _buildFeatureItem(
            icon: Icons.pie_chart,
            title: '50% Revenue Share',
            description: 'Earn 50% of rider fares until HP is paid',
          ),
          _buildFeatureItem(
            icon: Icons.trending_up,
            title: '18-25% Returns',
            description: 'Competitive returns over 12-24 months',
          ),
          _buildFeatureItem(
            icon: Icons.gps_fixed,
            title: 'GPS Tracking',
            description: 'Monitor your bikes in real-time',
          ),
          const SizedBox(height: 40),
          _buildPrimaryButton('Get Started', _nextPage),
        ],
      ),
    );
  }

  Widget _buildKycPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Identity Verification',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need to verify your identity to comply with Nigerian regulations.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _bvnController,
            label: 'Bank Verification Number (BVN)',
            hint: 'Enter your 11-digit BVN',
            keyboardType: TextInputType.number,
            maxLength: 11,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _ninController,
            label: 'National Identification Number (NIN)',
            hint: 'Enter your 11-digit NIN',
            keyboardType: TextInputType.number,
            maxLength: 11,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your data is encrypted and secure. We use Paystack Verify for KYC.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.amber,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildPrimaryButton('Continue', _nextPage),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _nextPage,
              child: Text(
                'Skip for now',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank Details',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your bank account for withdrawals.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _bankNameController,
            label: 'Bank Name',
            hint: 'e.g., Access Bank, GTBank',
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _accountNumberController,
            label: 'Account Number',
            hint: 'Enter 10-digit account number',
            keyboardType: TextInputType.number,
            maxLength: 10,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _accountNameController,
            label: 'Account Name',
            hint: 'As it appears on your account',
          ),
          const SizedBox(height: 40),
          _buildPrimaryButton('Continue', _nextPage),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _nextPage,
              child: Text(
                'Skip for now',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.3),
                  Colors.green.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
          ).animate().scale(delay: 200.ms),
          const SizedBox(height: 32),
          Text(
            'You\'re Almost There!',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'By proceeding, you agree to our Investor Terms & Conditions and acknowledge the risks involved in hire-purchase investments.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _buildConfirmItem('Revenue Split', '50% / 40% / 10%'),
                const Divider(color: Colors.white12, height: 20),
                _buildConfirmItem('HP Term', '12-24 months'),
                const Divider(color: Colors.white12, height: 20),
                _buildConfirmItem('Expected Return', '18-25%'),
                const Divider(color: Colors.white12, height: 20),
                _buildConfirmItem('Min Withdrawal', '₦5,000'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _isLoading
              ? CircularProgressIndicator(color: AppTheme.primaryColor)
              : _buildPrimaryButton('Complete Setup', _completeOnboarding),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (100 * (icon.hashCode % 5)).ms)
        .slideX(begin: 0.1);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: const TextStyle(color: Colors.white),
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white38),
            counterStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
        ),
      ],
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
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
