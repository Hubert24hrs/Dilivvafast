import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Message model for Maya chat
class MayaMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  MayaMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toApiFormat() => {
        'role': role,
        'content': content,
      };
}

/// Maya — Dilivvafast's AI support agent.
///
/// Backed by Claude through the `mayaChat` Cloud Function. The model choice and
/// system prompt live server-side (see `functions/src/index.ts`) so they can be
/// changed without shipping a new app build.
class MayaChatService {
  MayaChatService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  final List<MayaMessage> _conversationHistory = [];

  List<MayaMessage> get history => List.unmodifiable(_conversationHistory);


  /// Send a message and get Maya's response.
  ///
  /// The Anthropic API key lives in Cloud Functions secrets, so the app talks
  /// to the `mayaChat` callable rather than to Anthropic directly. If that call
  /// fails for any reason we fall back to canned answers so support chat still
  /// does something useful offline.
  Future<String> sendMessage(String userMessage) async {
    _conversationHistory.add(MayaMessage(role: 'user', content: userMessage));

    try {
      final callable = _functions.httpsCallable('mayaChat');
      final result = await callable.call<Map<String, dynamic>>({
        'messages': _conversationHistory.map((m) => m.toApiFormat()).toList(),
      });

      final reply = (result.data['reply'] as String?)?.trim();
      if (reply == null || reply.isEmpty) {
        return _getFallbackResponse(userMessage);
      }

      _conversationHistory.add(MayaMessage(role: 'assistant', content: reply));

      // Keep history manageable (last 20 messages)
      if (_conversationHistory.length > 20) {
        _conversationHistory.removeRange(0, _conversationHistory.length - 20);
      }

      return reply;
    } catch (e) {
      debugPrint('Maya chat error: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  /// Fallback responses when API is unavailable
  String _getFallbackResponse(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('track') || lower.contains('where')) {
      return "📦 To track your delivery, go to the **Orders** tab and tap on your active order. You'll see real-time location updates on the map!\n\nIf you have a tracking code, enter it in the search bar on the home screen.";
    }
    if (lower.contains('price') || lower.contains('cost') || lower.contains('fare') || lower.contains('how much')) {
      return "💰 Delivery pricing depends on:\n• **Distance** between pickup and dropoff\n• **Vehicle type** (Bike, Car, or Van)\n• **Delivery speed** (Express, Standard, Economy)\n\nYou can get an instant quote by entering your pickup and dropoff addresses in the booking screen!";
    }
    if (lower.contains('cancel')) {
      return "❌ **Cancellation Policy:**\n• Before driver pickup → Full refund\n• After pickup → 50% charge applies\n\nTo cancel, go to **Orders → Active Order → Cancel Order**.";
    }
    if (lower.contains('driver') || lower.contains('become')) {
      return "🚗 **Want to drive with Dilivvafast?**\n\nRequirements:\n1. Valid Nigerian driver's license\n2. NIN verification\n3. Own a bike, car, or van\n4. Smartphone with data plan\n5. Pass background check\n\nApply in the app: **Profile → Become a Driver**!";
    }
    if (lower.contains('payment') || lower.contains('wallet') || lower.contains('pay')) {
      return "💳 **Payment Options:**\n• Debit/Credit card (Visa, Mastercard)\n• Bank transfer\n• USSD payment\n• Wallet balance\n\nTop up your wallet: **Profile → Wallet → Top Up**\n\nAll payments are processed securely via Paystack.";
    }
    if (lower.contains('refund')) {
      return "💵 Refunds are processed within 3-5 business days to your original payment method. For wallet payments, refunds are instant.\n\nIf you haven't received your refund, contact support@dilivvafast.ng.";
    }
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return "Hey there! 👋 I'm Maya, your Dilivvafast assistant. How can I help you today?\n\nI can help with:\n• 📦 Tracking deliveries\n• 💰 Pricing questions\n• ❌ Cancellations & refunds\n• 🚗 Becoming a driver\n• 💳 Payment issues";
    }

    return "Thanks for reaching out! 😊 I'm Maya, and I'm here to help.\n\nCould you give me a bit more detail about what you need? I can assist with tracking, pricing, payments, cancellations, or any other delivery questions.\n\nFor urgent issues, email **support@dilivvafast.ng** or call **+234-800-DELIVER**.";
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Get quick reply suggestions based on context
  List<String> getQuickReplies() {
    if (_conversationHistory.isEmpty) {
      return [
        '📦 Track my order',
        '💰 How much does delivery cost?',
        '🚗 How do I become a driver?',
        '💳 Payment help',
      ];
    }

    final lastMessage = _conversationHistory.last.content.toLowerCase();

    if (lastMessage.contains('track') || lastMessage.contains('order')) {
      return [
        '📍 Where is my package?',
        '⏰ When will it arrive?',
        '❌ Cancel this order',
      ];
    }
    if (lastMessage.contains('price') || lastMessage.contains('cost')) {
      return [
        '🏍️ Bike delivery price',
        '🚗 Car delivery price',
        '🚐 Van delivery price',
      ];
    }

    return [
      '📦 Track my order',
      '💰 Pricing',
      '❌ Cancel order',
      '📞 Contact support',
    ];
  }
}
