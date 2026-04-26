import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dilivvafast/core/config/app_config.dart';

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

/// Maya — Dilivvafast's AI Support Agent
/// Powered by Claude (Anthropic) API
class MayaChatService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';
  static const int _maxTokens = 1024;

  final List<MayaMessage> _conversationHistory = [];

  List<MayaMessage> get history => List.unmodifiable(_conversationHistory);

  /// System prompt defining Maya's personality and knowledge
  static const String _systemPrompt = '''
You are Maya, the friendly and knowledgeable AI assistant for Dilivvafast — Nigeria's premier on-demand logistics and delivery platform.

Your personality:
- Warm, professional, and empathetic
- You speak naturally with occasional Nigerian English expressions (e.g., "No wahala!", "I dey for you")
- Always helpful and solution-oriented
- Use emojis sparingly but effectively

Your knowledge:
- Dilivvafast offers instant courier, package, and document delivery across Nigerian cities
- Delivery types: Express (1-2 hrs), Standard (same-day), Economy (next-day)
- Payment: Naira via Paystack (cards, bank transfer, USSD), wallet top-up
- Vehicle types: Bike (small packages), Car (medium), Van (large/bulk)
- Drivers are verified with NIN, driver's license, and background checks
- Users can track deliveries in real-time via Mapbox maps
- Rating system: both customers and drivers rate each other (1-5 stars)
- Referral program: Earn ₦500 for each friend who completes first delivery
- Operating hours: 6am - 10pm daily in Lagos, Abuja, Port Harcourt

What you can help with:
1. Tracking deliveries and order status
2. Explaining pricing and fare breakdowns
3. Helping with account issues (password reset, profile update)
4. Filing complaints or reporting issues
5. Explaining how to become a driver
6. Payment and wallet questions
7. Cancellation and refund policies

Important policies:
- Cancellation before driver pickup: Full refund
- Cancellation after pickup: 50% charge
- Damaged items: File claim within 24hrs with photos
- Insurance: Available for items valued above ₦50,000
- Response time SLA: Critical issues within 1 hour, general within 24 hours

Always try to resolve issues yourself. If you truly cannot help (e.g., billing disputes requiring manual review), advise contacting support@dilivvafast.ng or calling +234-800-DELIVER.
''';

  /// Send a message and get Maya's response
  Future<String> sendMessage(String userMessage) async {
    final apiKey = AppConfig.instance.anthropicApiKey;

    if (apiKey.isEmpty) {
      return _getFallbackResponse(userMessage);
    }

    // Add user message to history
    _conversationHistory.add(MayaMessage(
      role: 'user',
      content: userMessage,
    ));

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': _maxTokens,
          'system': _systemPrompt,
          'messages': _conversationHistory
              .map((m) => m.toApiFormat())
              .toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage =
            data['content'][0]['text'] as String;

        // Add assistant response to history
        _conversationHistory.add(MayaMessage(
          role: 'assistant',
          content: assistantMessage,
        ));

        // Keep history manageable (last 20 messages)
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeRange(
              0, _conversationHistory.length - 20);
        }

        return assistantMessage;
      } else {
        debugPrint('Maya API error: ${response.statusCode} ${response.body}');
        return _getFallbackResponse(userMessage);
      }
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
