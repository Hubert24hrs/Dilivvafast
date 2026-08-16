import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';

class DriverDocumentsScreen extends ConsumerStatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  ConsumerState<DriverDocumentsScreen> createState() =>
      _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends ConsumerState<DriverDocumentsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _uploadDocument(String docType) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final storageRef = FirebaseStorage.instance.ref().child(
        'drivers/$uid/$docType.jpg',
      );

      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await storageRef.getDownloadURL();

      await ref.read(firestoreProvider).collection('users').doc(uid).update({
        '${docType}Url': downloadUrl,
        'updatedAt': DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$docType uploaded successfully for review.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload document: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Documents & Verification'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status banner
          Card(
            color: user?.isVerified == true
                ? AppTheme.successColor.withValues(alpha: 0.15)
                : AppTheme.warningColor.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: user?.isVerified == true
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
              ),
            ),
            child: ListTile(
              leading: Icon(
                user?.isVerified == true ? Icons.verified : Icons.hourglass_top,
                color: user?.isVerified == true
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
                size: 32,
              ),
              title: Text(
                user?.isVerified == true
                    ? 'Account Verified'
                    : 'Verification Pending',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                user?.isVerified == true
                    ? 'You are authorized to accept delivery requests.'
                    : 'Upload your required documents below for compliance audit.',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'REQUIRED DOCUMENTS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          _docCard(
            title: 'Driver License',
            subtitle: 'Government issued valid driving permit',
            url: user?.licenseUrl,
            onUpload: () => _uploadDocument('license'),
          ),
          _docCard(
            title: 'Vehicle Registration',
            subtitle: 'Proof of motorcycle / vehicle ownership',
            url: null,
            onUpload: () => _uploadDocument('registration'),
          ),
          _docCard(
            title: 'Third-Party Insurance',
            subtitle: 'Valid road insurance certificate',
            url: null,
            onUpload: () => _uploadDocument('insurance'),
          ),
        ],
      ),
    );
  }

  Widget _docCard({
    required String title,
    required String subtitle,
    required String? url,
    required VoidCallback onUpload,
  }) {
    final hasUploaded = url != null && url.isNotEmpty;

    return Card(
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          hasUploaded ? Icons.task_alt : Icons.upload_file,
          color: hasUploaded ? AppTheme.successColor : AppTheme.primaryColor,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          hasUploaded ? 'Document Uploaded' : subtitle,
          style: TextStyle(
            color: hasUploaded ? AppTheme.successColor : Colors.white70,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: _isUploading ? null : onUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: hasUploaded
                ? AppTheme.surfaceColor
                : AppTheme.primaryColor,
          ),
          child: Text(hasUploaded ? 'Re-upload' : 'Upload'),
        ),
      ),
    );
  }
}
