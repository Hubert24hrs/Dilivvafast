import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';

class SavedAddressesScreen extends ConsumerStatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  ConsumerState<SavedAddressesScreen> createState() =>
      _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends ConsumerState<SavedAddressesScreen> {
  final _labelCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _addAddress() async {
    final label = _labelCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    if (label.isEmpty || address.isEmpty) return;

    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(firestoreProvider)
          .collection('users')
          .doc(uid)
          .collection('saved_addresses')
          .add({
            'label': label,
            'address': address,
            'createdAt': FieldValue.serverTimestamp(),
          });
      _labelCtrl.clear();
      _addressCtrl.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving address: $e'),
            backgroundColor: context.palette.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Saved Address',
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _labelCtrl,
                style: TextStyle(color: context.palette.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Label (e.g. Home, Work, Gym)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                style: TextStyle(color: context.palette.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Full Address'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setModalState(() {});
                          await _addAddress();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.brand,
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.palette.onBrand,
                          ),
                        )
                      : const Text('Save Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAddress(String docId) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref
        .read(firestoreProvider)
        .collection('users')
        .doc(uid)
        .collection('saved_addresses')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        backgroundColor: context.palette.surfaceRaised,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: context.palette.brand,
        child: Icon(Icons.add, color: context.palette.onBrand),
      ),
      body: uid == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot>(
              stream: ref
                  .watch(firestoreProvider)
                  .collection('users')
                  .doc(uid)
                  .collection('saved_addresses')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading addresses: ${snapshot.error}',
                      style: TextStyle(color: context.palette.danger),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 64,
                          color: context.palette.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No saved addresses yet',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to save home, work, or favorite places',
                          style: TextStyle(
                            color: context.palette.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final label = data['label'] ?? 'Address';
                    final address = data['address'] ?? '';

                    return Card(
                      color: context.palette.surfaceRaised,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: context.palette.brand.withValues(
                            alpha: 0.15,
                          ),
                          child: Icon(
                            _getLabelIcon(label),
                            color: context.palette.brand,
                          ),
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            color: context.palette.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          address,
                          style: TextStyle(
                            color: context.palette.textSecondary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: context.palette.textMuted,
                          ),
                          onPressed: () => _deleteAddress(docId),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  IconData _getLabelIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('home')) return Icons.home_outlined;
    if (l.contains('work') || l.contains('office')) return Icons.work_outline;
    if (l.contains('gym')) return Icons.fitness_center_outlined;
    return Icons.location_on_outlined;
  }
}
