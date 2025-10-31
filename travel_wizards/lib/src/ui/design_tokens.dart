import 'package:flutter/material.dart';

/// Design tokens for Travel Wizards app following Material 3 guidelines.
///
/// This file provides a single source of truth for colors, typography, shapes, and spacing
/// aligned with M3 specifications and the app's design system.

class DesignTokens {
  DesignTokens._();

  // ================== Color Roles (M3) ==================

  /// Fallback Light Palette (Purple, Teal, Deep Orange theme)
  static const ColorScheme fallbackLightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF673AB7), // Deep Purple 600
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEADDFF),
    onPrimaryContainer: Color(0xFF21005E),
    secondary: Color(0xFF006A60), // Teal 700
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF6FF7D1),
    onSecondaryContainer: Color(0xFF00201B),
    tertiary: Color(0xFFFF5722), // Deep Orange 600
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDAD4),
    onTertiaryContainer: Color(0xFF410E0B),
    error: Color(0xFFD32F2F),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1B1B1B),
    surfaceContainerHighest: Color(0xFFE7E0EC),
    onSurfaceVariant: Color(0xFF49454F),
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF303030),
    onInverseSurface: Color(0xFFF0F0F0),
    inversePrimary: Color(0xFFCFBCFF),
    surfaceTint: Color(0xFF673AB7),
  );

  /// Fallback Dark Palette (Purple, Teal, Deep Orange theme)
  static const ColorScheme fallbackDarkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFCFBCFF), // Deep Purple 200
    onPrimary: Color(0xFF381E72),
    primaryContainer: Color(0xFF4F378B),
    onPrimaryContainer: Color(0xFFEADDFF),
    secondary: Color(0xFF4DD8C0), // Teal 200
    onSecondary: Color(0xFF00382E),
    secondaryContainer: Color(0xFF005142),
    onSecondaryContainer: Color(0xFF6FF7D1),
    tertiary: Color(0xFFFFB4A9), // Deep Orange 200
    onTertiary: Color(0xFF690005),
    tertiaryContainer: Color(0xFF93000A),
    onTertiaryContainer: Color(0xFFFFDAD4),
    error: Color(0xFFCF6679),
    onError: Color(0xFF0A0A0A),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFE3E3E3),
    surfaceContainerHighest: Color(0xFF49454F),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF939094),
    outlineVariant: Color(0xFF43474E),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE3E3E3),
    onInverseSurface: Color(0xFF303030),
    inversePrimary: Color(0xFF673AB7),
    surfaceTint: Color(0xFFCFBCFF),
  );

  // ================== Typography Scales (M3) ==================

  /// M3 Typography scale using Noto Sans as primary, Roboto as fallback
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.16,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.22,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.25,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.29,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.33,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.27,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.5,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
      fontFamily: 'Noto Sans',
      fontFamilyFallback: ['Roboto'],
    ),
  );

  // ================== Shape Radii ==================

  /// Small components radius
  static const double smallRadius = 8.0;

  /// Large surfaces radius
  static const double largeRadius = 16.0;

  /// Card radius
  static const double cardRadius = 12.0;

  /// Button radius
  static const double buttonRadius = 8.0;

  /// Avatar radius
  static const double avatarRadius = 24.0;

  // ================== Spacing Constants ==================

  /// Base spacing unit (8dp)
  static const double space1 = 8.0;
  static const double space2 = 16.0;
  static const double space3 = 24.0;
  static const double space4 = 32.0;
  static const double space5 = 48.0;
  static const double space6 = 64.0;

  /// Common gaps
  static const double gapSmall = 8.0;
  static const double gapMedium = 16.0;
  static const double gapLarge = 24.0;

  /// Padding constants
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // ================== Elevation Scales (M3) ==================

  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 3.0;
  static const double elevation3 = 6.0;
  static const double elevation4 = 8.0;
  static const double elevation5 = 12.0;
}
