import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00F0FF); // Neon Cyan
  static const Color secondaryColor = Color(0xFFFF00AA); // Neon Magenta
  static const Color backgroundColor = Color(0xFF0A0E21); // Deep Space Blue
  static const Color surfaceColor = Color(0xFF1D1E33); // Dark Surface
  static const Color errorColor = Color(0xFFFF3B30);

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
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 10,
        shadowColor: Color.fromRGBO(
          primaryColor.r.toInt(),
          primaryColor.g.toInt(),
          primaryColor.b.toInt(),
          0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
  );

  // Custom Gradients and Shadows for 3D effects
  static const BoxShadow neonShadow = BoxShadow(
    color: primaryColor,
    blurRadius: 20,
    spreadRadius: -5,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF00A8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
