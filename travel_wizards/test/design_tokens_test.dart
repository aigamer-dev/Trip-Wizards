import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/ui/design_tokens.dart';

void main() {
  group('DesignTokens', () {
    test('fallbackLightScheme has correct primary color', () {
      expect(DesignTokens.fallbackLightScheme.primary, const Color(0xFF673AB7));
    });

    test('fallbackLightScheme has correct secondary color', () {
      expect(
        DesignTokens.fallbackLightScheme.secondary,
        const Color(0xFF006A60),
      );
    });

    test('fallbackLightScheme has correct tertiary color', () {
      expect(
        DesignTokens.fallbackLightScheme.tertiary,
        const Color(0xFFFF5722),
      );
    });

    test('fallbackDarkScheme has correct primary color', () {
      expect(DesignTokens.fallbackDarkScheme.primary, const Color(0xFFCFBCFF));
    });

    test('fallbackDarkScheme has correct secondary color', () {
      expect(
        DesignTokens.fallbackDarkScheme.secondary,
        const Color(0xFF4DD8C0),
      );
    });

    test('fallbackDarkScheme has correct tertiary color', () {
      expect(DesignTokens.fallbackDarkScheme.tertiary, const Color(0xFFFFB4A9));
    });

    test('textTheme is properly defined', () {
      expect(DesignTokens.textTheme, isNotNull);
      expect(DesignTokens.textTheme.displayLarge, isNotNull);
      expect(DesignTokens.textTheme.headlineLarge, isNotNull);
      expect(DesignTokens.textTheme.titleLarge, isNotNull);
      expect(DesignTokens.textTheme.bodyLarge, isNotNull);
    });

    test('spacing values are reasonable', () {
      expect(DesignTokens.space1, greaterThan(0));
      expect(DesignTokens.space2, greaterThan(DesignTokens.space1));
      expect(DesignTokens.space3, greaterThan(DesignTokens.space2));
      expect(DesignTokens.space4, greaterThan(DesignTokens.space3));
      expect(DesignTokens.space5, greaterThan(DesignTokens.space4));
    });
  });
}
