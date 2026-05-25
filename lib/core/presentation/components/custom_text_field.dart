import 'package:flutter/material.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      enabled: enabled,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        prefixIcon: icon != null
            ? Icon(
                icon,
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
              )
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
