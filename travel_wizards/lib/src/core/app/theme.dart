import 'package:flutter/material.dart';
import 'travel_colors.dart';
import 'travel_typography.dart';

// Travel-themed Light and Dark color schemes
final ColorScheme kTravelLightScheme = TravelColors.lightTravelScheme();
final ColorScheme kTravelDarkScheme = TravelColors.darkTravelScheme();

// Fallback Light and Dark color schemes per ToDo.md
final ColorScheme kFallbackLightScheme = ColorScheme.fromSeed(
  seedColor: Colors.deepOrange,
  brightness: Brightness.light,
);

final ColorScheme kFallbackDarkScheme = ColorScheme.fromSeed(
  seedColor: Colors.deepPurple,
  brightness: Brightness.dark,
);

ThemeData themeFromScheme(ColorScheme scheme) {
  // Use travel-themed typography system
  final textTheme = TravelTypography.createTravelTextTheme(scheme);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textTheme,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      },
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface.withValues(alpha: 0.92),
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      toolbarHeight: 80,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
    ),
    cardTheme: CardThemeData(
      elevation: 0, // Material 3 uses surface tints instead of elevation
      shape: RoundedRectangleBorder(
        borderRadius: TravelBorderRadius.cardRadius,
      ),
      margin: TravelSpacing.tripCardPadding,
      surfaceTintColor: scheme.surfaceTint,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 80,
      elevation: 0,
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.secondaryContainer,
      surfaceTintColor: scheme.surfaceTint,
      shadowColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 26,
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelLarge?.copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: scheme.secondaryContainer,
      elevation: 0,
      selectedIconTheme: IconThemeData(
        color: scheme.onPrimaryContainer,
        size: 28,
      ),
      unselectedIconTheme: IconThemeData(
        color: scheme.onSurfaceVariant,
        size: 26,
      ),
      selectedLabelTextStyle: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onPrimaryContainer,
      ),
      unselectedLabelTextStyle: textTheme.titleSmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      elevation: 0,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: TravelBorderRadius.cardRadius,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      modalBackgroundColor: scheme.surface,
      backgroundColor: scheme.surfaceDim,
      surfaceTintColor: scheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: TravelBorderRadius.cardRadius,
      ),
      elevation: 3,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: TravelBorderRadius.buttonRadius),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        textStyle: WidgetStateProperty.all(
          textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
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
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: TravelBorderRadius.smallRadius,
        ),
        foregroundColor: scheme.onSurface,
        hoverColor: scheme.primary.withValues(alpha: 0.08),
        focusColor: scheme.primary.withValues(alpha: 0.12),
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
    scrollbarTheme: ScrollbarThemeData(
      interactive: true,
      radius: const Radius.circular(24),
      thumbVisibility: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.dragged),
      ),
      thickness: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.dragged) ? 8 : 5,
      ),
      thumbColor: WidgetStateProperty.all(
        scheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
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
