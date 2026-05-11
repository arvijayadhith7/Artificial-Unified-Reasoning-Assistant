import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // New Professional Palette
  static const Color background = Color(0xFF212121);
  static const Color sidebar = Color(0xFF171717);
  static const Color surface = Color(0xFF2F2F2F);
  
  static const Color primaryGreen = Color(0xFF10A37F);
  static const Color hoverGreen = Color(0xFF19C37D);
  
  static const Color userBubble = Color(0xFF303030);
  static const Color aiBubble = Color(0xFF444654);
  
  static const Color textPrimary = Color(0xFFECECEC);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color border = Color(0xFF3A3A3A);

  // Keep these for internal logic/backwards compatibility if needed, but updated to fit
  static const Color neonBlue = primaryGreen; 
  static const Color neonPurple = Color(0xFF5C72FF); // Adjusted for the new theme
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryGreen,
      hintColor: AppColors.textSecondary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGreen,
        secondary: AppColors.hoverGreen,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        background: AppColors.background,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1.0,
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
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );
  }
}
