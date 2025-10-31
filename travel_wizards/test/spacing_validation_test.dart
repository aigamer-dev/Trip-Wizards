import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/ui/design_tokens.dart';

void main() {
  group('Spacing Validation Tests', () {
    test('All spacing constants follow 8dp baseline grid', () {
      // Test space constants are multiples of 8dp
      expect(DesignTokens.space1 % 8.0, equals(0.0));
      expect(DesignTokens.space2 % 8.0, equals(0.0));
      expect(DesignTokens.space3 % 8.0, equals(0.0));
      expect(DesignTokens.space4 % 8.0, equals(0.0));
      expect(DesignTokens.space5 % 8.0, equals(0.0));
      expect(DesignTokens.space6 % 8.0, equals(0.0));
    });

    test('Gap constants follow 8dp baseline grid', () {
      expect(DesignTokens.gapSmall % 8.0, equals(0.0));
      expect(DesignTokens.gapMedium % 8.0, equals(0.0));
      expect(DesignTokens.gapLarge % 8.0, equals(0.0));
    });

    test('Padding constants follow 8dp baseline grid', () {
      expect(DesignTokens.paddingSmall % 8.0, equals(0.0));
      expect(DesignTokens.paddingMedium % 8.0, equals(0.0));
      expect(DesignTokens.paddingLarge % 8.0, equals(0.0));
    });

    test('Spacing values are reasonable and follow baseline', () {
      // Verify spacing increases appropriately (not necessarily linear)
      expect(DesignTokens.space2, greaterThan(DesignTokens.space1));
      expect(DesignTokens.space3, greaterThan(DesignTokens.space2));
      expect(DesignTokens.space4, greaterThan(DesignTokens.space3));
      expect(DesignTokens.space5, greaterThan(DesignTokens.space4));
      expect(DesignTokens.space6, greaterThan(DesignTokens.space5));
    });

    test('Gap constants match space constants', () {
      expect(DesignTokens.gapSmall, equals(DesignTokens.space1));
      expect(DesignTokens.gapMedium, equals(DesignTokens.space2));
      expect(DesignTokens.gapLarge, equals(DesignTokens.space3));
    });

    test('Padding constants match space constants', () {
      expect(DesignTokens.paddingSmall, equals(DesignTokens.space1));
      expect(DesignTokens.paddingMedium, equals(DesignTokens.space2));
      expect(DesignTokens.paddingLarge, equals(DesignTokens.space3));
    });

    test('All spacing values are positive', () {
      expect(DesignTokens.space1, greaterThan(0.0));
      expect(DesignTokens.space2, greaterThan(0.0));
      expect(DesignTokens.space3, greaterThan(0.0));
      expect(DesignTokens.space4, greaterThan(0.0));
      expect(DesignTokens.space5, greaterThan(0.0));
      expect(DesignTokens.space6, greaterThan(0.0));
      expect(DesignTokens.gapSmall, greaterThan(0.0));
      expect(DesignTokens.gapMedium, greaterThan(0.0));
      expect(DesignTokens.gapLarge, greaterThan(0.0));
      expect(DesignTokens.paddingSmall, greaterThan(0.0));
      expect(DesignTokens.paddingMedium, greaterThan(0.0));
      expect(DesignTokens.paddingLarge, greaterThan(0.0));
    });
  });
}
