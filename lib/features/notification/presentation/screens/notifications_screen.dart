import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/domain/entities/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(ref),
            child: const Text('Mark all read',
                style: TextStyle(color: Color(0xFF00F0FF), fontSize: 12)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 56,
                      color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 12),
                  const Text('No notifications yet',
                      style: TextStyle(color: Colors.white38, fontSize: 15)),
                ],
              ),
            );
          }

          // Group by date
          final grouped = _groupByDate(notifications);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: grouped.length,
            itemBuilder: (_, i) {
              final group = grouped[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i == 0 || grouped[i].dateLabel != grouped[i - 1].dateLabel)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        group.dateLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _buildNotificationTile(ref, group.notification),
                ],
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
        ),
        error: (e, _) => Center(
          child:
              Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(WidgetRef ref, NotificationModel n) {
    final icon = _iconForType(n.type);
    final color = _colorForType(n.type);

    return GestureDetector(
      onTap: () => _markRead(ref, n),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead
              ? const Color(0xFF1D1E33)
              : const Color(0xFF1D1E33).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.isRead ? Colors.white12 : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                                n.isRead ? FontWeight.w400 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(n.createdAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_GroupedNotification> _groupByDate(List<NotificationModel> items) {
    final now = DateTime.now();
    return items.map((n) {
      final diff = now.difference(n.createdAt);
      String label;
      if (diff.inDays == 0) {
        label = 'Today';
      } else if (diff.inDays == 1) {
        label = 'Yesterday';
      } else if (diff.inDays < 7) {
        label = '${diff.inDays} days ago';
      } else {
        label = 'Earlier';
      }
      return _GroupedNotification(dateLabel: label, notification: n);
    }).toList();
  }

  IconData _iconForType(NotificationType type) {
    return switch (type) {
      NotificationType.orderUpdate => Icons.local_shipping,
      NotificationType.driverAssigned => Icons.person_pin,
      NotificationType.deliveryComplete => Icons.check_circle,
      NotificationType.payment => Icons.payment,
      NotificationType.promo => Icons.local_offer,
      NotificationType.system => Icons.info,
    };
  }

  Color _colorForType(NotificationType type) {
    return switch (type) {
      NotificationType.orderUpdate => const Color(0xFF00F0FF),
      NotificationType.driverAssigned => const Color(0xFF4CAF50),
      NotificationType.deliveryComplete => const Color(0xFF4CAF50),
      NotificationType.payment => const Color(0xFFFF9800),
      NotificationType.promo => const Color(0xFFFF00AA),
      NotificationType.system => const Color(0xFF90CAF9),
    };
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _markRead(WidgetRef ref, NotificationModel n) async {
    if (n.isRead) return;
    await ref
        .read(firestoreProvider)
        .collection('notifications')
        .doc(n.id)
        .update({'isRead': true});
  }

  Future<void> _markAllRead(WidgetRef ref) async {
    final notifications = ref.read(notificationsProvider).value ?? [];
    final unread = notifications.where((n) => !n.isRead);
    final batch = ref.read(firestoreProvider).batch();
    for (final n in unread) {
      batch.update(
        ref.read(firestoreProvider).collection('notifications').doc(n.id),
        {'isRead': true},
      );
    }
    await batch.commit();
  }
}

class _GroupedNotification {
  const _GroupedNotification({
    required this.dateLabel,
    required this.notification,
  });
  final String dateLabel;
  final NotificationModel notification;
}
