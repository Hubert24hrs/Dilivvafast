import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/constants/firestore_constants.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/auth/domain/entities/app_mode.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';
import 'package:dilivvafast/features/driver/domain/entities/driver_application_model.dart';

/// Pending driver applications, newest first.
final driverApplicationsProvider = StreamProvider<List<DriverApplicationModel>>(
  (ref) {
    return ref
        .watch(firestoreProvider)
        .collection(FirestoreConstants.driverApplications)
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(DriverApplicationModel.fromFirestore)
              .toList(growable: false),
        );
  },
);

/// Accounts waiting on investor approval.
final investorApplicantsProvider = StreamProvider<List<UserModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection(FirestoreConstants.users)
      .where('investorStatus', isEqualTo: ModeAccess.pending.name)
      .limit(100)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map(UserModel.fromFirestore).toList(growable: false),
      );
});

/// The approval queue.
///
/// This is the only place a mode entitlement is granted — the client can move
/// an account to `pending`, but `approved` is written here and enforced by the
/// Firestore rules.
class AdminApplicationsScreen extends ConsumerWidget {
  const AdminApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Applications'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Drivers'),
              Tab(text: 'Investors'),
            ],
          ),
        ),
        body: const TabBarView(children: [_DriverQueue(), _InvestorQueue()]),
      ),
    );
  }
}

// ── Drivers ─────────────────────────────────────────────────────────────────

class _DriverQueue extends ConsumerWidget {
  const _DriverQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(driverApplicationsProvider);

    return applications.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _QueueError(message: '$e'),
      data: (items) {
        if (items.isEmpty) {
          return const _QueueEmpty(
            icon: Icons.two_wheeler_outlined,
            message: 'No driver applications yet.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _DriverCard(application: items[i]),
        );
      },
    );
  }
}

class _DriverCard extends ConsumerWidget {
  const _DriverCard({required this.application});

  final DriverApplicationModel application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final decided =
        application.status == ApplicationStatus.approved ||
        application.status == ApplicationStatus.rejected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application.fullName, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(application.email, style: context.text.bodySmall),
                  ],
                ),
              ),
              _StatusChip(status: application.status),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Phone', value: application.phone),
          _DetailRow(
            label: 'Vehicle',
            value: '${application.vehicleType} · ${application.vehiclePlate}',
          ),
          if (application.bankName != null)
            _DetailRow(
              label: 'Payout',
              value:
                  '${application.bankName} · '
                  '${application.accountNumber ?? '—'}',
            ),
          _DocumentRow(application: application),
          if (!decided) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decide(context, ref, approved: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.danger,
                      side: BorderSide(color: palette.danger),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _decide(context, ref, approved: true),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref, {
    required bool approved,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Goes through the Cloud Function rather than writing Firestore
      // directly. Admins are permitted to write both documents, but granting
      // someone the ability to earn on the platform should leave a record of
      // who decided it — the function writes admin_audit_log, which no client
      // can forge, and commits both documents in one batch.
      await ref
          .read(firebaseFunctionsProvider)
          .httpsCallable('reviewDriverApplication')
          .call<Map<String, dynamic>>({
            'uid': application.userId,
            'applicationId': application.id,
            'decision': approved ? 'approved' : 'rejected',
            if (approved) 'vehicleType': application.vehicleType,
            if (approved) 'vehiclePlate': application.vehiclePlate,
          });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? '${application.fullName} can now drive.'
                : 'Application declined.',
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not update the application.'),
        ),
      );
    } catch (e) {
      debugPrint('reviewDriverApplication failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update the application.')),
      );
    }
  }
}

class _DocumentRow extends ConsumerWidget {
  const _DocumentRow({required this.application});

  final DriverApplicationModel application;

  /// Label -> (whether it was uploaded, the storage key the backend expects).
  Map<String, (bool, String)> get _docs => {
    'Licence': (application.licenseUrl != null, 'drivers_license'),
    'Vehicle': (application.vehiclePhotoUrl != null, 'vehicle_photo'),
    'ID': (application.governmentIdUrl != null, 'government_id'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in _docs.entries)
            _DocChip(
              label: entry.key,
              uploaded: entry.value.$1,
              onTap: entry.value.$1
                  ? () => _view(context, ref, entry.key, entry.value.$2)
                  : null,
            ),
        ],
      ),
    );
  }

  /// Open one identity document.
  ///
  /// These chips used to be decoration — they showed a tick if a file had been
  /// uploaded and nothing more, so an application was approved or declined
  /// without anyone ever seeing the licence or ID behind it.
  ///
  /// The URL is minted on demand by `getDriverDocumentUrl` and expires after
  /// 15 minutes. The permanent `getDownloadURL()` links stored on the
  /// application document bypass storage.rules and cannot be revoked, so they
  /// are deliberately not used here.
  Future<void> _view(
    BuildContext context,
    WidgetRef ref,
    String label,
    String docKey,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ref
          .read(firebaseFunctionsProvider)
          .httpsCallable('getDriverDocumentUrl')
          .call<Map<String, dynamic>>({
            'uid': application.userId,
            'docKey': docKey,
          });

      navigator.pop(); // dismiss the spinner

      final url = result.data['url'] as String?;
      if (url == null || url.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('That document is unavailable.')),
        );
        return;
      }

      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(label),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Padding(
                            padding: EdgeInsets.all(48),
                            child: CircularProgressIndicator(),
                          ),
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Could not load the image.'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not open that document.')),
      );
    } catch (e) {
      navigator.pop();
      debugPrint('getDriverDocumentUrl failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open that document.')),
      );
    }
  }
}

class _DocChip extends StatelessWidget {
  const _DocChip({required this.label, required this.uploaded, this.onTap});

  final String label;
  final bool uploaded;

  /// Null when nothing was uploaded, which also leaves the chip inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: uploaded ? palette.successSubtle : palette.surfaceSunken,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              uploaded ? Icons.check_rounded : Icons.remove_rounded,
              size: 14,
              color: uploaded ? palette.success : palette.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: context.text.bodySmall?.copyWith(
                color: uploaded ? palette.success : palette.textMuted,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.visibility_outlined, size: 13, color: palette.success),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Investors ───────────────────────────────────────────────────────────────

class _InvestorQueue extends ConsumerWidget {
  const _InvestorQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicants = ref.watch(investorApplicantsProvider);

    return applicants.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _QueueError(message: '$e'),
      data: (items) {
        if (items.isEmpty) {
          return const _QueueEmpty(
            icon: Icons.trending_up_rounded,
            message: 'No investor applications waiting.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _InvestorCard(user: items[i]),
        );
      },
    );
  }
}

class _InvestorCard extends ConsumerWidget {
  const _InvestorCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.fullName, style: context.text.titleMedium),
          const SizedBox(height: 2),
          Text(user.email, style: context.text.bodySmall),
          const SizedBox(height: 4),
          Text(user.phone, style: context.text.bodySmall),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _decide(context, ref, approved: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.danger,
                    side: BorderSide(color: palette.danger),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _decide(context, ref, approved: true),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref, {
    required bool approved,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(firestoreProvider)
          .collection(FirestoreConstants.users)
          .doc(user.uid)
          .update({
            'investorStatus': approved
                ? ModeAccess.approved.name
                : ModeAccess.rejected.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? '${user.fullName} can now invest.'
                : 'Application declined.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }
}

// ── Shared ──────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (bg, fg, label) = switch (status) {
      ApplicationStatus.approved => (
        palette.successSubtle,
        palette.success,
        'Approved',
      ),
      ApplicationStatus.rejected => (
        palette.dangerSubtle,
        palette.danger,
        'Declined',
      ),
      ApplicationStatus.underReview => (
        palette.infoSubtle,
        palette.info,
        'In review',
      ),
      ApplicationStatus.submitted => (
        palette.warningSubtle,
        palette.warning,
        'New',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: context.text.labelSmall?.copyWith(color: fg)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: context.text.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: context.text.bodyMedium?.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueEmpty extends StatelessWidget {
  const _QueueEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: palette.textMuted),
          const SizedBox(height: 12),
          Text(message, style: context.text.bodyMedium),
        ],
      ),
    );
  }
}

class _QueueError extends StatelessWidget {
  const _QueueError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load applications.\n$message',
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(
            color: context.palette.danger,
          ),
        ),
      ),
    );
  }
}
