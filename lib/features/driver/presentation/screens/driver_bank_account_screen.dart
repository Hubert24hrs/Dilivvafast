import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/domain/entities/bank_account.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _field = Color(0xFFF3F4F6);
const _lime = Color(0xFFC1F11D);

/// Banks and fintechs couriers commonly use, for the picker. Anything else
/// can still be saved — an account from the application keeps its own name.
const nigerianBanks = [
  'Access Bank',
  'Citibank',
  'Ecobank',
  'Fidelity Bank',
  'First Bank',
  'FCMB',
  'Globus Bank',
  'GTBank',
  'Heritage Bank',
  'Jaiz Bank',
  'Keystone Bank',
  'Kuda',
  'Moniepoint',
  'OPay',
  'PalmPay',
  'Parallex Bank',
  'Polaris Bank',
  'Providus Bank',
  'Stanbic IBTC',
  'Standard Chartered',
  'Sterling Bank',
  'SunTrust Bank',
  'Titan Trust Bank',
  'Union Bank',
  'UBA',
  'Unity Bank',
  'VFD Microfinance Bank',
  'Wema Bank',
  'Zenith Bank',
];

/// The account customers pay this courier into by bank transfer.
///
/// Saved on the courier's own profile; the server copies it onto an order
/// only when the customer accepts this courier's offer.
class DriverBankAccountScreen extends ConsumerStatefulWidget {
  const DriverBankAccountScreen({super.key});

  @override
  ConsumerState<DriverBankAccountScreen> createState() =>
      _DriverBankAccountScreenState();
}

class _DriverBankAccountScreenState
    extends ConsumerState<DriverBankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _name = TextEditingController();
  String? _bank;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  void _prefill(BankAccount? account) {
    if (_loaded) return;
    _loaded = true;
    if (account == null) return;
    _bank = account.bankName.isEmpty ? null : account.bankName;
    _number.text = account.accountNumber;
    _name.text = account.accountName;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final account = BankAccount(
      bankName: _bank!,
      accountNumber: _number.text.trim(),
      accountName: _name.text.trim(),
    );
    setState(() => _saving = true);
    final result = await ref.read(userRepositoryProvider).updateUser(uid, {
      'payoutAccount': account.toMap(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not save your bank account. Try again.'),
          backgroundColor: context.palette.danger,
        ),
      ),
      (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bank account saved')));
        if (context.canPop()) context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user != null) _prefill(user.payoutAccount);

    final banks = [
      ...nigerianBanks,
      if (_bank != null && !nigerianBanks.contains(_bank)) _bank!,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _ink,
        title: const Text(
          'Bank account',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: _ink,
                disabledBackgroundColor: _field,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: _ink,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Save bank account'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7DC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: _ink),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Customers pay you directly after each delivery — in '
                        'cash, or by bank transfer to this account. Only the '
                        'customer of a delivery you are doing can see it.',
                        style: TextStyle(color: _ink, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _bank,
                isExpanded: true,
                decoration: _decoration('Bank'),
                items: [
                  for (final b in banks)
                    DropdownMenuItem(value: b, child: Text(b)),
                ],
                onChanged: (v) => setState(() => _bank = v),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Choose your bank' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: _decoration('Account number (10 digits)'),
                validator: (v) => BankAccount.isValidAccountNumber(v ?? '')
                    ? null
                    : 'Enter your 10-digit account number',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 80,
                decoration: _decoration('Account name'),
                validator: (v) => (v ?? '').trim().length < 3
                    ? 'Enter the name on the account'
                    : null,
              ),
              const SizedBox(height: 4),
              const Text(
                'Use an account in your own name, so customers can check who '
                'they are paying.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: _field,
    counterText: '',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}
