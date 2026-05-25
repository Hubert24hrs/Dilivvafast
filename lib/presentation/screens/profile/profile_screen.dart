


import 'package:fast_delivery/core/models/user_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  Uint8List? _imageBytes; // Changed from File? to Uint8List?
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initializeControllers(UserModel user) {
    if (!_isEditing) {
      if (_nameController.text != user.displayName) {
        _nameController.text = user.displayName ?? '';
      }
      if (_phoneController.text != user.phoneNumber) {
        _phoneController.text = user.phoneNumber ?? '';
      }
      if (_emailController.text != user.email) {
        _emailController.text = user.email;
      }
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _saveProfile(UserModel currentUser) async {
    setState(() => _isLoading = true);
    try {
      String? photoUrl = currentUser.photoUrl;

      // Upload Photo if changed
      if (_imageBytes != null) {
        // Pass bytes instead of File
        photoUrl = await ref.read(storageServiceProvider).uploadProfilePhoto(currentUser.id, _imageBytes!);
      }

      final updatedUser = UserModel(
        id: currentUser.id,
        email: currentUser.email,
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoUrl: photoUrl,
        role: currentUser.role,
        walletBalance: currentUser.walletBalance,
        homeAddress: currentUser.homeAddress,
        workAddress: currentUser.workAddress,
        createdAt: currentUser.createdAt,
      );

      await ref.read(databaseServiceProvider).updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated', style: TextStyle(color: Colors.white))),
        );
        setState(() {
          _isEditing = false;
          _imageBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e', style: const TextStyle(color: Colors.white))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _updateAddress(UserModel currentUser, String type, String address) async {
    try {
      final updatedUser = UserModel(
        id: currentUser.id,
        email: currentUser.email,
        displayName: currentUser.displayName,
        phoneNumber: currentUser.phoneNumber,
        photoUrl: currentUser.photoUrl,
        role: currentUser.role,
        walletBalance: currentUser.walletBalance,
        homeAddress: type == 'home' ? address : currentUser.homeAddress,
        workAddress: type == 'work' ? address : currentUser.workAddress,
        createdAt: currentUser.createdAt,
      );

      await ref.read(databaseServiceProvider).updateUser(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type == 'home' ? 'Home' : 'Work'} address updated', style: const TextStyle(color: Colors.white))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating address: $e', style: const TextStyle(color: Colors.white))),
        );
      }
    }
  }

  void _showAddressDialog(UserModel user, String type) {
    final controller = TextEditingController(
      text: type == 'home' ? user.homeAddress : user.workAddress
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('Enter ${type == 'home' ? 'Home' : 'Work'} Location', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g., 123 Main St, Lagos',
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              _updateAddress(user, type, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final userAsync = userId != null 
        ? ref.watch(databaseServiceProvider).getUserStream(userId)
        : const Stream<UserModel?>.empty();

    return StreamBuilder<UserModel?>(
      stream: userAsync,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
        }

        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('User not found')));
        }

        _initializeControllers(user);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GlassCard(
                borderRadius: 50,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : () {
                  if (_isEditing) {
                    _saveProfile(user);
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                child: _isLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                    : Text(
                        _isEditing ? 'Done' : 'Edit',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Stack(
            children: [
              const BackgroundOrbs(),
              Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.backgroundGradient,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 100),
                  child: Column(
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryColor, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white10,
                                backgroundImage: _imageBytes != null 
                                    ? MemoryImage(_imageBytes!) as ImageProvider
                                    : (user.photoUrl != null ? NetworkImage(user.photoUrl!) : null),
                                child: (_imageBytes == null && user.photoUrl == null)
                                    ? const Icon(Icons.person, size: 60, color: Colors.white54)
                                    : null,
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_isEditing)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 60),
                            child: TextField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                                hintText: 'Enter Name',
                                hintStyle: TextStyle(color: Colors.white24),
                              ),
                            ),
                          )
                        else
                          Text(
                            user.displayName?.isNotEmpty == true ? user.displayName! : 'No Name',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 48),

                  // Info Fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildInfoField(Icons.phone, 'Phone Number', _phoneController, enabled: _isEditing),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Saved Places
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'SAVED PLACES',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          Icons.home, 
                          user.homeAddress?.isNotEmpty == true ? user.homeAddress! : 'Set Home Address',
                          subtitle: 'Home',
                          isSet: user.homeAddress?.isNotEmpty == true,
                          onTap: () => _showAddressDialog(user, 'home'),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsItem(
                          Icons.work, 
                          user.workAddress?.isNotEmpty == true ? user.workAddress! : 'Set Work Address',
                          subtitle: 'Work',
                          isSet: user.workAddress?.isNotEmpty == true,
                          onTap: () => _showAddressDialog(user, 'work'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                  
                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: const Text('LOG OUT', style: TextStyle(color: Colors.redAccent, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildInfoField(IconData icon, String label, TextEditingController controller, {required bool enabled}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              if (enabled)
                TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                  ),
                )
              else
                Text(
                  controller.text.isNotEmpty ? controller.text : 'Not set',
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, {String? subtitle, required bool isSet, VoidCallback? onTap}) {
    return GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSet ? AppTheme.primaryColor.withValues(alpha: 0.2) : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSet ? AppTheme.primaryColor : Colors.white54, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSet ? Colors.white : Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
