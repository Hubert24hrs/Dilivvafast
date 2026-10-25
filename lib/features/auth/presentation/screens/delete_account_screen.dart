import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmCtrl = TextEditingController();
  bool _isDeleting = false;
  String? _errorMsg;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (_confirmCtrl.text.trim().toUpperCase() != 'DELETE') {
      setState(() {
        _errorMsg = 'Please type "DELETE" to confirm';
      });
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMsg = null;
    });

    final res = await ref.read(authRepositoryProvider).deleteAccount();

    res.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isDeleting = false;
            _errorMsg = failure.message;
          });
        }
      },
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your account and data have been permanently deleted.',
              ),
            ),
          );
          context.go('/login');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Delete Account'),
        backgroundColor: context.palette.surfaceRaised,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: context.palette.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Permanent Account Deletion',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Account: ${user?.email ?? 'your account'}',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: context.palette.danger.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.palette.danger),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Warning: This action cannot be undone!',
                      style: TextStyle(
                        color: context.palette.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    // What the deleteMyAccount Cloud Function actually does.
                    // This used to promise that order history would be
                    // purged; it is kept, because the other party and the
                    // accounts rely on it. Play requires an accurate account.
                    Text(
                      '• Your profile, saved addresses, notifications and '
                      'support chat are deleted.\n'
                      '• Driver documents and bank details you uploaded are '
                      'deleted.\n'
                      '• Any wallet balance is forfeited.\n'
                      '• Delivery and payment records are kept for accounting '
                      'and disputes, no longer linked to your name.\n'
                      '• You will be signed out on every device.',
                      style: TextStyle(
                        color: context.palette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'To confirm deletion, please type "DELETE" below:',
              style: TextStyle(color: context.palette.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmCtrl,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: context.palette.textPrimary),
              decoration: InputDecoration(
                hintText: 'DELETE',
                errorText: _errorMsg,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _handleDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'PERMANENTLY DELETE ACCOUNT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
