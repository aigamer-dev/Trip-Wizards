import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/ui/design_tokens.dart';
import 'dart:math' as math;

/// Contrast ratio verification tests for design tokens
///
/// This test suite verifies that all text/background color combinations
/// meet WCAG 2.1 AA accessibility standards:
/// - Normal text: >= 4.5:1 contrast ratio
/// - Large text (>= 18pt or 14pt bold): >= 3:1 contrast ratio

class ContrastChecker {
  /// Calculate the contrast ratio between two colors
  static double calculateContrast(Color foreground, Color background) {
    // Convert colors to linear RGB values
    final fg = _toLinearRgb(foreground);
    final bg = _toLinearRgb(background);

    // Calculate relative luminance
    final lum1 = _calculateLuminance(fg);
    final lum2 = _calculateLuminance(bg);

    // Return contrast ratio (larger value / smaller value + 0.05)
    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Convert sRGB color to linear RGB values
  static List<double> _toLinearRgb(Color color) {
    // Use color.value bit masks instead of deprecated getters
    final r = ((color.value >> 16) & 0xFF) / 255.0;
    final g = ((color.value >> 8) & 0xFF) / 255.0;
    final b = (color.value & 0xFF) / 255.0;

    return [
      r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4).toDouble(),
      g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4).toDouble(),
      b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4).toDouble(),
    ];
  }

  /// Calculate relative luminance from linear RGB
  static double _calculateLuminance(List<double> rgb) {
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2];
  }

  /// Check if contrast ratio meets WCAG AA standards
  static bool meetsAAStandard(double contrast, bool isLargeText) {
    return isLargeText ? contrast >= 3.0 : contrast >= 4.5;
  }

  /// Check if text is considered "large" (>= 18pt or 14pt bold)
  static bool isLargeText(TextStyle? style) {
    if (style == null) return false;
    final fontSize = style.fontSize ?? 14.0;
    final fontWeight = style.fontWeight ?? FontWeight.normal;
    final isBold =
        fontWeight.index >= FontWeight.bold.index; // Truly bold (w700+)

    return fontSize >= 18.0 || (fontSize >= 14.0 && isBold);
  }
}

void main() {
  group('Design Tokens Contrast Verification', () {
    group('Light Theme Contrast Ratios', () {
      test('Primary text on surface meets AA standards', () {
        final contrast = ContrastChecker.calculateContrast(
          DesignTokens.fallbackLightScheme.onSurface,
          DesignTokens.fallbackLightScheme.surface,
        );

        final meetsStandard = ContrastChecker.meetsAAStandard(contrast, false);
        expect(
          meetsStandard,
          isTrue,
          reason:
              'Primary text contrast ratio: ${contrast.toStringAsFixed(2)}:1 (required: 4.5:1)',
        );
      });

      test('Primary text on primary meets AA standards', () {
        final contrast = ContrastChecker.calculateContrast(
          DesignTokens.fallbackLightScheme.onPrimary,
          DesignTokens.fallbackLightScheme.primary,
        );

        final meetsStandard = ContrastChecker.meetsAAStandard(contrast, false);
        expect(
          meetsStandard,
          isTrue,
          reason:
              'Primary text on primary contrast ratio: ${contrast.toStringAsFixed(2)}:1 (required: 4.5:1)',
        );
      });

      test('Secondary text on surface meets AA standards', () {
        final contrast = ContrastChecker.calculateContrast(
          DesignTokens.fallbackLightScheme.onSurfaceVariant,
          DesignTokens.fallbackLightScheme.surface,
        );

        final meetsStandard = ContrastChecker.meetsAAStandard(contrast, false);
        expect(
          meetsStandard,
          isTrue,
          reason:
              'Secondary text contrast ratio: ${contrast.toStringAsFixed(2)}:1 (required: 4.5:1)',
        );
      });

      test('Error text on surface meets AA standards', () {
        final contrast = ContrastChecker.calculateContrast(
          DesignTokens.fallbackLightScheme.error,
          DesignTokens.fallbackLightScheme.surface,
        );

        final meetsStandard = ContrastChecker.meetsAAStandard(contrast, false);
        expect(
          meetsStandard,
          isTrue,
          reason:
              'Error text contrast ratio: ${contrast.toStringAsFixed(2)}:1 (required: 4.5:1)',
        );
      });

      test('Large text (display styles) meets relaxed AA standards', () {
        // Test displayLarge (57pt)
        final displayLargeContrast = ContrastChecker.calculateContrast(
          DesignTokens.fallbackLightScheme.onSurface,
          DesignTokens.fallbackLightScheme.surface,
        );

        final isLarge = ContrastChecker.isLargeText(
          DesignTokens.textTheme.displayLarge,
        );
        expect(
          isLarge,
          isTrue,
          reason: 'displayLarge should be considered large text',
        );

        final meetsStandard = ContrastChecker.meetsAAStandard(
          displayLargeContrast,
          true,
        );
        expect(
          meetsStandard,
          isTrue,
          reason:
              'Display large text contrast ratio: ${displayLargeContrast.toStringAsFixed(2)}:1 (required: 3:1)',
        );
      });
    });

    group('Dark Theme Contrast Ratios', () {
      test('Primary text on surface meets AA standards', () {
        final contrast = ContrastChecker.calculateContrast(
          DesignTokens.fallbackDarkScheme.onSurface,
          DesignTokens.fallbackDarkScheme.surface,
        );

        final meetsStandard = ContrastChecker.meetsAAStandard(contrast, false);
        expect(
          meetsStandard,
          isTrue,
          reason:
              'Dark theme primary text contrast ratio: ${contrast.toStringAsFixed(2)}:1 (required: 4.5:1)',
        );
      });

      test('Primary text on primary meets AA standards', () {
        final contrast = ContrastChecker.calculateContrast(
          DesignTokens.fallbackDarkScheme.onPrimary,
          DesignTokens.fallbackDarkScheme.primary,
        );

        final meetsStandard = ContrastChecker.meetsAAStandard(contrast, false);
        expect(
          meetsStandard,
          isTrue,
          reason:
              'Dark theme primary text on primary contrast ratio: ${contrast.toStringAsFixed(2)}:1 (required: 4.5:1)',
        );
      });

      test('Secondary text on surface meets AA standards', () {
        final contrast = ContrastChecker.calculateContrast(
          DesignTokens.fallbackDarkScheme.onSurfaceVariant,
          DesignTokens.fallbackDarkScheme.surface,
        );

        final meetsStandard = ContrastChecker.meetsAAStandard(contrast, false);
        expect(
          meetsStandard,
          isTrue,
          reason:
              'Dark theme secondary text contrast ratio: ${contrast.toStringAsFixed(2)}:1 (required: 4.5:1)',
        );
      });
    });

    group('Typography Scale Verification', () {
      test('Text styles are properly sized for accessibility', () {
        // Body text should be readable
        expect(
          DesignTokens.textTheme.bodyLarge?.fontSize,
          greaterThanOrEqualTo(14.0),
        );
        expect(
          DesignTokens.textTheme.bodyMedium?.fontSize,
          greaterThanOrEqualTo(12.0),
        );
        expect(
          DesignTokens.textTheme.bodySmall?.fontSize,
          greaterThanOrEqualTo(11.0),
        );

        // Label text should be readable
        expect(
          DesignTokens.textTheme.labelLarge?.fontSize,
          greaterThanOrEqualTo(11.0),
        );
        expect(
          DesignTokens.textTheme.labelMedium?.fontSize,
          greaterThanOrEqualTo(10.0),
        );
        expect(
          DesignTokens.textTheme.labelSmall?.fontSize,
          greaterThanOrEqualTo(8.0),
        );
      });

      test('Large text identification works correctly', () {
        // These should be considered large text (>= 18pt OR >= 14pt and truly bold w700+)
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.displayLarge),
          isTrue,
        ); // 57pt
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.displayMedium),
          isTrue,
        ); // 45pt
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.displaySmall),
          isTrue,
        ); // 36pt
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.headlineLarge),
          isTrue,
        ); // 32pt
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.headlineMedium),
          isTrue,
        ); // 28pt
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.headlineSmall),
          isTrue,
        ); // 24pt
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.titleLarge),
          isTrue,
        ); // 22pt

        // These should NOT be considered large text
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.titleMedium),
          isFalse,
        ); // 16pt + w500 (not >= 18pt)
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.titleSmall),
          isFalse,
        ); // 14pt + w500 (not truly bold)
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.bodyLarge),
          isFalse,
        ); // 16pt
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.bodyMedium),
          isFalse,
        ); // 14pt
        expect(
          ContrastChecker.isLargeText(DesignTokens.textTheme.labelLarge),
          isFalse,
        ); // 14pt + w500
      });
    });

    group('Contrast Calculation Validation', () {
      test('Contrast calculation produces expected results', () {
        // Pure black on pure white should be 21:1
        final blackOnWhite = ContrastChecker.calculateContrast(
          const Color(0xFF000000),
          const Color(0xFFFFFFFF),
        );
        expect(blackOnWhite, closeTo(21.0, 0.1));

        // Same color should be 1:1
        final sameColor = ContrastChecker.calculateContrast(
          const Color(0xFF808080),
          const Color(0xFF808080),
        );
        expect(sameColor, closeTo(1.0, 0.01));
      });

      test('AA standard checking works correctly', () {
        expect(
          ContrastChecker.meetsAAStandard(4.5, false),
          isTrue,
        ); // Exactly 4.5:1 for normal text
        expect(
          ContrastChecker.meetsAAStandard(4.4, false),
          isFalse,
        ); // Below 4.5:1 for normal text
        expect(
          ContrastChecker.meetsAAStandard(3.0, true),
          isTrue,
        ); // Exactly 3:1 for large text
        expect(
          ContrastChecker.meetsAAStandard(2.9, true),
          isFalse,
        ); // Below 3:1 for large text
      });
    });
  });
}
