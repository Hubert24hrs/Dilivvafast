import 'dart:ui';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _exitController;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(vsync: this, duration: 800.ms);
    
    // Sequence: Enter (handled by Animate) -> Wait -> Exit -> Navigate
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _startExitAnimation();
      }
    });
  }

  void _startExitAnimation() async {
    await _exitController.forward();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Animated Background Orbs (Exit animation applied to whole stack or elements)
          Positioned(
            top: -100,
            left: -100,
            child: _AnimatedOrb(color: const Color(0xFF004D26), size: 300)
                .animate(autoPlay: false, controller: _exitController)
                .fadeOut(duration: 600.ms),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _AnimatedOrb(color: AppTheme.primaryColor, size: 250)
                .animate(autoPlay: false, controller: _exitController)
                .fadeOut(duration: 600.ms),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: _AnimatedOrb(color: const Color(0xFF00FF94), size: 200)
                .animate(autoPlay: false, controller: _exitController)
                .fadeOut(duration: 600.ms),
          ),

          // 2. Blur Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate(autoPlay: false, controller: _exitController).fadeOut(duration: 800.ms),
          ),

          // 3. Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D Logo Animation
                // We wrap it in an Animate widget to handle the Exit phase specifically
                Animate(
                  controller: _exitController,
                  autoPlay: false,
                  effects: [
                    ScaleEffect(begin: const Offset(1, 1), end: const Offset(0, 0), duration: 600.ms, curve: Curves.easeInBack),
                    RotateEffect(begin: 0, end: 0.5, duration: 600.ms, curve: Curves.easeInBack),
                    FadeEffect(begin: 1, end: 0, duration: 400.ms),
                  ],
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    )
                    // Entrance Animation
                    .animate()
                    .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 1.seconds, curve: Curves.elasticOut)
                    .rotate(begin: -0.5, end: 0, duration: 1.seconds, curve: Curves.elasticOut)
                    .shimmer(delay: 1.seconds, duration: 2.seconds, color: Colors.white.withValues(alpha: 0.5))
                    .then()
                    // Continuous Breathing
                    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds, curve: Curves.easeInOut)
                    .then()
                    .scale(begin: const Offset(1.05, 1.05), end: const Offset(1, 1), duration: 2.seconds, curve: Curves.easeInOut),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Text Animations
                Animate(
                  controller: _exitController,
                  autoPlay: false,
                  effects: [
                    MoveEffect(begin: const Offset(0, 0), end: const Offset(0, 50), duration: 600.ms, curve: Curves.easeIn),
                    FadeEffect(begin: 1, end: 0, duration: 400.ms),
                  ],
                  child: Column(
                    children: [
                      Text(
                        'FAST DELIVERY',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                      ).animate().fadeIn(duration: 1.seconds).slideY(begin: 0.5, end: 0),
                      
                      const SizedBox(height: 10),
                      
                      Text(
                        'NIGERIA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              letterSpacing: 8,
                            ),
                      ).animate().fadeIn(delay: 500.ms, duration: 1.seconds),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _AnimatedOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 4.seconds, curve: Curves.easeInOut)
      .move(begin: const Offset(-20, -20), end: const Offset(20, 20), duration: 5.seconds, curve: Curves.easeInOut);
  }
}
