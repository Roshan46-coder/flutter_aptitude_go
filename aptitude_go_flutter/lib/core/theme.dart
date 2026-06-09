import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark theme surface colors
  static const Color darkBackground = Color(0xFF0D0E12);
  static const Color darkSurface = Color(0xFF161820);
  static const Color darkCardBg = Color(0xFF1E212E);
  static const Color darkDivider = Color(0xFF2C3043);

  // Light theme surface colors
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBg = Color(0xFFF0F0F3);
  static const Color lightDivider = Color(0xFFE0E0E0);

  // Brand colors (identical in both themes)
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color neonBlue = Color(0xFF3B82F6);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color livesRed = Color(0xFFEF4444);
  static const Color goldAccent = Color(0xFFFBBF24);

  // Backwards-compatible aliases (point to dark values)
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color cardBg = darkCardBg;
  static const Color divider = darkDivider;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: neonPurple,
      colorScheme: const ColorScheme.dark(
        primary: neonPurple,
        secondary: neonBlue,
        surface: darkSurface,
        error: livesRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white54,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkDivider, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: const TextStyle(color: Colors.white30),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkDivider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkDivider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: neonPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: livesRed, width: 1),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: neonPurple,
        textTheme: ButtonTextTheme.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: neonPurple,
      colorScheme: const ColorScheme.light(
        primary: neonPurple,
        secondary: neonBlue,
        surface: lightSurface,
        error: livesRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.black87,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightDivider, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        hintStyle: const TextStyle(color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightDivider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightDivider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: neonPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: livesRed, width: 1),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: neonPurple,
        textTheme: ButtonTextTheme.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
    );
  }
}

extension ThemeColors on BuildContext {
  Color get background => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get cardBgColor => Theme.of(this).cardTheme.color ?? Theme.of(this).colorScheme.surface;
  Color get dividerColor => Theme.of(this).dividerColor;
  Color get onSurface => Theme.of(this).colorScheme.onSurface;
}
