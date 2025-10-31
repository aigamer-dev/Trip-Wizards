import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/features/trip_planning/views/controllers/trip_planning_controller.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/plan_trip_screen.dart';
import 'package:travel_wizards/src/shared/widgets/places_autocomplete_field.dart';
import 'mocks/mock_places_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanTripScreen widget tests', () {
    late TripPlanningController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PlacesAutocompleteField.overrideDefaultServiceForTesting(
        MockPlacesApiService(),
      );
      controller = TripPlanningController();
    });

    tearDown(() {
      PlacesAutocompleteField.overrideDefaultServiceForTesting(null);
      controller.dispose();
    });

    testWidgets('shows validation banner when Step 2 fields are missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: PlanTripScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Step 1 passes with default values -> move to Step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(controller.currentStep, TripPlanningStep.details);

      // Attempt to move to Step 3 without filling required fields
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Validation banner should surface the origin error message
      expect(find.text('Please enter an origin location'), findsWidgets);
      expect(controller.currentStep, TripPlanningStep.details);
    });

    testWidgets('autocomplete selection populates destination controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: PlanTripScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Advance to Step 2 to interact with destination field
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      final destinationField = find.bySemanticsLabel('To (Destination)');
      expect(destinationField, findsOneWidget);

      await tester.tap(destinationField);
      await tester.enterText(destinationField, 'Bang');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final suggestion = find.text('Bangalore');
      expect(suggestion, findsOneWidget);

      await tester.tap(suggestion);
      await tester.pumpAndSettle();

      expect(controller.destinationController.text, 'Bangalore, India');
      expect(find.text('Bangalore, India'), findsWidgets);
    });

    testWidgets('moving past Step 2 saves draft when inputs valid', (
      tester,
    ) async {
      final spyController = _SpyTripPlanningController();
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(home: PlanTripScreen(controller: spyController)),
      );
      await tester.pumpAndSettle();
      addTearDown(spyController.dispose);

      // Step 1 -> Step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(spyController.currentStep, TripPlanningStep.details);

      // Provide required details directly through the controller
      spyController.originController.text = 'Chennai';
      spyController.destinationController.text = 'Bangalore';
      final today = DateTime.now();
      final start = DateTime(
        today.year,
        today.month,
        today.day,
      ).add(const Duration(days: 1));
      final end = start.add(const Duration(days: 2));
      spyController.setDates(DateTimeRange(start: start, end: end));
      await tester.pumpAndSettle();

      // Proceed to Step 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(spyController.currentStep, TripPlanningStep.stayActivities);
      expect(spyController.draftSaved, isTrue);
    });
  });
}

class _SpyTripPlanningController extends TripPlanningController {
  bool draftSaved = false;

  @override
  Future<void> saveDraft() async {
    draftSaved = true;
    await super.saveDraft();
  }
}
