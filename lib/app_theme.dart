import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color sidebar = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF121212);
  
  static const Color electricBlue = Color(0xFF0066FF);
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color violetGlow = Color(0xFF8B00FF);
  
  static const Color glassFill = Color(0x1AFFFFFF); 
  static const Color glassBorder = Color(0x33FFFFFF); 
  
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color border = Color(0xFF1A1A1A);

  static const Color primaryBlue = electricBlue;
  static const Color accentCyan = neonCyan;
}

class AppTheme {
  static Color getAccentColor(String colorKey) {
    switch (colorKey.toLowerCase()) {
      case 'blue':
        return const Color(0xFF0066FF);
      case 'violet':
        return const Color(0xFF8B00FF);
      case 'orange':
        return const Color(0xFFFF5722); // Vibrant Orange
      case 'green':
        return const Color(0xFF00E676); // Neon Green
      case 'cyan':
      default:
        return const Color(0xFF00FFFF);
    }
  }

  static ThemeData getDynamicTheme({
    required String themeMode,
    required String accentColor,
    required double fontScale,
    required String density,
  }) {
    final isDark = themeMode.toUpperCase() == 'DARK';
    final accent = getAccentColor(accentColor);
    
    // Background and Surface selections
    final bg = isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF121212) : const Color(0xFFF1F3F5);
    final border = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE9ECEF);
    
    // Text color selections
    final textPrimary = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF212529);
    final textSecondary = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF6C757D);

    // Padding settings based on density
    double getDensitySpacing() {
      switch (density.toUpperCase()) {
        case 'COMPACT':
          return -2.0;
        case 'COMFY':
          return 2.0;
        case 'COZY':
        default:
          return 0.0;
      }
    }

    final spacing = getDensitySpacing();

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      hintColor: textSecondary,
      visualDensity: VisualDensity(horizontal: spacing, vertical: spacing),
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: accent,
              secondary: accent.withOpacity(0.8),
              tertiary: AppColors.violetGlow,
              surface: cardBg,
              onSurface: textPrimary,
              background: bg,
            )
          : ColorScheme.light(
              primary: accent,
              secondary: accent.withOpacity(0.8),
              tertiary: AppColors.violetGlow,
              surface: cardBg,
              onSurface: textPrimary,
              background: bg,
            ),
      textTheme: GoogleFonts.outfitTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            fontSize: 48 * fontScale,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -1.0,
            shadows: isDark
                ? [Shadow(color: accent.withOpacity(0.3), blurRadius: 20)]
                : null,
          ),
          displayMedium: TextStyle(
            fontSize: 28 * fontScale,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 22 * fontScale,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16 * fontScale,
            color: textPrimary,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 14 * fontScale,
            color: textSecondary,
            height: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isDark ? 8 : 4,
          shadowColor: accent.withOpacity(0.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
      ),
    );
  }

  // Backward compatibility
  static ThemeData get darkTheme => getDynamicTheme(
        themeMode: 'DARK',
        accentColor: 'cyan',
        fontScale: 1.0,
        density: 'COZY',
      );
}
