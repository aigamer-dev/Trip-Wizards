import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Travel Wizards typography system with travel-optimized text styles.
///
/// This class provides a comprehensive typography hierarchy designed for
/// travel content, with enhanced readability for destinations, itineraries,
/// and travel information.
class TravelTypography {
  TravelTypography._();

  // ================== Font Families ==================

  /// Primary font family for headings and emphasis
  static const String primaryFontFamily = 'Noto Sans';

  /// Secondary font family for body text and details
  static const String bodyFontFamily = 'Noto Sans';

  // ================== Travel-Specific Text Styles ==================

  /// Large destination titles (city/country names)
  static TextStyle destinationTitle(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: colorScheme.onSurface,
      height: 1.2,
    );
  }

  /// Medium destination names (for cards and lists)
  static TextStyle destinationName(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: colorScheme.onSurface,
      height: 1.3,
    );
  }

  /// Trip titles and important headings
  static TextStyle tripTitle(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: colorScheme.onSurface,
      height: 1.25,
    );
  }

  /// Activity and itinerary item titles
  static TextStyle activityTitle(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      height: 1.3,
    );
  }

  /// Price display text (prominent pricing)
  static TextStyle priceDisplay(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: colorScheme.primary,
      height: 1.2,
    );
  }

  /// Large price text for featured pricing
  static TextStyle priceLarge(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: colorScheme.primary,
      height: 1.1,
    );
  }

  /// Small price text for compact displays
  static TextStyle priceSmall(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: colorScheme.primary,
      height: 1.2,
    );
  }

  /// Time and date displays
  static TextStyle timeDisplay(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: colorScheme.primary,
      height: 1.2,
    );
  }

  /// Duration text (e.g., "2h 30m", "3 days")
  static TextStyle duration(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurfaceVariant,
      height: 1.3,
    );
  }

  /// Location and address text
  static TextStyle locationText(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurfaceVariant,
      height: 1.4,
    );
  }

  /// Description and body text for travel content
  static TextStyle travelDescription(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurface,
      height: 1.5,
    );
  }

  /// Compact description for cards
  static TextStyle descriptionCompact(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurfaceVariant,
      height: 1.4,
    );
  }

  /// Status and badge text
  static TextStyle statusText(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: colorScheme.onSurface,
      height: 1.2,
    );
  }

  /// Chip and filter text
  static TextStyle chipText(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
      height: 1.2,
    );
  }

  /// Caption text for images and details
  static TextStyle caption(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurfaceVariant,
      height: 1.3,
    );
  }

  /// Error and warning text
  static TextStyle errorText(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: colorScheme.error,
      height: 1.4,
    );
  }

  /// Success and confirmation text
  static TextStyle successText(ColorScheme colorScheme) {
    return GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF388E3C), // Travel green from TravelColors
      height: 1.4,
    );
  }

  // ================== Utility Methods ==================

  /// Create a travel-themed text theme
  static TextTheme createTravelTextTheme(ColorScheme colorScheme) {
    final baseTheme = GoogleFonts.notoSansTextTheme();

    return baseTheme.copyWith(
      // Headlines
      displayLarge: destinationTitle(colorScheme),
      displayMedium: tripTitle(colorScheme),
      displaySmall: destinationName(colorScheme),

      // Titles
      headlineLarge: tripTitle(colorScheme),
      headlineMedium: destinationName(colorScheme),
      headlineSmall: activityTitle(colorScheme),

      // Body text
      titleLarge: activityTitle(colorScheme),
      titleMedium: GoogleFonts.notoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      titleSmall: GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.3,
      ),

      // Body styles
      bodyLarge: travelDescription(colorScheme),
      bodyMedium: GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      bodySmall: descriptionCompact(colorScheme),

      // Labels
      labelLarge: chipText(colorScheme),
      labelMedium: GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      labelSmall: caption(colorScheme),
    );
  }

  /// Get text style for specific travel content types
  static TextStyle getStyleForContent(
    String contentType,
    ColorScheme colorScheme,
  ) {
    switch (contentType.toLowerCase()) {
      case 'destination':
        return destinationName(colorScheme);
      case 'trip_title':
        return tripTitle(colorScheme);
      case 'activity':
        return activityTitle(colorScheme);
      case 'price':
        return priceDisplay(colorScheme);
      case 'time':
        return timeDisplay(colorScheme);
      case 'location':
        return locationText(colorScheme);
      case 'description':
        return travelDescription(colorScheme);
      case 'status':
        return statusText(colorScheme);
      case 'caption':
        return caption(colorScheme);
      default:
        return travelDescription(colorScheme);
    }
  }
}

/// Enhanced spacing system for travel content
class TravelSpacing {
  TravelSpacing._();

  // ================== Travel-Specific Spacing ==================

  /// Spacing between trip cards in lists
  static const double tripCardSpacing = 16.0;

  /// Spacing between activity items in timelines
  static const double timelineItemSpacing = 24.0;

  /// Spacing around destination images
  static const double imageSpacing = 12.0;

  /// Spacing for price displays
  static const double priceSpacing = 8.0;

  /// Spacing between travel information sections
  static const double sectionSpacing = 24.0;

  /// Compact spacing for dense layouts
  static const double compactSpacing = 8.0;

  /// Large spacing for important separations
  static const double largeSpacing = 32.0;

  // ================== Content-Specific Insets ==================

  /// Standard padding for trip cards
  static const EdgeInsets tripCardPadding = EdgeInsets.all(16.0);

  /// Padding for activity timeline items
  static const EdgeInsets timelinePadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );

  /// Padding for destination chips
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 6.0,
  );

  /// Padding for price displays
  static const EdgeInsets pricePadding = EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 4.0,
  );

  /// Padding for image overlays
  static const EdgeInsets overlayPadding = EdgeInsets.all(12.0);

  // ================== Layout Helpers ==================

  /// Vertical spacing between major sections
  static const SizedBox sectionGap = SizedBox(height: sectionSpacing);

  /// Horizontal spacing between related elements
  static const SizedBox horizontalGap = SizedBox(width: 12.0);

  /// Small vertical spacing for compact layouts
  static const SizedBox smallGap = SizedBox(height: compactSpacing);

  /// Large vertical spacing for important breaks
  static const SizedBox largeGap = SizedBox(height: largeSpacing);

  /// Timeline item spacing
  static const SizedBox timelineGap = SizedBox(height: timelineItemSpacing);
}

/// Travel-themed border radius constants
class TravelBorderRadius {
  TravelBorderRadius._();

  /// Standard border radius for cards
  static const double card = 16.0;

  /// Border radius for chips and small elements
  static const double chip = 12.0;

  /// Border radius for buttons
  static const double button = 12.0;

  /// Border radius for images
  static const double image = 8.0;

  /// Large border radius for prominent elements
  static const double large = 20.0;

  /// Small border radius for minimal elements
  static const double small = 6.0;

  // ================== BorderRadius Objects ==================

  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius chipRadius = BorderRadius.all(
    Radius.circular(chip),
  );
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius imageRadius = BorderRadius.all(
    Radius.circular(image),
  );
  static const BorderRadius largeRadius = BorderRadius.all(
    Radius.circular(large),
  );
  static const BorderRadius smallRadius = BorderRadius.all(
    Radius.circular(small),
  );
}
