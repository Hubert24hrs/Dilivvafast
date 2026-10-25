import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/utils/friendly_error.dart';
import 'package:dilivvafast/core/providers/providers.dart';

/// A customer's conversation with support, at `orders/support_{uid}`.
///
/// Customers open their own thread. An admin opens a customer's thread from
/// the support inbox by passing [userId], and replies as Support;
/// `onSupportMessageCreated` notifies whichever side has to answer next.
class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key, this.userId});

  /// The customer whose thread to show. Null means the signed-in user's own.
  final String? userId;

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  bool get _asSupport => widget.userId != null;

  Future<void> _sendMessage(String threadId) async {
    final text = _msgCtrl.text.trim();
    final uid = ref.read(currentUserIdProvider);
    if (text.isEmpty || uid == null || _sending) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(firestoreProvider)
          .collection('orders')
          .doc(threadId)
          .collection('messages')
          .add({
            'senderId': uid,
            'senderName': _asSupport ? 'Support' : 'Customer',
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          });
      // Cleared only once it is stored; this used to clear first, so a
      // failed send silently threw the message away.
      _msgCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: context.palette.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserIdProvider);
    final threadId = 'support_${widget.userId ?? uid ?? 'guest'}';

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: Text(_asSupport ? 'Support conversation' : 'Chat with Support'),
        backgroundColor: context.palette.surfaceRaised,
      ),
      body: Column(
        children: [
          Expanded(
            child: uid == null
                ? const Center(child: Text('Please log in'))
                : StreamBuilder<QuerySnapshot>(
                    stream: ref
                        .watch(firestoreProvider)
                        .collection('orders')
                        .doc(threadId)
                        .collection('messages')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            friendlyError(snapshot.error!),
                            style: TextStyle(
                              color: context.palette.textSecondary,
                            ),
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: context.palette.brand,
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 64,
                                  color: context.palette.textMuted,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'How can we help you today?',
                                  style: TextStyle(
                                    color: context.palette.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Send a message below and a Dilivvafast support agent will respond shortly.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: context.palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final senderId = data['senderId'] ?? '';
                          final isMe = senderId == uid;
                          final text = data['text'] ?? '';

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? context.palette.brand
                                    : context.palette.surfaceRaised,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: isMe
                                      ? context.palette.onBrand
                                      : context.palette.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: context.palette.surfaceRaised,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: TextStyle(color: context.palette.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(threadId),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send',
                    icon: Icon(Icons.send, color: context.palette.brand),
                    onPressed: _sending ? null : () => _sendMessage(threadId),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
