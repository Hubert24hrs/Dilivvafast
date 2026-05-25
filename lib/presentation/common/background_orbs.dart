import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Reusable background orbs widget for consistent neomorphic styling
/// across all screens in the app.
class BackgroundOrbs extends StatelessWidget {
  const BackgroundOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-right green orb
        Positioned(
          top: -50,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom-left white orb
        Positioned(
          bottom: -100,
          left: -120,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Floating shape
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: 40,
          child: Transform.rotate(
            angle: 0.8,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
