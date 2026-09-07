import 'package:flutter/material.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// A raised surface panel.
///
/// Previously a frosted-glass effect: a translucent white fill behind a
/// backdrop blur. That renders as white-on-white in light mode and the blur
/// costs a saveLayer on every frame, so it is now a flat, bordered surface —
/// which is also what contemporary delivery apps use. The constructor keeps
/// its original shape so existing call sites are unaffected.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = AppTheme.radiusLarge,
    @Deprecated('The blur was removed with the frosted-glass treatment.')
    this.blur = 0.0,
    @Deprecated('Surface colour now comes from the theme.')
    this.opacity = 0.0,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final double opacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(borderRadius);

    return Material(
      color: palette.surfaceRaised,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        // Keeps the ripple contained when the card is not interactive.
        canRequestFocus: onTap != null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: palette.border),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
