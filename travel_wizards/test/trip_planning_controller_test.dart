import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/features/trip_planning/views/controllers/trip_planning_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripPlanningController unit tests', () {
    setUp(() {
      // Clear any stored preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('validateStep1 enforces business fields', () {
      final controller = TripPlanningController();

      controller.setTripStyle('Business');
      // Both company name and purpose empty -> validation error
      final err1 = controller.validateStep1();
      expect(err1, isNotNull);

      controller.companyNameController.text = 'Acme Corp';
      // Purpose still empty
      final err2 = controller.validateStep1();
      expect(err2, isNotNull);

      controller.businessPurposeController.text = 'Conference';
      final ok = controller.validateStep1();
      expect(ok, isNull);
    });

    test('validateStep2 requires origin, destination and valid dates', () {
      final controller = TripPlanningController();

      // Empty origin -> error
      controller.originController.text = '';
      controller.destinationController.text = '';
      controller.setDates(null);
      expect(controller.validateStep2(), isNotNull);

      // Fill origin but missing destination
      controller.originController.text = 'Chennai';
      expect(controller.validateStep2(), isNotNull);

      // Fill destination and invalid dates (null)
      controller.destinationController.text = 'Bangalore';
      expect(controller.validateStep2(), isNotNull);

      // Set valid date range starting tomorrow
      final today = DateTime.now();
      final start = DateTime(
        today.year,
        today.month,
        today.day,
      ).add(const Duration(days: 1));
      final end = start.add(const Duration(days: 2));
      controller.setDates(DateTimeRange(start: start, end: end));
      expect(controller.validateStep2(), isNull);
    });

    test(
      'saveDraft and loadDraft persist basic values via PlanTripStore',
      () async {
        final controller = TripPlanningController();

        // Set some values
        controller.setTestBudget(Budget.high);
        controller.setTestNotes('My notes for the trip');
        controller.setTestDuration(5);

        // Save draft
        await controller.saveDraft();

        // Create a fresh controller and load draft
        final controller2 = TripPlanningController();
        await controller2.loadDraft();

        // Loaded values should match
        expect(controller2.durationDays, equals(5));
        expect(controller2.budget, equals(Budget.high));
        expect(controller2.notes, contains('My notes'));
      },
    );
  });
}
