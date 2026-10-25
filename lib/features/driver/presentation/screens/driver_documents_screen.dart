import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/presentation/utils/friendly_error.dart';

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
    // The gallery picker suspends this screen; it may be disposed by the time
    // the user finishes choosing (or cancelling).
    if (image == null || !mounted) return;

    // Reject anything that is not an image we are prepared to store. The
    // storage rules enforce this too, but failing here gives the driver a
    // clear message instead of an opaque permission error.
    final name = image.name.toLowerCase();
    const allowed = ['.jpg', '.jpeg', '.png', '.webp'];
    if (!allowed.any(name.endsWith)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please choose a JPG, PNG or WebP image.'),
          backgroundColor: context.palette.danger,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();

      // Matches the 8 MB ceiling in storage.rules, checked here so an
      // oversized file fails fast instead of after a long upload.
      const maxBytes = 8 * 1024 * 1024;
      if (bytes.lengthInBytes > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('That image is too large (8 MB maximum).'),
            backgroundColor: context.palette.danger,
          ),
        );
        return;
      }

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
            backgroundColor: context.palette.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: context.palette.danger,
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
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Documents & Verification'),
        backgroundColor: context.palette.surfaceRaised,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status banner
          Card(
            color: user?.isVerified == true
                ? context.palette.success.withValues(alpha: 0.15)
                : context.palette.warning.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: user?.isVerified == true
                    ? context.palette.success
                    : context.palette.warning,
              ),
            ),
            child: ListTile(
              leading: Icon(
                user?.isVerified == true ? Icons.verified : Icons.hourglass_top,
                color: user?.isVerified == true
                    ? context.palette.success
                    : context.palette.warning,
                size: 32,
              ),
              title: Text(
                user?.isVerified == true
                    ? 'Account Verified'
                    : 'Verification Pending',
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                user?.isVerified == true
                    ? 'You are authorized to accept delivery requests.'
                    : 'Upload your required documents below for compliance audit.',
                style: TextStyle(color: context.palette.textSecondary),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'REQUIRED DOCUMENTS',
            style: TextStyle(
              color: context.palette.textSecondary,
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
      color: context.palette.surfaceRaised,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          hasUploaded ? Icons.task_alt : Icons.upload_file,
          color: hasUploaded ? context.palette.success : context.palette.brand,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          hasUploaded ? 'Document Uploaded' : subtitle,
          style: TextStyle(
            color: hasUploaded
                ? context.palette.success
                : context.palette.textSecondary,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: _isUploading ? null : onUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: hasUploaded
                ? context.palette.surfaceRaised
                : context.palette.brand,
          ),
          child: Text(hasUploaded ? 'Re-upload' : 'Upload'),
        ),
      ),
    );
  }
}
