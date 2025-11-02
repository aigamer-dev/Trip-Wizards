import 'package:flutter/material.dart';
import '../../ui/design_tokens.dart';

/// App theme management following Material 3 guidelines with dynamic color support.

class AppTheme {
  AppTheme._();

  /// Light theme using dynamic color with fallback
  static ThemeData light = _createTheme(Brightness.light);

  /// Dark theme using dynamic color with fallback
  static ThemeData dark = _createTheme(Brightness.dark);

  /// Create theme data with dynamic color support
  static ThemeData _createTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final baseScheme = isLight
        ? DesignTokens.fallbackLightScheme
        : DesignTokens.fallbackDarkScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      textTheme: DesignTokens.textTheme.apply(
        bodyColor: baseScheme.onSurface,
        displayColor: baseScheme.onSurface,
      ),
      scaffoldBackgroundColor: baseScheme.surface,
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
        backgroundColor: baseScheme.surface.withValues(alpha: 0.92),
        foregroundColor: baseScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: DesignTokens.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: baseScheme.onSurface,
        ),
        toolbarHeight: 80,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseScheme.primaryContainer,
        foregroundColor: baseScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.largeRadius),
        ),
        elevation: DesignTokens.elevation3,
      ),
      cardTheme: CardThemeData(
        elevation: DesignTokens.elevation0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        margin: EdgeInsets.all(DesignTokens.space1),
        surfaceTintColor: baseScheme.surfaceTint,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: DesignTokens.elevation0,
        backgroundColor: baseScheme.surfaceContainer,
        indicatorColor: baseScheme.secondaryContainer,
        surfaceTintColor: baseScheme.surfaceTint,
        shadowColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? baseScheme.onPrimaryContainer
                : baseScheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => DesignTokens.textTheme.labelLarge?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? baseScheme.onPrimaryContainer
                : baseScheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: baseScheme.secondaryContainer,
        elevation: DesignTokens.elevation0,
        selectedIconTheme: IconThemeData(
          color: baseScheme.onPrimaryContainer,
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: baseScheme.onSurfaceVariant,
          size: 26,
        ),
        selectedLabelTextStyle: DesignTokens.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: baseScheme.onPrimaryContainer,
        ),
        unselectedLabelTextStyle: DesignTokens.textTheme.titleSmall?.copyWith(
          color: baseScheme.onSurfaceVariant,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: baseScheme.surface,
        surfaceTintColor: baseScheme.surfaceTint,
        indicatorColor: baseScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        elevation: DesignTokens.elevation0,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: baseScheme.surface,
        surfaceTintColor: baseScheme.surfaceTint,
        elevation: DesignTokens.elevation1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.smallRadius),
        ),
        selectedColor: baseScheme.secondaryContainer,
        disabledColor: baseScheme.surfaceContainerHighest,
        side: BorderSide(color: baseScheme.outline, width: 1),
        labelStyle: DesignTokens.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space2,
          vertical: DesignTokens.space1,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: baseScheme.inverseSurface,
        contentTextStyle: DesignTokens.textTheme.bodyMedium?.copyWith(
          color: baseScheme.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space2,
          vertical: DesignTokens.space1 + DesignTokens.space1,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        modalBackgroundColor: baseScheme.surface,
        backgroundColor: baseScheme.surfaceDim,
        surfaceTintColor: baseScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: baseScheme.surface,
        surfaceTintColor: baseScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        elevation: DesignTokens.elevation3,
        titleTextStyle: DesignTokens.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: baseScheme.onSurface,
        ),
        contentTextStyle: DesignTokens.textTheme.bodyMedium?.copyWith(
          color: baseScheme.onSurfaceVariant,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            ),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: 18,
              vertical: DesignTokens.space1 + DesignTokens.space1,
            ),
          ),
          textStyle: WidgetStateProperty.all(
            DesignTokens.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          borderSide: BorderSide(color: baseScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          borderSide: BorderSide(color: baseScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          borderSide: BorderSide(color: baseScheme.primary, width: 2),
        ),
        hintStyle: DesignTokens.textTheme.bodyMedium?.copyWith(
          color: baseScheme.onSurfaceVariant,
        ),
        labelStyle: DesignTokens.textTheme.bodyMedium?.copyWith(
          color: baseScheme.onSurfaceVariant,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: DesignTokens.space1 + DesignTokens.space1,
          ),
          textStyle: DesignTokens.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: DesignTokens.space1 + DesignTokens.space1,
          ),
          side: BorderSide(color: baseScheme.outline),
          textStyle: DesignTokens.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.smallRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space2,
            vertical: DesignTokens.space1,
          ),
          textStyle: DesignTokens.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.smallRadius),
          ),
          foregroundColor: baseScheme.onSurface,
          hoverColor: baseScheme.primary.withValues(alpha: 0.08),
          focusColor: baseScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.smallRadius),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space2,
          vertical: DesignTokens.space1,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: baseScheme.outlineVariant,
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
          baseScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  /// Get theme data with dynamic color support
  static Future<ThemeData> getThemeWithDynamicColor(
    Brightness brightness,
    Color? dynamicPrimaryColor,
  ) async {
    final baseTheme = brightness == Brightness.light ? light : dark;

    if (dynamicPrimaryColor != null) {
      final dynamicScheme = ColorScheme.fromSeed(
        seedColor: dynamicPrimaryColor,
        brightness: brightness,
      );
      return baseTheme.copyWith(colorScheme: dynamicScheme);
    }

    return baseTheme;
  }
}

/// Theme provider for managing app theme state
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _reducedMotion = false;

  ThemeMode get themeMode => _themeMode;
  bool get reducedMotion => _reducedMotion;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setReducedMotion(bool value) {
    _reducedMotion = value;
    notifyListeners();
  }

  ThemeData getTheme(BuildContext context, {Color? dynamicPrimaryColor}) {
    final brightness = _getBrightness(context);
    return brightness == Brightness.light ? AppTheme.light : AppTheme.dark;
  }

  Brightness _getBrightness(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }
}
