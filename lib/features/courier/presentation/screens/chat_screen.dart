import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/chat_message_model.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// Streams chat messages for a specific order
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessageModel>, String>((ref, orderId) {
  return ref
      .watch(firestoreProvider)
      .collection('couriers')
      .doc(orderId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => ChatMessageModel.fromFirestore(d)).toList());
});

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userId = ref.read(currentUserIdProvider);
    final user = ref.read(currentUserProvider).value;
    if (userId == null) return;

    _controller.clear();

    try {
      await ref
          .read(firestoreProvider)
          .collection('couriers')
          .doc(widget.orderId)
          .collection('messages')
          .add(ChatMessageModel(
            id: '',
            senderId: userId,
            senderRole: user?.role.name ?? 'customer',
            text: text,
            timestamp: DateTime.now(),
          ).toFirestore());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.orderId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat',
                style: TextStyle(color: context.palette.textPrimary, fontSize: 16)),
            Text('Order: ${widget.orderId.substring(0, 8)}...',
                style: TextStyle(color: context.palette.textMuted, fontSize: 11)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: context.palette.textMuted),
                        const SizedBox(height: 12),
                        Text('No messages yet',
                            style: TextStyle(color: context.palette.textMuted)),
                        const SizedBox(height: 4),
                        Text('Start the conversation!',
                            style:
                                TextStyle(color: context.palette.textMuted, fontSize: 12)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) =>
                      _buildBubble(messages[i], currentUserId),
                );
              },
              loading: () => Center(
                child:
                    CircularProgressIndicator(color: context.palette.brand),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: TextStyle(color: context.palette.danger)),
              ),
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.palette.surfaceRaised,
              border: Border(
                  top: BorderSide(
                      color: context.palette.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.palette.surfaceBase,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(
                            color: context.palette.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                              color: context.palette.textMuted),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.palette.brand,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send,
                          color: context.palette.surfaceBase, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessageModel msg, String? currentUserId) {
    final isMine = msg.senderId == currentUserId;
    final time = _formatTime(msg.timestamp);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine
              ? context.palette.brand.withValues(alpha: 0.15)
              : context.palette.surfaceRaised,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: Border.all(
            color: isMine
                ? context.palette.brand.withValues(alpha: 0.3)
                : context.palette.border,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Text(
                msg.senderRole.toUpperCase(),
                style: TextStyle(
                  color: context.palette.brand.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(color: context.palette.onBrand, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(
                color: context.palette.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
