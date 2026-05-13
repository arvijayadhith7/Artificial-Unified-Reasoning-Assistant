import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // LaternTech AI - Futuristic Premium Palette
  static const Color background = Color(0xFF000000);
  static const Color sidebar = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF121212);
  
  static const Color electricBlue = Color(0xFF0066FF);
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color violetGlow = Color(0xFF8B00FF);
  
  static const Color glassFill = Color(0x1AFFFFFF); // 10% white for glass effect
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white for border
  
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color border = Color(0xFF1A1A1A);

  // Aliases for compatibility
  static const Color primaryBlue = electricBlue;
  static const Color accentCyan = neonCyan;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.electricBlue,
      hintColor: AppColors.textSecondary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricBlue,
        secondary: AppColors.neonCyan,
        tertiary: AppColors.violetGlow,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        background: AppColors.background,
      ),
      textTheme: GoogleFonts.outfitTextTheme( // Using Outfit for a more futuristic feel
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1.0,
            shadows: [
              Shadow(color: AppColors.electricBlue, blurRadius: 20),
            ],
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: AppColors.electricBlue.withOpacity(0.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );
  }
}
