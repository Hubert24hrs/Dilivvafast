import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/features/driver/domain/entities/driver_application_model.dart';

class DriverApplicationScreen extends ConsumerStatefulWidget {
  const DriverApplicationScreen({super.key});

  @override
  ConsumerState<DriverApplicationScreen> createState() =>
      _DriverApplicationScreenState();
}

class _DriverApplicationScreenState
    extends ConsumerState<DriverApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _isSubmitting = false;

  // Step 1: Personal info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2: Vehicle
  String _vehicleType = 'motorcycle';
  final _plateController = TextEditingController();

  // Step 3: Bank
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  static const _vehicleTypes = [
    ('motorcycle', Icons.two_wheeler, 'Motorcycle'),
    ('bicycle', Icons.pedal_bike, 'Bicycle'),
    ('car', Icons.directions_car, 'Car'),
    ('van', Icons.local_shipping, 'Van'),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _nameController.text = user.fullName;
        _emailController.text = user.email;
        _phoneController.text = user.phone;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
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
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.pop();
            }
          },
        ),
        title: const Text('Become a Rider',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Step ${_step + 1}/3',
              style: const TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i <= _step
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF1D1E33),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _step == 0
                      ? _buildPersonalStep()
                      : _step == 1
                          ? _buildVehicleStep()
                          : _buildBankStep(),
                ),
              ),
            ),
          ),

          // Bottom button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _step < 2 ? 'Continue' : 'Submit Application',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalStep() {
    return Column(
      key: const ValueKey('personal'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(Icons.person, 'Personal Information',
            'Tell us about yourself'),
        const SizedBox(height: 24),
        _buildField(_nameController, 'Full Name', Icons.person_outline),
        const SizedBox(height: 14),
        _buildField(_emailController, 'Email', Icons.email_outlined,
            keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _buildField(_phoneController, 'Phone Number', Icons.phone_outlined,
            keyboard: TextInputType.phone),
      ],
    );
  }

  Widget _buildVehicleStep() {
    return Column(
      key: const ValueKey('vehicle'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(Icons.two_wheeler, 'Vehicle Details',
            'Select your vehicle type and enter plate number'),
        const SizedBox(height: 24),

        // Vehicle type selector
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _vehicleTypes.map((v) {
            final isSelected = _vehicleType == v.$1;
            return GestureDetector(
              onTap: () => setState(() => _vehicleType = v.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: (MediaQuery.of(context).size.width - 60) / 2,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                      : const Color(0xFF1D1E33),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : Colors.white12,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(v.$2,
                        color: isSelected
                            ? const Color(0xFF4CAF50)
                            : Colors.white54,
                        size: 32),
                    const SizedBox(height: 8),
                    Text(v.$3,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildField(_plateController, 'Plate Number', Icons.confirmation_num,
            capitalize: TextCapitalization.characters),

        const SizedBox(height: 20),
        // Documents section (placeholder)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1E33),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Required Documents',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildDocRow('Driver\'s License', Icons.credit_card),
              _buildDocRow('Vehicle Photo', Icons.photo_camera),
              _buildDocRow('Government ID', Icons.badge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankStep() {
    return Column(
      key: const ValueKey('bank'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(Icons.account_balance, 'Bank Details',
            'Where should we send your earnings?'),
        const SizedBox(height: 24),
        _buildField(
            _bankNameController, 'Bank Name', Icons.account_balance_outlined),
        const SizedBox(height: 14),
        _buildField(
            _accountNumberController, 'Account Number', Icons.numbers,
            keyboard: TextInputType.number),
        const SizedBox(height: 14),
        _buildField(
            _accountNameController, 'Account Name', Icons.person_outline),
      ],
    );
  }

  Widget _buildHeader(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.08),
            const Color(0xFF00F0FF).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    TextCapitalization capitalize = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        textCapitalization: capitalize,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          hintText: label,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? '$label is required' : null,
      ),
    );
  }

  Widget _buildDocRow(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          GestureDetector(
            onTap: () {
              // TODO: Open file picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File picker coming soon')),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
              ),
              child: const Text('Upload',
                  style: TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_step < 2) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _step++);
      }
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');

      final application = DriverApplicationModel(
        id: '',
        userId: userId,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        vehicleType: _vehicleType,
        vehiclePlate: _plateController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        accountName: _accountNameController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref
          .read(firestoreProvider)
          .collection('driver_applications')
          .add(application.toFirestore());

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
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
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.check,
                    color: Color(0xFF4CAF50), size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Application Submitted!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'We\'ll review your application and get back to you within 24-48 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
