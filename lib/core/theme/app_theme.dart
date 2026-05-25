import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Design System from HTML Templates
  static const Color primaryColor = Color(0xFF00D66C); // Green accent
  static const Color primaryForeground = Color(0xFF00210E); // Dark green for text on primary
  static const Color secondaryColor = Color(0xFF1E1E1E); // Card/secondary bg
  static const Color secondaryForeground = Color(0xFFFAFAFA); // White text
  
  static const Color backgroundColor = Color(0xFF050505); // Main dark background
  static const Color surfaceColor = Color(0xFF101010); // Card surface
  static const Color cardColor = Color(0xFF121212); // Slightly lighter cards
  
  static const Color mutedColor = Color(0xFF27272A); // Borders
  static const Color mutedForeground = Color(0xFFA1A1AA); // Secondary text
  static const Color inputColor = Color(0xFF18181B); // Input background
  
  static const Color errorColor = Color(0xFFEF4444);

  // Neomorphic shadow colors
  static const Color shadowDark = Color(0xFF008F48); // Dark green shadow for 3D effect
  static const Color shadowLight = Color(0xFF1E1E1E); // Dark shadow for cards

  static final ThemeData futuristicTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: primaryForeground,
      onSecondary: secondaryForeground,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: primaryForeground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputColor.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: mutedForeground),
      hintStyle: const TextStyle(color: mutedForeground),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0A0A0A).withValues(alpha: 0.95),
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.white.withValues(alpha: 0.6),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );

  // Neomorphic Button Shadows (3D effect from HTML)
  static List<BoxShadow> neomorphicShadow({Color? color}) => [
    BoxShadow(
      color: color ?? shadowLight,
      offset: const Offset(0, 8),
      blurRadius: 0,
    ),
  ];

  static List<BoxShadow> neomorphicShadowPressed({Color? color}) => [
    BoxShadow(
      color: color ?? shadowLight,
      offset: const Offset(0, 2),
      blurRadius: 0,
    ),
  ];

  // Primary button 3D shadow (green shadow)
  static List<BoxShadow> primaryNeomorphicShadow = [
    const BoxShadow(
      color: shadowDark,
      offset: Offset(0, 8),
      blurRadius: 0,
    ),
  ];

  static List<BoxShadow> primaryNeomorphicShadowPressed = [
    const BoxShadow(
      color: shadowDark,
      offset: Offset(0, 2),
      blurRadius: 0,
    ),
  ];

  // Glow effects
  static BoxShadow glowShadow(Color color, {double blur = 20}) => BoxShadow(
    color: color.withValues(alpha: 0.4),
    blurRadius: blur,
    spreadRadius: 0,
  );

  // Glass shadow for glass card effect
  static BoxShadow glassShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.2),
    blurRadius: 20,
    offset: const Offset(0, 5),
  );

  // Glass card decoration
  static BoxDecoration glassDecoration = BoxDecoration(
    color: secondaryColor.withValues(alpha: 0.3),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
  );

  // Gradient backgrounds
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundColor, Color(0xFF0A0A0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF00FF94)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF004D26), Color(0xFF00210E)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Heading text style
  static TextStyle headingStyle({double fontSize = 24, Color color = Colors.white}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: color,
    );
  }

  // Body text style
  static TextStyle bodyStyle({double fontSize = 14, Color color = mutedForeground}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      color: color,
    );
  }
}
