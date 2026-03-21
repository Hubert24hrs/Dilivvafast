import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fast_delivery/features/courier/domain/entities/courier_order_model.dart';

/// Package details form: category, weight, recipient info, and notes.
class PackageForm extends StatelessWidget {
  const PackageForm({
    super.key,
    required this.onCategoryChanged,
    required this.onWeightChanged,
    required this.onRecipientNameChanged,
    required this.onRecipientPhoneChanged,
    required this.onDescriptionChanged,
    required this.onNotesChanged,
    this.selectedCategory = PackageCategory.other,
    this.weight = 0.0,
  });

  final ValueChanged<PackageCategory> onCategoryChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<String> onRecipientNameChanged;
  final ValueChanged<String> onRecipientPhoneChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String> onNotesChanged;
  final PackageCategory selectedCategory;
  final double weight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Package category
        const _SectionLabel('Package Category'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PackageCategory.values.map((category) {
            final isSelected = category == selectedCategory;
            return GestureDetector(
              onTap: () => onCategoryChanged(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
                      : const Color(0xFF1D1E33),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00F0FF)
                        : Colors.white12,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcon(category),
                      color: isSelected
                          ? const Color(0xFF00F0FF)
                          : Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _categoryLabel(category),
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00F0FF) : Colors.white70,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Package weight
        const _SectionLabel('Estimated Weight (kg)'),
        const SizedBox(height: 8),
        _buildTextField(
          hint: 'e.g. 2.5',
          icon: Icons.fitness_center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
          ],
          onChanged: (val) {
            final w = double.tryParse(val) ?? 0.0;
            onWeightChanged(w);
          },
        ),

        const SizedBox(height: 24),

        // Package description
        const _SectionLabel('Package Description'),
        const SizedBox(height: 8),
        _buildTextField(
          hint: 'What are you sending?',
          icon: Icons.inventory_2,
          onChanged: onDescriptionChanged,
        ),

        const SizedBox(height: 24),

        // Recipient info
        const _SectionLabel('Recipient Details'),
        const SizedBox(height: 8),
        _buildTextField(
          hint: 'Recipient name',
          icon: Icons.person_outline,
          onChanged: onRecipientNameChanged,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          hint: 'Recipient phone (e.g. 08012345678)',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          onChanged: onRecipientPhoneChanged,
        ),

        const SizedBox(height: 24),

        // Notes
        const _SectionLabel('Delivery Notes (Optional)'),
        const SizedBox(height: 8),
        _buildTextField(
          hint: 'e.g. Call before delivery, fragile item...',
          icon: Icons.note_outlined,
          maxLines: 3,
          onChanged: onNotesChanged,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF00F0FF), size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
      ),
    );
  }

  IconData _categoryIcon(PackageCategory cat) {
    return switch (cat) {
      PackageCategory.documents => Icons.description,
      PackageCategory.fragile => Icons.warning_amber,
      PackageCategory.electronics => Icons.devices,
      PackageCategory.food => Icons.fastfood,
      PackageCategory.clothing => Icons.checkroom,
      PackageCategory.other => Icons.inventory_2,
    };
  }

  String _categoryLabel(PackageCategory cat) {
    return switch (cat) {
      PackageCategory.documents => 'Documents',
      PackageCategory.fragile => 'Fragile',
      PackageCategory.electronics => 'Electronics',
      PackageCategory.food => 'Food',
      PackageCategory.clothing => 'Clothing',
      PackageCategory.other => 'Other',
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
