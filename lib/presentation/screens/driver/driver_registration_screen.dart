import 'dart:typed_data';

import 'package:fast_delivery/core/models/driver_application_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class DriverRegistrationScreen extends ConsumerStatefulWidget {
  final String type; // 'driver' or 'courier'

  const DriverRegistrationScreen({super.key, required this.type});

  @override
  ConsumerState<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends ConsumerState<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _makeModelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();

  // Document Files (Bytes)
  Uint8List? _licenseImage;
  Uint8List? _registrationImage;
  Uint8List? _insuranceImage;
  Uint8List? _permitImage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _makeModelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = widget.type == 'driver';
    final title = isDriver ? 'Become a Driver' : 'Become a Courier';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submit Documentation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please fill in the details and upload necessary documents to get verified.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),

              _buildTextField('Full Name', _nameController),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', _phoneController),
              const SizedBox(height: 16),
              _buildTextField('Vehicle Make & Model', _makeModelController),
              const SizedBox(height: 16),
              _buildTextField('Vehicle Year', _yearController),
              const SizedBox(height: 16),
              _buildTextField('License Plate Number', _plateController),
              
              const SizedBox(height: 32),
              
              const Text(
                'Documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              
              _buildUploadButton('Driver\'s License', _licenseImage, (bytes) => setState(() => _licenseImage = bytes)),
              const SizedBox(height: 12),
              _buildUploadButton('Vehicle Registration', _registrationImage, (bytes) => setState(() => _registrationImage = bytes)),
              const SizedBox(height: 12),
              _buildUploadButton('Insurance Certificate', _insuranceImage, (bytes) => setState(() => _insuranceImage = bytes)),
              if (!isDriver) ...[
                const SizedBox(height: 12),
                _buildUploadButton('Courier Permit', _permitImage, (bytes) => setState(() => _permitImage = bytes)),
              ],

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Widget _buildUploadButton(String label, Uint8List? imageBytes, Function(Uint8List) onImageSelected) {
    final isSelected = imageBytes != null;

    return InkWell(
      onTap: () => _pickImage(onImageSelected),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white24, 
            style: BorderStyle.solid
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.upload_file, 
              color: isSelected ? AppTheme.primaryColor : Colors.white54
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  if (isSelected)
                    Text(
                      'File selected',
                      style: TextStyle(color: AppTheme.primaryColor.withValues(alpha: 0.8), fontSize: 12),
                    ),
                ],
              ),
            ),
            Text(
              isSelected ? 'Change' : 'Upload',
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.white70, 
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(Function(Uint8List) onImageSelected) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        onImageSelected(bytes);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_licenseImage == null || _registrationImage == null || _insuranceImage == null || (widget.type != 'driver' && _permitImage == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload all required documents')),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) throw Exception('User not logged in');

        // Upload Documents
        final storage = ref.read(storageServiceProvider);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        // uploadDocument now accepts Uint8List
        final licenseUrl = await storage.uploadDocument(userId, 'license_$timestamp', _licenseImage!);
        final registrationUrl = await storage.uploadDocument(userId, 'registration_$timestamp', _registrationImage!);
        final insuranceUrl = await storage.uploadDocument(userId, 'insurance_$timestamp', _insuranceImage!);
        String? permitUrl;
        
        if (widget.type != 'driver' && _permitImage != null) {
          permitUrl = await storage.uploadDocument(userId, 'permit_$timestamp', _permitImage!);
        }

        final app = DriverApplicationModel(
          id: userId,
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          vehicleMake: _makeModelController.text.split(' ').first,
          vehicleModel: _makeModelController.text,
          vehicleYear: _yearController.text.trim(),
          licensePlate: _plateController.text.trim(),
          createdAt: DateTime.now(),
          licenseUrl: licenseUrl,
          registrationUrl: registrationUrl,
          insuranceUrl: insuranceUrl,
          permitUrl: permitUrl,
        );

        await ref.read(databaseServiceProvider).submitDriverApplication(app);

        if (mounted) {
          context.go('/driver-pending');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting application: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
