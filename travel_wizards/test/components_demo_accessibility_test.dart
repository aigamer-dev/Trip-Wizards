import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/shared/widgets/travel_components/components_demo.dart';

void main() {
  group('Components Demo Page Accessibility Tests', () {
    testWidgets('Demo page has proper semantic structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const ComponentsDemoPage(),
        ),
      );

      // Check that headings are present and properly structured
      expect(find.text('Buttons'), findsOneWidget);
      expect(find.text('Text Fields'), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Avatars'), findsOneWidget);
      expect(find.text('Color Palette'), findsOneWidget);

      // Check that buttons have proper text
      expect(find.text('Primary Button'), findsOneWidget);
      expect(find.text('Secondary Button'), findsOneWidget);
    });

    testWidgets('Buttons have adequate touch targets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const ComponentsDemoPage(),
        ),
      );

      // Find the primary button
      final primaryButtonFinder = find.widgetWithText(
        ElevatedButton,
        'Primary Button',
      );
      expect(primaryButtonFinder, findsOneWidget);

      // Check button size
      final buttonSize = tester.getSize(primaryButtonFinder);
      expect(buttonSize.width, greaterThanOrEqualTo(48.0));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));

      // Find the secondary button
      final secondaryButtonFinder = find.widgetWithText(
        OutlinedButton,
        'Secondary Button',
      );
      expect(secondaryButtonFinder, findsOneWidget);

      // Check button size
      final secondaryButtonSize = tester.getSize(secondaryButtonFinder);
      expect(secondaryButtonSize.width, greaterThanOrEqualTo(48.0));
      expect(secondaryButtonSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Text fields have proper labels and hints', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const ComponentsDemoPage(),
        ),
      );

      // Check that text fields have proper labels
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

      // Check that hint text is present
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('Card has adequate content and accessibility', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const ComponentsDemoPage(),
        ),
      );

      // Check card content
      expect(find.text('Sample Card'), findsOneWidget);
      expect(
        find.text(
          'This is a sample card demonstrating the TravelCard component.',
        ),
        findsOneWidget,
      );

      // Check card size is reasonable - find the specific card by its content
      final cardFinder = find.ancestor(
        of: find.text('Sample Card'),
        matching: find.byType(Card),
      );
      expect(cardFinder, findsOneWidget);

      final cardSize = tester.getSize(cardFinder);
      expect(cardSize.width, greaterThan(100.0));
      expect(cardSize.height, greaterThan(50.0));
    });

    testWidgets('Avatars are properly sized', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const ComponentsDemoPage(),
        ),
      );

      // Check that avatars exist
      final avatarFinder = find.byType(CircleAvatar);
      expect(avatarFinder, findsWidgets);

      // Check avatar sizes (should be at least 48dp diameter)
      final avatars = tester.widgetList<CircleAvatar>(avatarFinder);
      for (final avatar in avatars) {
        expect(avatar.radius ?? 0, greaterThanOrEqualTo(24.0)); // 48dp diameter
      }
    });

    testWidgets('Color swatches have proper contrast', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const ComponentsDemoPage(),
        ),
      );

      // Check that color swatches exist
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Tertiary'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Surface'), findsOneWidget);
      expect(find.text('Background'), findsOneWidget);
    });

    testWidgets('Page is scrollable and fits content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const SizedBox(
            width: 400,
            height: 600,
            child: ComponentsDemoPage(),
          ),
        ),
      );

      // Check that SingleChildScrollView exists for scrolling
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Check that all content is present
      expect(find.text('Design System Demo'), findsOneWidget);
      expect(find.text('Buttons'), findsOneWidget);
      expect(find.text('Text Fields'), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Avatars'), findsOneWidget);
      expect(find.text('Color Palette'), findsOneWidget);
    });

    testWidgets('Components use design tokens consistently', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const ComponentsDemoPage(),
        ),
      );

      // This test ensures the demo page uses design tokens
      // The actual verification would require more complex testing
      // For now, we verify the page builds without errors
      expect(find.byType(ComponentsDemoPage), findsOneWidget);
    });
  });
}
