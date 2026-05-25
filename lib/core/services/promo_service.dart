import 'package:cloud_firestore/cloud_firestore.dart';

class PromoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Available promo codes (in production, these would come from Firestore)
  static const Map<String, Map<String, dynamic>> _promoCodes = {
    'WELCOME50': {'discount': 0.5, 'maxDiscount': 500.0, 'type': 'percentage', 'description': '50% off first ride', 'minOrder': 0.0},
    'FAST20': {'discount': 20.0, 'maxDiscount': 20.0, 'type': 'fixed', 'description': '₦20 off any ride', 'minOrder': 100.0},
    'COURIER100': {'discount': 100.0, 'maxDiscount': 100.0, 'type': 'fixed', 'description': '₦100 off courier', 'minOrder': 500.0},
    'NEWUSER': {'discount': 0.25, 'maxDiscount': 300.0, 'type': 'percentage', 'description': '25% off (max ₦300)', 'minOrder': 0.0},
  };

  // Validate and apply a promo code
  Future<PromoResult> validatePromoCode(String code, String userId, double orderAmount) async {
    final upperCode = code.toUpperCase().trim();
    
    if (!_promoCodes.containsKey(upperCode)) {
      return PromoResult(success: false, message: 'Invalid promo code');
    }

    // Check if user already used this code
    final usedDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('usedPromos')
        .doc(upperCode)
        .get();

    if (usedDoc.exists) {
      return PromoResult(success: false, message: 'You have already used this promo code');
    }

    final promo = _promoCodes[upperCode]!;
    final minOrder = promo['minOrder'] as double;

    if (orderAmount < minOrder) {
      return PromoResult(
        success: false, 
        message: 'Minimum order of ₦${minOrder.toStringAsFixed(0)} required',
      );
    }

    // Calculate discount
    double discountAmount;
    if (promo['type'] == 'percentage') {
      discountAmount = orderAmount * (promo['discount'] as double);
      final maxDiscount = promo['maxDiscount'] as double;
      if (discountAmount > maxDiscount) {
        discountAmount = maxDiscount;
      }
    } else {
      discountAmount = promo['discount'] as double;
    }

    return PromoResult(
      success: true,
      message: 'Promo applied: ${promo['description']}',
      discountAmount: discountAmount,
      promoCode: upperCode,
    );
  }

  // Mark promo as used
  Future<void> markPromoAsUsed(String userId, String promoCode) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('usedPromos')
        .doc(promoCode.toUpperCase())
        .set({
      'usedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get list of available promos
  List<Map<String, dynamic>> getAvailablePromos() {
    return _promoCodes.entries.map((e) => {
      'code': e.key,
      ...e.value,
    }).toList();
  }
}

class PromoResult {
  final bool success;
  final String message;
  final double discountAmount;
  final String? promoCode;

  PromoResult({
    required this.success,
    required this.message,
    this.discountAmount = 0.0,
    this.promoCode,
  });
}
