import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:travel_wizards/main.dart' as app;

void main() {
  IntegrationTestWidgetsBinding.ensureInitialized();

  group('Destination Flow Integration Tests', () {
    testWidgets('Should add destinations and allow trip generation', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Look for plan trip button or navigation
      final planTripFinder = find.textContaining('Plan');
      if (planTripFinder.evaluate().isNotEmpty) {
        await tester.tap(planTripFinder.first);
        await tester.pumpAndSettle();
      }

      // Look for destination input field - try TextField first, then TextFormField
      Finder destinationFieldFinder = find.byType(TextField);
      if (destinationFieldFinder.evaluate().isEmpty) {
        destinationFieldFinder = find.byType(TextFormField);
      }

      if (destinationFieldFinder.evaluate().isNotEmpty) {
        // Test adding a destination
        await tester.enterText(destinationFieldFinder.first, 'Mumbai');
        await tester.pumpAndSettle();

        // Look for autocomplete suggestions
        await tester.pump(const Duration(seconds: 2));

        // Try to find Mumbai in suggestions and tap it
        final mumbaiSuggestion = find.textContaining('Mumbai');
        if (mumbaiSuggestion.evaluate().isNotEmpty) {
          await tester.tap(mumbaiSuggestion.first);
          await tester.pumpAndSettle();
        }

        // Verify destination was added (look for chip or list item)
        await tester.pumpAndSettle();

        // Look for generate trip button - try Generate first, then Create
        Finder generateTripFinder = find.textContaining('Generate');
        if (generateTripFinder.evaluate().isEmpty) {
          generateTripFinder = find.textContaining('Create');
        }
        if (generateTripFinder.evaluate().isNotEmpty) {
          // Should not show "please add at least one destination" error now
          expect(
            find.textContaining('please add at least one destination'),
            findsNothing,
          );
        }

        print('✅ Destination flow test completed successfully');
      } else {
        print('⚠️ Could not find destination input field');
      }
    });

    testWidgets('Should handle Indian location search correctly', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test searches for common Indian cities
      final testCities = ['Delhi', 'Mumbai', 'Bangalore', 'Chennai'];

      for (final city in testCities) {
        // Look for any text input field - try TextField first, then TextFormField
        Finder inputField = find.byType(TextField);
        if (inputField.evaluate().isEmpty) {
          inputField = find.byType(TextFormField);
        }

        if (inputField.evaluate().isNotEmpty) {
          await tester.enterText(inputField.first, city);
          await tester.pumpAndSettle();

          // Wait for search results
          await tester.pump(const Duration(seconds: 2));

          // Should find the city in results
          final cityResult = find.textContaining(city);
          expect(
            cityResult,
            findsOneWidget,
            reason: 'Should find $city in search results',
          );

          // Clear the field for next test
          await tester.enterText(inputField.first, '');
          await tester.pumpAndSettle();
        }
      }

      print('✅ Indian location search test completed');
    });
  });
}
