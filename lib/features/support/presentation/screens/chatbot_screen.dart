import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Simple FAQ data model
class _FaqItem {
  final String question;
  final String answer;
  _FaqItem(this.question, this.answer);
}

/// Chat message model
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  _ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  static final List<_FaqItem> _faqs = [
    _FaqItem(
        'How do I track my delivery?',
        'You can track your delivery in real-time from the "My Orders" tab. '
            'Tap on any active order to see the live location of your rider.'),
    _FaqItem(
        'What are the delivery charges?',
        'Delivery charges are calculated based on distance, package weight, '
            'and the zone. You can see the fare breakdown before confirming your booking.'),
    _FaqItem(
        'How do I fund my wallet?',
        'Go to your Wallet, tap "Fund Wallet", select an amount, and complete '
            'the payment via Paystack. Your balance updates instantly.'),
    _FaqItem(
        'How do I become a driver?',
        'Tap the menu and select "Become a Driver". Fill out the application '
            'form with your details and documents. Our team will review and approve your application.'),
    _FaqItem(
        'How do I cancel an order?',
        'You can cancel an order before a driver picks it up. Go to "My Orders", '
            'select the order, and tap "Cancel". Note: cancellation fees may apply.'),
    _FaqItem(
        'What is the referral program?',
        'Share your referral code with friends. When they sign up and complete '
            'their first delivery, you both earn a ₦500 bonus!'),
    _FaqItem(
        'How long does delivery take?',
        'Delivery times depend on distance and traffic conditions. Estimated '
            'time is shown when you book. Most intra-city deliveries take 30-90 minutes.'),
    _FaqItem(
        'How do I contact support?',
        'You\'re already here! Type your question below or tap a suggested topic. '
            'For urgent issues, call us at 0800-DILIVVA.'),
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(_ChatMessage(
      text: 'Hello! 👋 I\'m your Dilivvafast assistant. How can I help you today?',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _controller.clear();

    // Find matching FAQ
    Future.delayed(const Duration(milliseconds: 500), () {
      final response = _findAnswer(text);
      setState(() {
        _messages.add(_ChatMessage(text: response, isUser: false));
      });
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  String _findAnswer(String query) {
    final lower = query.toLowerCase();

    // Check FAQs for keyword matches
    for (final faq in _faqs) {
      final keywords = faq.question.toLowerCase().split(' ');
      final matchCount =
          keywords.where((k) => k.length > 3 && lower.contains(k)).length;
      if (matchCount >= 2) return faq.answer;
    }

    // Keyword-based fallbacks
    if (lower.contains('track')) return _faqs[0].answer;
    if (lower.contains('charge') || lower.contains('price') || lower.contains('fare')) {
      return _faqs[1].answer;
    }
    if (lower.contains('fund') || lower.contains('wallet') || lower.contains('pay')) {
      return _faqs[2].answer;
    }
    if (lower.contains('driver') || lower.contains('rider')) return _faqs[3].answer;
    if (lower.contains('cancel')) return _faqs[4].answer;
    if (lower.contains('refer')) return _faqs[5].answer;
    if (lower.contains('time') || lower.contains('long')) return _faqs[6].answer;
    if (lower.contains('help') || lower.contains('support')) return _faqs[7].answer;

    return 'I\'m not sure about that. Would you like to speak with a human agent? '
        'Tap the "Escalate" button below to connect with our support team.';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.smart_toy,
                  color: Color(0xFF00F0FF), size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support Bot',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
                Text('Online',
                    style:
                        TextStyle(color: Color(0xFF4CAF50), fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Connecting to human agent...'),
                    backgroundColor: Color(0xFFFF9800)),
              );
            },
            icon: const Icon(Icons.headset_mic,
                color: Color(0xFFFF9800), size: 16),
            label: const Text('Escalate',
                style: TextStyle(color: Color(0xFFFF9800), fontSize: 11)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index]),
            ),
          ),

          // Quick reply chips (only show at start)
          if (_messages.length <= 2) _buildQuickReplies(),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
              : const Color(0xFF1D1E33),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: message.isUser
                ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                : Colors.white10,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color:
                message.isUser ? const Color(0xFF00F0FF) : Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    final suggestions = [
      'Track my delivery',
      'Delivery charges',
      'Fund wallet',
      'Become a driver',
      'Referral program',
    ];

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => ActionChip(
          label: Text(suggestions[index],
              style: const TextStyle(
                  color: Color(0xFF00F0FF), fontSize: 11)),
          backgroundColor:
              const Color(0xFF00F0FF).withValues(alpha: 0.08),
          side: BorderSide(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.2)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onPressed: () => _sendMessage(suggestions[index]),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 8, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1D1E33),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00F0FF),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF0A0E21), size: 18),
              onPressed: () => _sendMessage(_controller.text),
            ),
          ),
        ],
      ),
    );
  }
}
