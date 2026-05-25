import 'package:fast_delivery/core/models/chat_message_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? rideId;
  final String? otherUserName;

  const ChatScreen({
    super.key,
    this.rideId,
    this.otherUserName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;

    final message = ChatMessageModel(
      id: '', // Firestore will generate ID
      senderId: currentUser.uid,
      text: text,
      timestamp: DateTime.now(),
    );

    _messageController.clear();

    try {
      await ref.read(databaseServiceProvider).sendMessage(widget.rideId!, message);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e', style: const TextStyle(color: Colors.white))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle missing rideId
    if (widget.rideId == null || widget.rideId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.white54),
                SizedBox(height: 16),
                Text(
                  'Invalid chat session',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final messagesStream = ref.watch(databaseServiceProvider).getMessagesStream(widget.rideId!);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.otherUserName ?? 'Chat', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassCard(
            borderRadius: 50,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const BackgroundOrbs(),
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: Column(
              children: [
                Expanded(
              child: StreamBuilder<List<ChatMessageModel>>(
                stream: messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          const Text(
                            'Start the conversation',
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        ],
                      ).animate().fadeIn(),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 110, 16, 16), // Top padding for app bar
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
            
            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GlassCard(
                       color: Colors.white.withValues(alpha: 0.05),
                       borderRadius: 25,
                       child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GlassCard(
                    borderRadius: 50,
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send_rounded),
                      color: AppTheme.primaryColor,
                      tooltip: 'Send',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe 
                    ? LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.white10, Colors.white.withValues(alpha: 0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: Border.all(
                  color: isMe ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                   BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                   )
                ]
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.black : Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}
