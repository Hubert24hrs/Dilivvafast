import 'package:flutter/material.dart';

class ThreeDButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const ThreeDButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  State<ThreeDButton> createState() => _ThreeDButtonState();
}

class _ThreeDButtonState extends State<ThreeDButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()
          ..translate(0.0, _isPressed ? 10.0 : 0.0), // Move down when pressed
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isPressed
              ? [] // No shadow when pressed (flat against surface)
              : [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.6),
                    offset: const Offset(0, 10), // Deep shadow for 3D effect
                    blurRadius: 0, // Sharp shadow for "blocky" 3D look or soft for neon?
                    // Let's go with a mix: a solid block shadow + a glow
                  ),
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    offset: const Offset(0, 15),
                    blurRadius: 20, // Glow
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 48,
              color: Colors.black,
            ),
            const SizedBox(height: 12),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
