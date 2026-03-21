import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/features/courier/domain/entities/chat_message_model.dart';

/// Streams chat messages for a specific order
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessageModel>, String>((ref, orderId) {
  return ref
      .watch(firestoreProvider)
      .collection('orders')
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
          .collection('orders')
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
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('Order: ${widget.orderId.substring(0, 8)}...',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
                            color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),
                        const Text('No messages yet',
                            style: TextStyle(color: Colors.white38)),
                        const SizedBox(height: 4),
                        const Text('Start the conversation!',
                            style:
                                TextStyle(color: Colors.white24, fontSize: 12)),
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
              loading: () => const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFF00F0FF)),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E21),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3)),
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00F0FF),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send,
                          color: Color(0xFF0A0E21), size: 20),
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
              ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
              : const Color(0xFF1D1E33),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: Border.all(
            color: isMine
                ? const Color(0xFF00F0FF).withValues(alpha: 0.3)
                : Colors.white12,
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
                  color: const Color(0xFFFF00AA).withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
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
