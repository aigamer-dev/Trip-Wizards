import 'package:flutter/material.dart';
import 'travel_colors.dart';
import 'travel_typography.dart';

// Travel-themed Light and Dark color schemes
final ColorScheme kTravelLightScheme = TravelColors.lightTravelScheme();
final ColorScheme kTravelDarkScheme = TravelColors.darkTravelScheme();

// Fallback Light and Dark color schemes per ToDo.md
final ColorScheme kFallbackLightScheme = ColorScheme.fromSeed(
  seedColor: Colors.blueAccent,
  brightness: Brightness.light,
);

final ColorScheme kFallbackDarkScheme = ColorScheme.fromSeed(
  seedColor: Colors.blueAccent,
  brightness: Brightness.dark,
);

ThemeData themeFromScheme(ColorScheme scheme) {
  // Use travel-themed typography system
  final textTheme = TravelTypography.createTravelTextTheme(scheme);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: textTheme,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 5,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: TravelBorderRadius.cardRadius,
      ),
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 2, // Slightly higher elevation for travel cards
      shape: RoundedRectangleBorder(
        borderRadius: TravelBorderRadius.cardRadius,
      ),
      margin: TravelSpacing.tripCardPadding,
      surfaceTintColor: scheme.surfaceTint,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: TravelBorderRadius.chipRadius,
      ), // More rounded for travel theme
      selectedColor: scheme.secondaryContainer,
      disabledColor: scheme.surfaceContainerHighest,
      side: BorderSide(color: scheme.outline, width: 1),
      labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      padding: TravelSpacing.chipPadding,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: TravelBorderRadius.buttonRadius,
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: TravelBorderRadius.buttonRadius,
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: TravelBorderRadius.buttonRadius,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: TravelBorderRadius.buttonRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: TravelBorderRadius.buttonRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(color: scheme.outline),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: TravelBorderRadius.smallRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: TravelBorderRadius.smallRadius,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
  );
}

/// Create a travel-themed light theme
ThemeData createTravelLightTheme() {
  return themeFromScheme(kTravelLightScheme);
}

/// Create a travel-themed dark theme
ThemeData createTravelDarkTheme() {
  return themeFromScheme(kTravelDarkScheme);
}

/// Create fallback light theme (maintains compatibility)
ThemeData createFallbackLightTheme() {
  return themeFromScheme(kFallbackLightScheme);
}

/// Create fallback dark theme (maintains compatibility)
ThemeData createFallbackDarkTheme() {
  return themeFromScheme(kFallbackDarkScheme);
}
