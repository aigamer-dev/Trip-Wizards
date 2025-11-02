import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/shared/widgets/location_autocomplete_field.dart';

void main() {
  group('LocationAutocompleteField Widget Tests', () {
    testWidgets('should render correctly', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              controller: controller,
              labelText: 'Test Location',
              hintText: 'Enter location',
            ),
          ),
        ),
      );

      expect(find.text('Test Location'), findsOneWidget);
      expect(find.text('Enter location'), findsOneWidget);
    });

    testWidgets('should handle disabled state', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              controller: controller,
              labelText: 'Location',
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('should trigger callback when text changes', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      String? changedText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              controller: controller,
              labelText: 'Location',
              onChanged: (text) => changedText = text,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Mumbai');
      expect(changedText, equals('Mumbai'));
    });
  });
}
