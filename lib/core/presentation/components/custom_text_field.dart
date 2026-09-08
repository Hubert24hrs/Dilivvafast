import 'package:flutter/material.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: context.palette.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: context.palette.textMuted),
        prefixIcon: icon != null
            ? Icon(icon, color: context.palette.brand.withValues(alpha: 0.7))
            : null,
      ),
    );
  }
}
