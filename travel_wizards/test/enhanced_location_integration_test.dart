import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/shared/widgets/location_autocomplete_field.dart';

void main() {
  group('Enhanced Location Autocomplete Integration Tests', () {
    testWidgets('should render with Indian location support', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              controller: controller,
              labelText: 'Indian Location Test',
              hintText: 'Type Mumbai, Delhi, BOM, etc.',
            ),
          ),
        ),
      );

      expect(find.text('Indian Location Test'), findsOneWidget);
      expect(find.text('Type Mumbai, Delhi, BOM, etc.'), findsOneWidget);
    });

    testWidgets('should handle Indian city input', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              controller: controller,
              labelText: 'Destination',
              onPlaceSelected: (result) {
                // Handle selection
                controller.text = result.description;
              },
            ),
          ),
        ),
      );

      // Test typing an Indian city
      await tester.enterText(find.byType(TextField), 'Mumbai');
      expect(controller.text, equals('Mumbai'));
    });

    testWidgets('should handle airport codes', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              controller: controller,
              labelText: 'Airport',
            ),
          ),
        ),
      );

      // Test typing an airport code
      await tester.enterText(find.byType(TextField), 'BOM');
      expect(controller.text, equals('BOM'));
    });
  });
}
