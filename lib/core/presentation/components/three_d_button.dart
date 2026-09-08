import 'package:flutter/material.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class ThreeDButton extends StatefulWidget {
  const ThreeDButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.height = 56.0,
    this.width = double.infinity,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  /// Defaults to the brand colour resolved from the active theme.
  final Color? color;
  final double height;
  final double width;

  @override
  State<ThreeDButton> createState() => _ThreeDButtonState();
}

class _ThreeDButtonState extends State<ThreeDButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? context.palette.brand;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) {
          widget.onPressed();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: widget.height,
        width: widget.width,
        margin: EdgeInsets.only(top: _isPressed ? 4.0 : 0.0),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: base.withValues(alpha: 0.5),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: base.withValues(alpha: 0.8),
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: context.palette.onBrand,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  widget.text,
                  style: TextStyle(
                    color: context.palette.onBrand,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}
