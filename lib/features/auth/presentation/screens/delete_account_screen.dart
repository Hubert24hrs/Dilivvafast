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
                color: context.palette.onBrand,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Account: ${user?.email ?? "Current User"}\nUID: ${user?.uid ?? ""}',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontFamily: 'monospace',
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
                    Text(
                      '• Your user profile and personal info will be deleted.\n'
                      '• Your order history and saved addresses will be purged.\n'
                      '• Unused wallet balances will be forfeited.\n'
                      '• You will be immediately logged out of all devices.',
                      style: TextStyle(color: context.palette.textSecondary, height: 1.5),
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
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.palette.onBrand,
                        ),
                      )
                    : Text(
                        'PERMANENTLY DELETE ACCOUNT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.palette.textPrimary,
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
