import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dilivvafast/core/presentation/theme/app_palette.dart';

export 'package:dilivvafast/core/presentation/theme/app_palette.dart';

/// Dilivvafast design system.
///
/// Two full themes share one brand: a light default and a dark counterpart,
/// following the convention of contemporary Western delivery apps — neutral
/// surfaces, high text contrast, generous spacing, hairline borders instead of
/// glows, and the orange used as an accent rather than a wash.
class AppTheme {
  const AppTheme._();

  // ==================== Brand constants ====================
  // Brand hues are fixed; everything that must adapt lives in [AppPalette].

  /// Dilivvafast Orange.
  static const Color primaryColor = Color(0xFFFF6B00);
  static const Color secondaryColor = Color(0xFFFF9500);
  static const Color accentColor = Color(0xFFFFB347);

  static const Color errorColor = Color(0xFFD92D20);
  static const Color successColor = Color(0xFF12805C);
  static const Color warningColor = Color(0xFFB54708);
  static const Color infoColor = Color(0xFF175CD3);

  /// Mode accents used by the drawer switcher.
  static const Color driverColor = Color(0xFF12805C);
  static const Color investorColor = Color(0xFF6938EF);

  // Dark-surface constants, kept for the dark theme's own definition.
  static const Color backgroundColor = Color(0xFF0B0D12);
  static const Color surfaceColor = Color(0xFF14171F);
  static const Color cardColor = Color(0xFF1B1F2A);

  // ==================== Shape and spacing tokens ====================

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;

  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  /// Minimum tappable height, per Apple HIG and Material accessibility.
  static const double minTouchTarget = 48;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== Palettes ====================

  static const AppPalette lightPalette = AppPalette(
    surfaceBase: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF5F6F8),
    surfaceInverse: Color(0xFF11131A),
    border: Color(0xFFE5E7EB),
    borderStrong: Color(0xFFD1D5DB),
    textPrimary: Color(0xFF11131A),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF868EA0),
    textInverse: Color(0xFFFFFFFF),
    brand: primaryColor,
    onBrand: Color(0xFF11131A),
    brandSubtle: Color(0xFFFFF3EC),
    success: successColor,
    successSubtle: Color(0xFFE6F4EF),
    warning: warningColor,
    warningSubtle: Color(0xFFFEF3E2),
    danger: errorColor,
    dangerSubtle: Color(0xFFFDECEA),
    info: infoColor,
    infoSubtle: Color(0xFFE8F0FE),
    driverAccent: driverColor,
    investorAccent: investorColor,
    shadow: Color(0x14101828),
    scrim: Color(0x66101828),
  );

  static const AppPalette darkPalette = AppPalette(
    surfaceBase: backgroundColor,
    surfaceRaised: surfaceColor,
    surfaceSunken: Color(0xFF1B1F2A),
    surfaceInverse: Color(0xFFF5F6F8),
    border: Color(0xFF262B36),
    borderStrong: Color(0xFF39404F),
    textPrimary: Color(0xFFF7F8FA),
    textSecondary: Color(0xFFAEB6C4),
    textMuted: Color(0xFF7A8496),
    textInverse: Color(0xFF11131A),
    brand: Color(0xFFFF8A3D),
    onBrand: Color(0xFF1A0A00),
    brandSubtle: Color(0xFF2A1608),
    success: Color(0xFF3CCB93),
    successSubtle: Color(0xFF0E2A22),
    warning: Color(0xFFF2A93B),
    warningSubtle: Color(0xFF2C1D09),
    danger: Color(0xFFF97066),
    dangerSubtle: Color(0xFF2E1210),
    info: Color(0xFF6BA5F7),
    infoSubtle: Color(0xFF0F1E33),
    driverAccent: Color(0xFF3CCB93),
    investorAccent: Color(0xFF9F7BFF),
    shadow: Color(0x66000000),
    scrim: Color(0xB3000000),
  );

  // ==================== Themes ====================

  static ThemeData get light => _build(Brightness.light, lightPalette);

  static ThemeData get dark => _build(Brightness.dark, darkPalette);

  /// Retained so existing call sites keep resolving to a valid dark theme.
  static ThemeData get cleanDarkTheme => dark;

  static ThemeData get futuristicTheme => dark;

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.brand,
      onPrimary: p.onBrand,
      primaryContainer: p.brandSubtle,
      onPrimaryContainer: isDark ? p.brand : const Color(0xFF7A2E02),
      secondary: secondaryColor,
      onSecondary: isDark ? const Color(0xFF1A0A00) : Colors.white,
      tertiary: p.investorAccent,
      onTertiary: Colors.white,
      error: p.danger,
      onError: isDark ? const Color(0xFF2E1210) : Colors.white,
      errorContainer: p.dangerSubtle,
      onErrorContainer: p.danger,
      surface: p.surfaceBase,
      onSurface: p.textPrimary,
      surfaceContainerLowest: p.surfaceBase,
      surfaceContainerLow: p.surfaceSunken,
      surfaceContainer: p.surfaceRaised,
      surfaceContainerHigh:
          isDark ? cardColor : const Color(0xFFF5F6F8),
      surfaceContainerHighest:
          isDark ? const Color(0xFF232838) : const Color(0xFFEDEFF3),
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.border,
      inverseSurface: p.surfaceInverse,
      onInverseSurface: p.textInverse,
      shadow: p.shadow,
      scrim: p.scrim,
    );

    final baseText =
        isDark ? Typography.whiteMountainView : Typography.blackMountainView;
    final textTheme = GoogleFonts.outfitTextTheme(baseText)
        .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary)
        .copyWith(
          displayLarge: GoogleFonts.outfit(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -0.8,
              color: p.textPrimary),
          displaySmall: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -0.5,
              color: p.textPrimary),
          headlineMedium: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.4,
              color: p.textPrimary),
          headlineSmall: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.25,
              letterSpacing: -0.2,
              color: p.textPrimary),
          titleLarge: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: p.textPrimary),
          titleMedium: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: p.textPrimary),
          bodyLarge: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: p.textPrimary),
          bodyMedium: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: p.textSecondary),
          bodySmall: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: p.textMuted),
          labelLarge: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: p.textPrimary),
          labelSmall: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: p.textMuted),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.surfaceBase,
      canvasColor: p.surfaceBase,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[p],

      appBarTheme: AppBarTheme(
        backgroundColor: p.surfaceBase,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: p.shadow,
        centerTitle: false,
        titleSpacing: 20,
        iconTheme: IconThemeData(color: p.textPrimary, size: 24),
        titleTextStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 19,
          letterSpacing: -0.2,
          color: p.textPrimary,
        ),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          disabledBackgroundColor: p.surfaceSunken,
          disabledForegroundColor: p.textMuted,
          elevation: 0,
          minimumSize: const Size(64, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          minimumSize: const Size(64, minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.borderStrong),
          minimumSize: const Size(64, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brand,
          minimumSize: const Size(0, 44),
          textStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceSunken,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: p.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: p.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: p.danger, width: 1.6),
        ),
        labelStyle: TextStyle(color: p.textSecondary),
        floatingLabelStyle: TextStyle(color: p.brand),
        hintStyle: TextStyle(color: p.textMuted),
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textMuted,
        errorStyle: TextStyle(color: p.danger, fontSize: 12),
      ),

      cardTheme: CardThemeData(
        color: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: p.border),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surfaceBase,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.brandSubtle,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color:
                states.contains(WidgetState.selected) ? p.brand : p.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color:
                states.contains(WidgetState.selected) ? p.brand : p.textMuted,
          ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surfaceBase,
        selectedItemColor: p.brand,
        unselectedItemColor: p.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: p.surfaceBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        width: 312,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.horizontal(right: Radius.circular(radiusXLarge)),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        minLeadingWidth: 24,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.brand,
        foregroundColor: p.onBrand,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceInverse,
        contentTextStyle:
            GoogleFonts.outfit(color: p.textInverse, fontSize: 14),
        actionTextColor: p.brand,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceSunken,
        selectedColor: p.brandSubtle,
        checkmarkColor: p.brand,
        side: BorderSide(color: p.border),
        labelStyle: GoogleFonts.outfit(
            color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : p.surfaceBase),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.brand : p.borderStrong),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brand,
        linearTrackColor: p.surfaceSunken,
        circularTrackColor: Colors.transparent,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: p.brand,
        unselectedLabelColor: p.textMuted,
        indicatorColor: p.brand,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.border,
        labelStyle:
            GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.surfaceInverse,
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: GoogleFonts.outfit(color: p.textInverse, fontSize: 12),
      ),

      iconTheme: IconThemeData(color: p.textSecondary, size: 24),
    );
  }
}
