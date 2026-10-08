import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // Spacing System (8pt Grid)
  // ---------------------------------------------------------------------------
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // ---------------------------------------------------------------------------
  // Color Tokens
  // ---------------------------------------------------------------------------
  // Backgrounds
  static Color backgroundPrimary = const Color(0xFF0D1210); // Deep Operational Green
  static Color backgroundSecondary = const Color(0xFF141C18); // Elevated Surface
  static Color backgroundTertiary = const Color(0xFF1A241F); // Highest Elevation / Inputs

  // Brand Accents
  static Color primaryGreen = const Color(0xFF244033);
  static Color primaryGreenHover = const Color(0xFF2A4C3C);
  static Color militaryOlive = const Color(0xFF868A78);

  // Semantic Status
  static Color successGreen = const Color(0xFF34C759); // Apple-like crisp green
  static Color warningAmber = const Color(0xFFFF9F0A); // Apple-like crisp amber
  static Color criticalRed = const Color(0xFFFF453A); // Apple-like crisp red
  static Color infoBlue = const Color(0xFF0A84FF);

  // Borders
  static Color borderSubtle = const Color(0x1AFFFFFF); // 10% white
  static Color borderStrong = const Color(0x33FFFFFF); // 20% white

  // Text
  static Color textPrimary = const Color(0xFFF2F2F2);
  static Color textSecondary = const Color(0xFFA1A1AA); // Zinc 400
  static Color textMuted = const Color(0xFF71717A); // Zinc 500

  static void setLightMode() {
    backgroundPrimary = const Color(0xFFF9FAFB); 
    backgroundSecondary = const Color(0xFFFFFFFF); 
    backgroundTertiary = const Color(0xFFF3F4F6); 
    primaryGreen = const Color(0xFF34D399);
    primaryGreenHover = const Color(0xFF10B981);
    militaryOlive = const Color(0xFF6B7280);
    successGreen = const Color(0xFF34C759); 
    warningAmber = const Color(0xFFFF9F0A); 
    criticalRed = const Color(0xFFFF453A); 
    infoBlue = const Color(0xFF0A84FF);
    borderSubtle = const Color(0x1A000000); 
    borderStrong = const Color(0x33000000); 
    textPrimary = const Color(0xFF111827);
    textSecondary = const Color(0xFF4B5563); 
    textMuted = const Color(0xFF9CA3AF); 
  }

  static void setDarkMode() {
    backgroundPrimary = const Color(0xFF0D1210); 
    backgroundSecondary = const Color(0xFF141C18); 
    backgroundTertiary = const Color(0xFF1A241F); 
    primaryGreen = const Color(0xFF244033);
    primaryGreenHover = const Color(0xFF2A4C3C);
    militaryOlive = const Color(0xFF868A78);
    successGreen = const Color(0xFF34C759); 
    warningAmber = const Color(0xFFFF9F0A); 
    criticalRed = const Color(0xFFFF453A); 
    infoBlue = const Color(0xFF0A84FF);
    borderSubtle = const Color(0x1AFFFFFF); 
    borderStrong = const Color(0x33FFFFFF); 
    textPrimary = const Color(0xFFF2F2F2);
    textSecondary = const Color(0xFFA1A1AA); 
    textMuted = const Color(0xFF71717A); 
  }

  // Backward compatibility aliases (to be replaced progressively)
  static Color get background => backgroundPrimary;
  static Color get cardBackground => backgroundSecondary;
  static Color get inputBackground => backgroundTertiary;
  static Color get textLight => textPrimary;

  // ---------------------------------------------------------------------------
  // Radii
  // ---------------------------------------------------------------------------
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(6));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(9999));

  // ---------------------------------------------------------------------------
  // Theme Data
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.heeboTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundPrimary,
      primaryColor: primaryGreen,
      
      // Typography
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: -1.0),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textPrimary, fontSize: 16),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondary, fontSize: 14),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: textSecondary, fontWeight: FontWeight.w500),
      ),

      colorScheme: ColorScheme.dark(
        primary: primaryGreen,
        secondary: militaryOlive,
        surface: backgroundSecondary,
        error: criticalRed,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      
      dividerColor: borderSubtle,
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
        border: const OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: criticalRed, width: 2),
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: textMuted),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(color: textSecondary),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),

      // Override default behaviors that feel un-premium
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.heeboTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundPrimary,
      primaryColor: primaryGreen,
      
      // Typography
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: -1.0),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textPrimary, fontSize: 16),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondary, fontSize: 14),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: textSecondary, fontWeight: FontWeight.w500),
      ),

      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: militaryOlive,
        surface: backgroundSecondary,
        error: criticalRed,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      
      dividerColor: borderSubtle,
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
        border: const OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: criticalRed, width: 2),
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: textMuted),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(color: textSecondary),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),

      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }
}
