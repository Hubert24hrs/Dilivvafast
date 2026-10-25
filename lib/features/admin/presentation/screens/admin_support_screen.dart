import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/utils/friendly_error.dart';
import 'package:dilivvafast/core/providers/providers.dart';

/// Support threads, most recent first, with unanswered ones flagged.
///
/// Customers could always write to support, but nothing listed their
/// messages, so none were ever read. Thread summaries (`lastMessage`,
/// `needsReply`, `updatedAt`) are maintained by `onSupportMessageCreated`.
class AdminSupportScreen extends ConsumerWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final threads = ref
        .watch(firestoreProvider)
        .collection('orders')
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .snapshots();

    return Scaffold(
      backgroundColor: palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Support inbox'),
        backgroundColor: palette.surfaceRaised,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: threads,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error!)));
          }
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: palette.brand),
            );
          }
          final docs = snapshot.data!.docs
              .where((d) => d.id.startsWith('support_'))
              .toList();
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No support conversations yet.',
                style: TextStyle(color: palette.textSecondary),
              ),
            );
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: palette.border),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final userId = docs[i].id.substring('support_'.length);
              final needsReply = data['needsReply'] == true;
              final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
              return ListTile(
                onTap: () => context.push('/admin/support/$userId'),
                leading: CircleAvatar(
                  backgroundColor: needsReply
                      ? palette.brand
                      : palette.surfaceSunken,
                  child: Icon(
                    Icons.person,
                    color: needsReply ? palette.onBrand : palette.textMuted,
                  ),
                ),
                title: Text(
                  data['userName'] as String? ?? 'Customer',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: needsReply ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  data['lastMessage'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.textSecondary),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (updatedAt != null)
                      Text(
                        DateFormat('d MMM, HH:mm').format(updatedAt),
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    if (needsReply)
                      Text(
                        'Needs reply',
                        style: TextStyle(
                          color: palette.brand,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
