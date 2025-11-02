import 'package:flutter/material.dart';

/// Travel Wizards color system with travel-inspired theming.
///
/// This class defines a comprehensive color palette that evokes travel,
/// adventure, and exploration while maintaining accessibility standards.
class TravelColors {
  TravelColors._();

  // ================== Core Travel Color Palette ==================

  /// Primary Sky Blue - Represents sky, ocean, trust, and reliability
  static const Color skyBlue = Color(0xFF2196F3);
  static const Color skyBlueLight = Color(0xFF64B5F6);
  static const Color skyBlueDark = Color(0xFF1565C0);

  /// Secondary Sunset Orange - Represents adventure, warmth, and sunsets
  static const Color sunsetOrange = Color(0xFFFF9800);
  static const Color sunsetOrangeLight = Color(0xFFFFCC02);
  static const Color sunsetOrangeDark = Color(0xFFE65100);

  /// Tertiary Earth Green - Represents nature, sustainability, and growth
  static const Color earthGreen = Color(0xFF4CAF50);
  static const Color earthGreenLight = Color(0xFF81C784);
  static const Color earthGreenDark = Color(0xFF2E7D32);

  // ================== Trip Type Semantic Colors ==================

  /// Adventure trips - Mountain Orange
  static const Color adventure = Color(0xFFFF5722);
  static const Color adventureLight = Color(0xFFFF8A65);
  static const Color adventureDark = Color(0xFFD84315);

  /// Relaxation trips - Ocean Teal
  static const Color relaxation = Color(0xFF009688);
  static const Color relaxationLight = Color(0xFF4DB6AC);
  static const Color relaxationDark = Color(0xFF00695C);

  /// Business trips - Professional Navy
  static const Color business = Color(0xFF1565C0);
  static const Color businessLight = Color(0xFF42A5F5);
  static const Color businessDark = Color(0xFF0D47A1);

  /// Family trips - Warm Purple
  static const Color family = Color(0xFF7B1FA2);
  static const Color familyLight = Color(0xFFBA68C8);
  static const Color familyDark = Color(0xFF4A148C);

  /// Cultural trips - Historic Gold
  static const Color cultural = Color(0xFFF57C00);
  static const Color culturalLight = Color(0xFFFFB74D);
  static const Color culturalDark = Color(0xFFE65100);

  /// Food/culinary trips - Spice Red
  static const Color food = Color(0xFFD32F2F);
  static const Color foodLight = Color(0xFFEF5350);
  static const Color foodDark = Color(0xFFB71C1C);

  // ================== Status Colors ==================

  /// Booked/confirmed status
  static const Color booked = Color(0xFF388E3C);
  static const Color bookedLight = Color(0xFF66BB6A);
  static const Color bookedDark = Color(0xFF1B5E20);

  /// Pending/in-progress status
  static const Color pending = Color(0xFFF57C00);
  static const Color pendingLight = Color(0xFFFFB74D);
  static const Color pendingDark = Color(0xFFE65100);

  /// Cancelled/error status
  static const Color cancelled = Color(0xFFD32F2F);
  static const Color cancelledLight = Color(0xFFEF5350);
  static const Color cancelledDark = Color(0xFFB71C1C);

  /// Draft/not-started status
  static const Color draft = Color(0xFF757575);
  static const Color draftLight = Color(0xFFA1A1A1);
  static const Color draftDark = Color(0xFF424242);

  // ================== Utility Methods ==================

  /// Get trip type color based on category
  static Color getTripTypeColor(String tripType) {
    switch (tripType.toLowerCase()) {
      case 'adventure':
        return adventure;
      case 'relaxation':
      case 'leisure':
        return relaxation;
      case 'business':
        return business;
      case 'family':
        return family;
      case 'cultural':
      case 'heritage':
        return cultural;
      case 'food':
      case 'culinary':
        return food;
      default:
        return skyBlue; // Default to primary color
    }
  }

  /// Get status color based on booking status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
      case 'confirmed':
      case 'active':
        return booked;
      case 'pending':
      case 'in-progress':
      case 'processing':
        return pending;
      case 'cancelled':
      case 'failed':
      case 'error':
        return cancelled;
      case 'draft':
      case 'not-started':
      case 'planning':
        return draft;
      default:
        return draft;
    }
  }

  /// Create a travel-themed light color scheme
  static ColorScheme lightTravelScheme() {
    return ColorScheme.fromSeed(
      seedColor: skyBlue,
      brightness: Brightness.light,
      primary: skyBlue,
      secondary: sunsetOrange,
      tertiary: earthGreen,
      error: cancelled,
      // Custom surface colors for travel theme
      surface: const Color(0xFFFAFAFA), // Clean, bright surface
      surfaceContainerHighest: const Color(0xFFE8F4FD), // Sky-tinted container
    );
  }

  /// Create a travel-themed dark color scheme
  static ColorScheme darkTravelScheme() {
    return ColorScheme.fromSeed(
      seedColor: skyBlue,
      brightness: Brightness.dark,
      primary: skyBlueLight,
      secondary: sunsetOrangeLight,
      tertiary: earthGreenLight,
      error: cancelledLight,
      // Custom surface colors for dark travel theme
      surface: const Color(0xFF121212), // Material dark surface
      surfaceContainerHighest: const Color(
        0xFF1E2A3A,
      ), // Dark blue-tinted container
    );
  }

  // ================== Accessibility Helpers ==================

  /// Check if a color provides sufficient contrast against white background
  static bool hasGoodContrastOnWhite(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
  }

  /// Check if a color provides sufficient contrast against dark background
  static bool hasGoodContrastOnDark(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.light;
  }

  /// Get appropriate text color (black/white) for given background color
  static Color getContrastingTextColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}

/// Extension on ColorScheme to add travel-specific color properties
extension TravelColorScheme on ColorScheme {
  /// Adventure trip color
  Color get adventure => brightness == Brightness.light
      ? TravelColors.adventure
      : TravelColors.adventureLight;

  /// Relaxation trip color
  Color get relaxation => brightness == Brightness.light
      ? TravelColors.relaxation
      : TravelColors.relaxationLight;

  /// Business trip color
  Color get business => brightness == Brightness.light
      ? TravelColors.business
      : TravelColors.businessLight;

  /// Family trip color
  Color get family => brightness == Brightness.light
      ? TravelColors.family
      : TravelColors.familyLight;

  /// Cultural trip color
  Color get cultural => brightness == Brightness.light
      ? TravelColors.cultural
      : TravelColors.culturalLight;

  /// Food trip color
  Color get food => brightness == Brightness.light
      ? TravelColors.food
      : TravelColors.foodLight;

  /// Booked status color
  Color get booked => brightness == Brightness.light
      ? TravelColors.booked
      : TravelColors.bookedLight;

  /// Pending status color
  Color get pending => brightness == Brightness.light
      ? TravelColors.pending
      : TravelColors.pendingLight;

  /// Cancelled status color
  Color get cancelled => brightness == Brightness.light
      ? TravelColors.cancelled
      : TravelColors.cancelledLight;

  /// Draft status color
  Color get draft => brightness == Brightness.light
      ? TravelColors.draft
      : TravelColors.draftLight;
}
