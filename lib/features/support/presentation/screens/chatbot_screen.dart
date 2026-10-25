import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dilivvafast/core/constants/app_constants.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/features/ai/data/maya_chat_service.dart';

/// Chat message model for display
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isTyping = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  final MayaChatService _mayaService = MayaChatService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text:
            'Hey there! 👋 I\'m **Maya**, your Dilivvafast assistant.\n\nHow can I help you today? You can ask me about tracking, pricing, payments, or anything else!',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userText = text.trim();
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: userText, isUser: true));
      _isLoading = true;
      // Add typing indicator
      _messages.add(_ChatMessage(text: '', isUser: false, isTyping: true));
    });
    _scrollToBottom();

    try {
      final response = await _mayaService.sendMessage(userText);

      // A network round-trip to the assistant takes seconds; the user may well
      // have left the screen before it returns.
      if (!mounted) return;
      setState(() {
        // Remove typing indicator
        _messages.removeWhere((m) => m.isTyping);
        _messages.add(_ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Chatbot send failed: $e');
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _messages.add(
          _ChatMessage(
            text:
                'Oops! Something went wrong. Please try again or contact '
                '${AppConstants.supportEmail} 📧',
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      // The delay outlives the screen if the user backs out immediately;
      // touching the controller after dispose throws.
      if (!mounted) return;
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
    final quickReplies = _mayaService.getQuickReplies();

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message)
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: 0.1, end: 0, duration: 200.ms);
              },
            ),
          ),

          // Quick reply chips
          if (!_isLoading) _buildQuickReplies(quickReplies),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.palette.surfaceBase,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: context.palette.brand.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(
              Icons.support_agent,
              color: context.palette.onBrand,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Maya',
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.palette.success,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI Assistant • Online',
                    style: TextStyle(
                      color: context.palette.success,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: context.palette.textSecondary,
            size: 20,
          ),
          tooltip: 'Clear chat',
          onPressed: () {
            _mayaService.clearHistory();
            setState(() {
              _messages.clear();
              _messages.add(
                _ChatMessage(
                  text: 'Chat cleared! 🧹 How can I help you?',
                  isUser: false,
                ),
              );
            });
          },
        ),
        TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Connecting to human agent...'),
                backgroundColor: context.palette.brand,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          icon: Icon(Icons.headset_mic, color: context.palette.brand, size: 16),
          label: Text(
            'Escalate',
            style: TextStyle(color: context.palette.brand, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    if (message.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: context.palette.surfaceRaised,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: context.palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypingDot(0),
              _buildTypingDot(1),
              _buildTypingDot(2),
            ],
          ),
        ),
      );
    }

    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? context.palette.brand.withValues(alpha: 0.12)
              : context.palette.surfaceRaised,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
            color: isUser
                ? context.palette.brand.withValues(alpha: 0.25)
                : context.palette.border,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser
                ? context.palette.brand
                : context.palette.textSecondary,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(Icons.circle, size: 6, color: context.palette.textMuted),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(
          delay: Duration(milliseconds: index * 200),
          duration: 400.ms,
        )
        .slideY(begin: 0, end: -0.3, duration: 400.ms);
  }

  Widget _buildQuickReplies(List<String> quickReplies) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => ActionChip(
          label: Text(
            quickReplies[index],
            style: TextStyle(color: context.palette.brand, fontSize: 11.5),
          ),
          backgroundColor: context.palette.brand.withValues(alpha: 0.08),
          side: BorderSide(color: context.palette.brand.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onPressed: () => _sendMessage(quickReplies[index]),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        10,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        border: Border(top: BorderSide(color: context.palette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Ask Maya anything...',
                hintStyle: TextStyle(
                  color: context.palette.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              onSubmitted: _sendMessage,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isLoading ? null : AppTheme.primaryGradient,
              color: _isLoading ? context.palette.border : null,
              boxShadow: _isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: context.palette.brand.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
            ),
            child: IconButton(
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.palette.textSecondary,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: context.palette.textPrimary,
                      size: 18,
                    ),
              onPressed: _isLoading
                  ? null
                  : () => _sendMessage(_controller.text),
            ),
          ),
        ],
      ),
    );
  }
}
