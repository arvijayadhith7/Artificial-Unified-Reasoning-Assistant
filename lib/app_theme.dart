import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF121212);
  static const Color neonBlue = Color(0xFF00D9FF);
  static const Color neonPurple = Color(0xFF7A5CFF);
  static const Color accentCyan = Color(0xFF00F0FF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color cardGlow = Color(0x0D00D9FF);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.neonBlue,
      hintColor: AppColors.neonPurple,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonBlue,
        secondary: AppColors.neonPurple,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -2.0,
            height: 1.1,
          ),
          displayMedium: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -1.0,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonBlue,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
