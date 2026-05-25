import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Color? borderColor;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.opacity = 0.05,
    this.borderColor,
    this.borderRadius = 20,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              decoration: BoxDecoration(
                color: color ?? Colors.white.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor ?? Colors.white.withValues(alpha: 0.1),
                  width: 1.0,
                ),
                boxShadow: [
                  AppTheme.glassShadow,
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
