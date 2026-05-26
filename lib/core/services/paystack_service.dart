import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Conditional import for Paystack (not supported on web)
import 'paystack_stub.dart'
    if (dart.library.io) 'package:flutter_paystack_plus/flutter_paystack_plus.dart';

/// Paystack payment service for handling real payments
class PaystackService {
  static String get publicKey => dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? 'pk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  
  /// Initialize Paystack - call this in main() or splash screen
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('Paystack not supported on web - using mock payment');
      return;
    }
    debugPrint('Paystack initialized with public key');
  }

  /// Charge a card using Paystack checkout
  /// Returns true if payment was successful, false otherwise
  Future<bool> chargeCard({
    required BuildContext context,
    required double amount,
    required String email,
    String? reference,
    String? currency,
    Map<String, dynamic>? metadata,
    void Function(String)? onSuccess,
    void Function(String)? onCancel,
  }) async {
    // Generate unique reference if not provided
    final paymentReference = reference ?? _generateReference();
    
    // Web platform: show mock success (Paystack popup not supported on web)
    if (kIsWeb) {
      debugPrint('Web platform: simulating payment success');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web: Payment simulated (use mobile for real payments)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      onSuccess?.call(paymentReference);
      return true;
    }
    
    // Amount should be in kobo (smallest currency unit)
    // 1 Naira = 100 kobo
    final amountInKobo = (amount * 100).toInt();
    
    bool paymentSuccessful = false;

    try {
      await FlutterPaystackPlus.openPaystackPopup(
        publicKey: publicKey,
        customerEmail: email,
        amount: amountInKobo.toString(),
        reference: paymentReference,
        currency: currency ?? 'NGN',
        metadata: metadata ?? {},
        onClosed: () {
          debugPrint('Paystack popup closed');
          onCancel?.call(paymentReference);
        },
        onSuccess: () {
          debugPrint('Payment successful: $paymentReference');
          paymentSuccessful = true;
          onSuccess?.call(paymentReference);
        },
      );
    } catch (e) {
      debugPrint('Paystack error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return paymentSuccessful;
  }

  /// Verify payment on server-side (should be done via your backend)
  /// This is a placeholder - real verification should happen on your server
  Future<bool> verifyPayment(String reference) async {
    // IMPORTANT: Never verify payments on client-side in production!
    // Always verify transactions on your server using Paystack's API
    // Endpoint: GET https://api.paystack.co/transaction/verify/:reference
    // with Authorization header containing your secret key
    
    debugPrint('Payment verification should be done server-side: $reference');
    return true; // Placeholder
  }

  /// Generate unique payment reference
  String _generateReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'FD_${timestamp}_$random';
  }

  /// Calculate service fee (optional)
  double calculateServiceFee(double amount) {
    // Paystack charges 1.5% + ₦100 (capped at ₦2000)
    final percentageFee = amount * 0.015;
    final flatFee = 100.0;
    final totalFee = percentageFee + flatFee;
    return totalFee > 2000 ? 2000 : totalFee;
  }
  /// Initiate a transfer (withdrawal) to a bank account
  Future<Map<String, dynamic>> initiateTransfer({
    required double amount,
    required String bankCode,
    required String accountNumber,
    required String accountName,
    String? reason,
  }) async {
    // 1. Create Transfer Recipient
    final recipientCode = await _createTransferRecipient(
      name: accountName,
      accountNumber: accountNumber,
      bankCode: bankCode,
    );

    if (recipientCode == null) {
      throw Exception('Failed to create transfer recipient');
    }

    // 2. Initiate Transfer
    final secretKey = dotenv.env['PAYSTACK_SECRET_KEY'];
    if (secretKey == null) {
      throw Exception('Paystack Secret Key not found in .env');
    }

    final url = Uri.parse('https://api.paystack.co/transfer');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'source': 'balance',
        'reason': reason ?? 'Fast Delivery Withdrawal',
        'amount': (amount * 100).toInt(), // Convert to kobo
        'recipient': recipientCode,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == true) {
        return data['data'];
      }
    }

    throw Exception('Transfer failed: ${response.body}');
  }

  /// Create a Transfer Recipient
  Future<String?> _createTransferRecipient({
    required String name,
    required String accountNumber,
    required String bankCode,
  }) async {
    final secretKey = dotenv.env['PAYSTACK_SECRET_KEY'];
    if (secretKey == null) return null;

    final url = Uri.parse('https://api.paystack.co/transferrecipient');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'type': 'nuban',
        'name': name,
        'account_number': accountNumber,
        'bank_code': bankCode,
        'currency': 'NGN',
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == true) {
        return data['data']['recipient_code'];
      }
    }
    
    debugPrint('Create recipient error: ${response.body}');
    return null;
  }

  /// Get the standard Paystack Bank Code for a given bank name.
  /// Supports various formats and common aliases of major Nigerian banks.
  static String? getBankCode(String bankName) {
    final cleanName = bankName.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    
    // Map of common aliases/names to Paystack codes
    final bankMap = {
      // Major Commercial Banks
      'access': '044',
      'accessbank': '044',
      'accessdiamond': '044',
      'diamond': '044',
      
      'gtb': '058',
      'gtbank': '058',
      'guarantytrust': '058',
      'guarantytrustbank': '058',
      
      'zenith': '057',
      'zenithbank': '057',
      
      'uba': '033',
      'unitedbankforafrica': '033',
      
      'firstbank': '011',
      'fbn': '011',
      'firstbankofnigeria': '011',
      
      'union': '032',
      'unionbank': '032',
      
      'fidelity': '070',
      'fidelitybank': '070',
      
      'sterling': '232',
      'sterlingbank': '232',
      
      'stanbic': '221',
      'stanbictbtc': '221',
      'stanbicibtcbank': '221',
      
      'wema': '035',
      'wemabank': '035',
      
      'polaris': '076',
      'polarisbank': '076',
      
      'keystone': '082',
      'keystonebank': '082',
      
      'ecobank': '050',
      'fcmb': '214',
      'firstcitymonumentbank': '214',
      
      'unity': '215',
      'unitybank': '215',
      
      'providus': '101',
      'providusbank': '101',
      
      'titan': '102',
      'titantrust': '102',
      
      'globus': '103',
      'globusbank': '103',
      
      // Fintechs / Neobanks
      'opay': '999992',
      'paycom': '999992',
      
      'palmpay': '999991',
      
      'kuda': '50211',
      'kudamicrofinance': '50211',
      'kudabank': '50211',
      
      'moniepoint': '50515',
      'moniepointmfb': '50515',
      
      'fairmoney': '51318',
      'vfd': '566',
      'vfdmicrofinance': '566',
      
      'rubies': '125',
      'carbon': '565',
    };

    // Look for exact match first
    if (bankMap.containsKey(cleanName)) {
      return bankMap[cleanName];
    }

    // Fallback: look for partial matches (e.g. if user types "Access Bank PLC")
    for (var entry in bankMap.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        return entry.value;
      }
    }

    return null; // Return null if not found
  }
}
