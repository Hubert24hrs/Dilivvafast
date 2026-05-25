import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ServiceSelector extends StatelessWidget {
  final String selectedService;
  final Function(String) onServiceSelected;

  const ServiceSelector({
    super.key,
    required this.selectedService,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _build3DServiceCard(
            context,
            label: 'Ride',
            imagePath: 'assets/images/img_ride.jpg',
            isSelected: selectedService == 'Ride',
          ),
          _build3DServiceCard(
            context,
            label: 'Couriers',
            imagePath: 'assets/images/img_courier.jpg',
            isSelected: selectedService == 'Couriers',
          ),
        ],
      ),
    ).animate().slideY(begin: 1, duration: 500.ms, curve: Curves.easeOutQuart);
  }

  Widget _build3DServiceCard(
    BuildContext context, {
    required String label,
    required String imagePath,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onServiceSelected(label);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: 300.ms,
            curve: Curves.easeOutBack,
            width: isSelected ? 110 : 90,
            height: isSelected ? 110 : 90,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..translate(0.0, isSelected ? -10.0 : 0.0), // Float up
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 15),
                        spreadRadius: -5,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image Background
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                  
                  // Gradient Overlay (for text readability)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),

                  // Selection Border Overlay
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedDefaultTextStyle(
            duration: 200.ms,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
              fontSize: isSelected ? 16 : 14,
              fontFamily: 'GoogleFonts.outfit', // Assuming Outfit or default
            ),
            child: Text(label),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ).animate().scale(),
        ],
      ),
    );
  }
}
