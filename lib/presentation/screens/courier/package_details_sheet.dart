
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PackageDetailsSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  
  const PackageDetailsSheet({
    super.key, 
    required this.onSave,
  });

  @override
  State<PackageDetailsSheet> createState() => _PackageDetailsSheetState();
}

class _PackageDetailsSheetState extends State<PackageDetailsSheet> {
  bool _isToDoorstep = false;
  final _senderPhoneController = TextEditingController(text: '+234 8111605155');
  final _recipientPhoneController = TextEditingController(text: '+234 ');
  final _descriptionController = TextEditingController();

  void _handleSave() {
    final data = {
      'isToDoorstep': _isToDoorstep,
      'senderPhone': _senderPhoneController.text,
      'recipientPhone': _recipientPhoneController.text,
      'description': _descriptionController.text,
    };
    widget.onSave(data);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Package details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildToggleOption('To premises', !_isToDoorstep),
                    ),
                    Expanded(
                      child: _buildToggleOption('To doorstep', _isToDoorstep),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Phone Inputs
              _buildPhoneInput('Sender phone number', _senderPhoneController),
              const SizedBox(height: 16),
              _buildPhoneInput('Recipient phone number', _recipientPhoneController),
              
              const SizedBox(height: 24),

              // Description
              Row(
                children: [
                  const Text(
                    'Parcel description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.info_outline, size: 16, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Describe the parcel (value must be under N50,000)',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    '0/200',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor, // Lime green
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isToDoorstep = label == 'To doorstep'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Flag Icon (Static for now)
          const Icon(Icons.flag, color: AppTheme.primaryColor),
          const Icon(Icons.arrow_drop_down, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.contact_phone_outlined, color: Colors.white54),
        ],
      ),
    );
  }
}
