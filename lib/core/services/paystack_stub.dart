// Stub file for Paystack on web platform
// This file provides empty implementations for web where Paystack is not supported

/// Stub class for FlutterPaystackPlus on web
class FlutterPaystackPlus {
  static Future<void> openPaystackPopup({
    required String publicKey,
    required String customerEmail,
    required String amount,
    required String reference,
    String? currency,
    Map<String, dynamic>? metadata,
    void Function()? onClosed,
    void Function()? onSuccess,
  }) async {
    // Web stub - does nothing, kIsWeb check handles this before calling
  }
}
