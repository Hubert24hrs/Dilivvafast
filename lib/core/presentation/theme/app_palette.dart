import 'package:flutter/material.dart';

/// Semantic colour tokens that resolve differently in light and dark.
///
/// Screens should read these through [BuildContext.palette] rather than
/// hard-coding hex values or `Colors.white`, which is what previously locked
/// the app to a single dark appearance.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceInverse,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.brand,
    required this.onBrand,
    required this.brandSubtle,
    required this.success,
    required this.successSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.danger,
    required this.dangerSubtle,
    required this.info,
    required this.infoSubtle,
    required this.driverAccent,
    required this.investorAccent,
    required this.shadow,
    required this.scrim,
  });

  /// Page background.
  final Color surfaceBase;

  /// Cards, sheets and anything sitting above the page.
  final Color surfaceRaised;

  /// Input fills and inset wells.
  final Color surfaceSunken;

  /// High-contrast block (used for primary CTAs in light mode).
  final Color surfaceInverse;

  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Text drawn on [surfaceInverse].
  final Color textInverse;

  final Color brand;
  final Color onBrand;

  /// Tinted brand background for chips and icon wells.
  final Color brandSubtle;

  final Color success;
  final Color successSubtle;
  final Color warning;
  final Color warningSubtle;
  final Color danger;
  final Color dangerSubtle;
  final Color info;
  final Color infoSubtle;

  /// Per-mode accents used by the drawer's mode switcher.
  final Color driverAccent;
  final Color investorAccent;

  final Color shadow;
  final Color scrim;

  /// Derives a usable palette from a bare [ColorScheme].
  ///
  /// Only used as a fallback when the theme carries no [AppPalette]; the real
  /// themes always supply one explicitly.
  factory AppPalette.fromScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final onSurface = scheme.onSurface;
    return AppPalette(
      surfaceBase: scheme.surface,
      surfaceRaised: scheme.surfaceContainer,
      surfaceSunken: scheme.surfaceContainerLow,
      surfaceInverse: scheme.inverseSurface,
      border: scheme.outlineVariant,
      borderStrong: scheme.outline,
      textPrimary: onSurface,
      textSecondary: onSurface.withValues(alpha: 0.72),
      textMuted: onSurface.withValues(alpha: 0.50),
      textInverse: scheme.onInverseSurface,
      brand: scheme.primary,
      onBrand: scheme.onPrimary,
      brandSubtle: scheme.primaryContainer,
      success: isDark ? const Color(0xFF3CCB93) : const Color(0xFF12805C),
      successSubtle: isDark ? const Color(0xFF0E2A22) : const Color(0xFFE6F4EF),
      warning: isDark ? const Color(0xFFF2A93B) : const Color(0xFFB54708),
      warningSubtle: isDark ? const Color(0xFF2C1D09) : const Color(0xFFFEF3E2),
      danger: scheme.error,
      dangerSubtle: scheme.errorContainer,
      info: isDark ? const Color(0xFF6BA5F7) : const Color(0xFF175CD3),
      infoSubtle: isDark ? const Color(0xFF0F1E33) : const Color(0xFFE8F0FE),
      driverAccent: isDark ? const Color(0xFF3CCB93) : const Color(0xFF12805C),
      investorAccent: isDark ? const Color(0xFF9F7BFF) : const Color(0xFF6938EF),
      shadow: scheme.shadow,
      scrim: scheme.scrim,
    );
  }

  @override
  AppPalette copyWith({
    Color? surfaceBase,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? surfaceInverse,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textInverse,
    Color? brand,
    Color? onBrand,
    Color? brandSubtle,
    Color? success,
    Color? successSubtle,
    Color? warning,
    Color? warningSubtle,
    Color? danger,
    Color? dangerSubtle,
    Color? info,
    Color? infoSubtle,
    Color? driverAccent,
    Color? investorAccent,
    Color? shadow,
    Color? scrim,
  }) {
    return AppPalette(
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textInverse: textInverse ?? this.textInverse,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      brandSubtle: brandSubtle ?? this.brandSubtle,
      success: success ?? this.success,
      successSubtle: successSubtle ?? this.successSubtle,
      warning: warning ?? this.warning,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      danger: danger ?? this.danger,
      dangerSubtle: dangerSubtle ?? this.dangerSubtle,
      info: info ?? this.info,
      infoSubtle: infoSubtle ?? this.infoSubtle,
      driverAccent: driverAccent ?? this.driverAccent,
      investorAccent: investorAccent ?? this.investorAccent,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      surfaceBase: mix(surfaceBase, other.surfaceBase),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      surfaceSunken: mix(surfaceSunken, other.surfaceSunken),
      surfaceInverse: mix(surfaceInverse, other.surfaceInverse),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      textInverse: mix(textInverse, other.textInverse),
      brand: mix(brand, other.brand),
      onBrand: mix(onBrand, other.onBrand),
      brandSubtle: mix(brandSubtle, other.brandSubtle),
      success: mix(success, other.success),
      successSubtle: mix(successSubtle, other.successSubtle),
      warning: mix(warning, other.warning),
      warningSubtle: mix(warningSubtle, other.warningSubtle),
      danger: mix(danger, other.danger),
      dangerSubtle: mix(dangerSubtle, other.dangerSubtle),
      info: mix(info, other.info),
      infoSubtle: mix(infoSubtle, other.infoSubtle),
      driverAccent: mix(driverAccent, other.driverAccent),
      investorAccent: mix(investorAccent, other.investorAccent),
      shadow: mix(shadow, other.shadow),
      scrim: mix(scrim, other.scrim),
    );
  }
}

/// Shorthand so widgets can write `context.palette.textSecondary`.
extension AppPaletteX on BuildContext {
  /// The active palette.
  ///
  /// Falls back to a scheme-derived palette when the extension is absent —
  /// a screen rendered under a plain [ThemeData] (the Firebase-init error app,
  /// or a widget test) should degrade to sensible colours, not crash.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      AppPalette.fromScheme(Theme.of(this).colorScheme);

  /// Convenience for the places that only need the Material scheme.
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get text => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
