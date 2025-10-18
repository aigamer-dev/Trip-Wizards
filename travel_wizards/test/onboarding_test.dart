import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/features/onboarding/views/screens/enhanced_onboarding_screen.dart';

void main() {
  group('Onboarding Flow Tests', () {
    testWidgets('Should display welcome screen on first step', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: EnhancedOnboardingScreen()),
      );

      // Verify welcome screen elements
      expect(find.byIcon(Icons.flight_takeoff), findsOneWidget);
      expect(find.text('Welcome to Travel Wizards'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Should navigate to next step when Next is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: EnhancedOnboardingScreen()),
      );

      // Find and tap Next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify we're on step 2 (Travel Style)
      expect(find.text('Step 2 of 5'), findsOneWidget);
    });

    testWidgets('Should allow selecting travel style', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: EnhancedOnboardingScreen()),
      );

      // Navigate to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // TODO: Find and tap a travel style option
      // Verify selection is highlighted
    });

    testWidgets('Should collect all data and save to Firestore', (
      WidgetTester tester,
    ) async {
      // This is an integration test that would require Firebase mocking
      // TODO: Mock Firebase and verify data is saved correctly
    });

    testWidgets('Progress indicator should update correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: EnhancedOnboardingScreen()),
      );

      // Verify initial step indicator
      expect(find.text('Step 1 of 5'), findsOneWidget);

      // Navigate to next step
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify step 2
      expect(find.text('Step 2 of 5'), findsOneWidget);
    });

    testWidgets('Back button should navigate to previous step', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: EnhancedOnboardingScreen()),
      );

      // Go to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify we're on step 2
      expect(find.text('Step 2 of 5'), findsOneWidget);

      // Tap Back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Verify we're back on step 1
      expect(find.text('Step 1 of 5'), findsOneWidget);
    });

    testWidgets('Final step should show "Get Started!" button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: EnhancedOnboardingScreen()),
      );

      // Navigate through all steps
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Verify we're on step 5 and button says "Get Started!"
      expect(find.text('Step 5 of 5'), findsOneWidget);
      expect(find.text('Get Started!'), findsOneWidget);
    });
  });

  group('Onboarding UI/UX Tests', () {
    testWidgets('Should display correctly on mobile screen', (
      WidgetTester tester,
    ) async {
      // Set mobile viewport
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        const MaterialApp(home: EnhancedOnboardingScreen()),
      );

      // Verify layout fits mobile screen
      expect(tester.getSize(find.byType(EnhancedOnboardingScreen)).width, 375);
    });

    testWidgets('Should display correctly on tablet screen', (
      WidgetTester tester,
    ) async {
      // Set tablet viewport
      await tester.binding.setSurfaceSize(const Size(800, 1024));

      await tester.pumpWidget(
        const MaterialApp(home: EnhancedOnboardingScreen()),
      );

      // Verify layout adapts to tablet
      expect(tester.getSize(find.byType(EnhancedOnboardingScreen)).width, 800);
    });

    testWidgets('Should display correctly on desktop screen', (
      WidgetTester tester,
    ) async {
      // Set desktop viewport
      await tester.binding.setSurfaceSize(const Size(1920, 1080));

      await tester.pumpWidget(
        const MaterialApp(home: EnhancedOnboardingScreen()),
      );

      // Verify layout adapts to desktop
      expect(tester.getSize(find.byType(EnhancedOnboardingScreen)).width, 1920);
    });
  });
}
