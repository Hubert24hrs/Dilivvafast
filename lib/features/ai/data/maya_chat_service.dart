import 'package:dilivvafast/core/constants/app_constants.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Message model for Maya chat
class MayaMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  MayaMessage({required this.role, required this.content, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toApiFormat() => {'role': role, 'content': content};
}

/// Maya — Dilivvafast's AI Support Agent
/// Powered by Claude (Anthropic) API
class MayaChatService {
  MayaChatService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  // Model choice and token budget now live server-side in the askMaya
  // Cloud Function, so they can be changed without shipping a new build.
  final List<MayaMessage> _conversationHistory = [];

  List<MayaMessage> get history => List.unmodifiable(_conversationHistory);

  /// System prompt defining Maya's personality and knowledge
  static const String _systemPrompt =
      '''
You are Maya, the friendly and knowledgeable AI assistant for Dilivvafast — Nigeria's premier on-demand logistics and delivery platform.

Your personality:
- Warm, professional, and empathetic
- You speak naturally with occasional Nigerian English expressions (e.g., "No wahala!", "I dey for you")
- Always helpful and solution-oriented
- Use emojis sparingly but effectively

Your knowledge:
- Dilivvafast offers instant courier, package, and document delivery across Nigerian cities
- Delivery types: Express (1-2 hrs), Standard (same-day), Economy (next-day)
- Payment: customers pay their courier directly after delivery, in cash or by bank transfer to the courier's own account (shown on the delivery screen). There is no wallet and no card payment in the app.
- Vehicle types: Bike (small packages), Car (medium), Van (large/bulk)
- Drivers are verified with NIN, driver's license, and background checks
- Users can track deliveries in real-time on Google Maps
- Rating system: both customers and drivers rate each other (1-5 stars)
- Invite friends: share your code from Invite friends in the menu (no cash reward)
- Operating hours: 6am - 10pm daily in Lagos, Abuja, Port Harcourt

What you can help with:
1. Tracking deliveries and order status
2. Explaining pricing and fare breakdowns
3. Helping with account issues (password reset, profile update)
4. Filing complaints or reporting issues
5. Explaining how to become a driver
6. Payment questions (cash or bank transfer to the courier)
7. Cancellation and refund policies

Important policies:
- Cancellation before driver pickup: Full refund
- Cancellation after pickup: 50% charge
- Damaged items: File claim within 24hrs with photos
- Insurance: Available for items valued above ₦50,000
- Response time SLA: Critical issues within 1 hour, general within 24 hours

Always try to resolve issues yourself. If you truly cannot help (e.g., billing disputes requiring manual review), advise emailing ${AppConstants.supportEmail} or using Message support in the Help Centre.
''';

  /// Send a message and get Maya's response.
  ///
  /// The Anthropic key used to be read from `.env` and sent straight from the
  /// handset in an `x-api-key` header, which meant it shipped inside the APK
  /// and could be lifted by anyone who unzipped the bundle. The call now goes
  /// through the `askMaya` Cloud Function: the key lives in Secret Manager,
  /// never reaches the device, and the endpoint is rate-limited per user.
  Future<String> sendMessage(String userMessage) async {
    // Add user message to history
    _conversationHistory.add(MayaMessage(role: 'user', content: userMessage));

    try {
      final callable = _functions.httpsCallable('askMaya');
      final result = await callable.call<Map<String, dynamic>>({
        'system': _systemPrompt,
        'messages': _conversationHistory.map((m) => m.toApiFormat()).toList(),
      });

      final assistantMessage = result.data['reply'] as String?;
      if (assistantMessage == null || assistantMessage.isEmpty) {
        return _getFallbackResponse(userMessage);
      }

      _conversationHistory.add(
        MayaMessage(role: 'assistant', content: assistantMessage),
      );

      // Keep history manageable (last 20 messages) — also the cap the
      // backend enforces on the request it will accept.
      if (_conversationHistory.length > 20) {
        _conversationHistory.removeRange(0, _conversationHistory.length - 20);
      }

      return assistantMessage;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        return 'I am handling a lot of questions right now — please try '
            'again in a few minutes, or email ${AppConstants.supportEmail}.';
      }
      debugPrint('Maya chat error: ${e.code}');
      return _getFallbackResponse(userMessage);
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
    if (lower.contains('price') ||
        lower.contains('cost') ||
        lower.contains('fare') ||
        lower.contains('how much')) {
      return "💰 Delivery pricing depends on:\n• **Distance** between pickup and dropoff\n• **Vehicle type** (Bike, Car, or Van)\n• **Delivery speed** (Express, Standard, Economy)\n\nYou can get an instant quote by entering your pickup and dropoff addresses in the booking screen!";
    }
    if (lower.contains('cancel')) {
      return "❌ **Cancellation Policy:**\n• Before driver pickup → Full refund\n• After pickup → 50% charge applies\n\nTo cancel, go to **Orders → Active Order → Cancel Order**.";
    }
    if (lower.contains('driver') || lower.contains('become')) {
      return "🚗 **Want to drive with Dilivvafast?**\n\nRequirements:\n1. Valid Nigerian driver's license\n2. NIN verification\n3. Own a bike, car, or van\n4. Smartphone with data plan\n5. Pass background check\n\nApply in the app: **Profile → Become a Driver**!";
    }
    if (lower.contains('payment') ||
        lower.contains('wallet') ||
        lower.contains('pay')) {
      return "💳 **How you pay:**\nYou pay your courier directly once your package is delivered:\n• **Cash** — hand it over at the door\n• **Bank transfer** — to your courier's account, shown on your delivery screen. Tap **I've sent** after transferring.\n\nThere's no wallet or card payment in the app.";
    }
    if (lower.contains('refund')) {
      return "💵 Payments go straight to your courier, so Dilivvafast can't refund them directly. If something went wrong, contact us at ${AppConstants.supportEmail} and we'll help sort it out with your courier.";
    }
    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('hey')) {
      return "Hey there! 👋 I'm Maya, your Dilivvafast assistant. How can I help you today?\n\nI can help with:\n• 📦 Tracking deliveries\n• 💰 Pricing questions\n• ❌ Cancellations & refunds\n• 🚗 Becoming a driver\n• 💳 Payment issues";
    }

    return "Thanks for reaching out! 😊 I'm Maya, and I'm here to help.\n\nCould you give me a bit more detail about what you need? I can assist with tracking, pricing, payments, cancellations, or any other delivery questions.\n\nFor urgent issues, email **${AppConstants.supportEmail}** or tap **Message support** in the Help Centre.";
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
