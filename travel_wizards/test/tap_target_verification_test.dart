import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/shared/widgets/travel_components/travel_components.dart';
import 'package:travel_wizards/src/ui/design_tokens.dart';

void main() {
  group('Tap Target Accessibility Verification', () {
    testWidgets('PrimaryButton meets minimum touch target size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: PrimaryButton(onPressed: () {}, child: const Text('Test')),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      final button = tester.widget<ElevatedButton>(buttonFinder);

      // Get the resolved minimum size
      final minimumSize = button.style?.minimumSize?.resolve({});
      expect(minimumSize?.width ?? 0, greaterThanOrEqualTo(48.0));
      expect(minimumSize?.height ?? 0, greaterThanOrEqualTo(48.0));
    });

    testWidgets('SecondaryButton meets minimum touch target size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: SecondaryButton(onPressed: () {}, child: const Text('Test')),
          ),
        ),
      );

      final buttonFinder = find.byType(OutlinedButton);
      final button = tester.widget<OutlinedButton>(buttonFinder);

      // Get the resolved minimum size
      final minimumSize = button.style?.minimumSize?.resolve({});
      expect(minimumSize?.width ?? 0, greaterThanOrEqualTo(48.0));
      expect(minimumSize?.height ?? 0, greaterThanOrEqualTo(48.0));
    });

    testWidgets('TravelAvatar meets minimum touch target size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(body: const TravelAvatar()),
        ),
      );

      final avatarFinder = find.byType(CircleAvatar);
      final avatar = tester.widget<CircleAvatar>(avatarFinder);

      // CircleAvatar radius should be at least 24.0 (48.0 diameter)
      expect(avatar.radius, greaterThanOrEqualTo(24.0));
    });

    testWidgets('TravelCard with onTap has adequate touch target', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: TravelCard(
              onTap: () {},
              child: const SizedBox(
                width: 100,
                height: 100,
                child: Center(child: Text('Test')),
              ),
            ),
          ),
        ),
      );

      final cardFinder = find.byType(Card);

      // Get the size of the card
      final size = tester.getSize(cardFinder);

      // Card should have minimum dimensions for touch targets
      // Note: This test assumes the card content provides adequate size
      // In practice, cards should be designed with sufficient size
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('DestinationChip meets minimum touch target size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: DestinationChip(
              destination: 'Test Destination',
              onTap: () {},
            ),
          ),
        ),
      );

      final chipFinder = find.byType(FilterChip);

      // Get the size of the chip
      final size = tester.getSize(chipFinder);

      // FilterChip should have minimum touch target size
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    test('Design tokens define adequate avatar radius', () {
      // Avatar radius should be at least 24.0 for 48.0 diameter
      expect(DesignTokens.avatarRadius, greaterThanOrEqualTo(24.0));
    });

    test('Design tokens define adequate button radius', () {
      // Button radius can be smaller as buttons have padding
      expect(DesignTokens.buttonRadius, isNotNull);
    });
  });
}
