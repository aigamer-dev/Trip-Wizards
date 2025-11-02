import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/features/trip_planning/views/controllers/trip_planning_controller.dart';

void main() {
  group('TripPlanningController Destination Tests', () {
    late TripPlanningController controller;

    setUp(() {
      controller = TripPlanningController();
    });

    test('should add destinations correctly', () {
      // Initially no destinations
      expect(controller.destinations.isEmpty, isTrue);

      // Add a destination
      controller.addDestination('Mumbai, India');
      expect(controller.destinations.length, equals(1));
      expect(controller.destinations.contains('Mumbai, India'), isTrue);

      // Add another destination
      controller.addDestination('Delhi, India');
      expect(controller.destinations.length, equals(2));

      // Try to add duplicate destination - should not be added
      controller.addDestination('Mumbai, India');
      expect(controller.destinations.length, equals(2));

      // Try to add empty destination - should not be added
      controller.addDestination('');
      expect(controller.destinations.length, equals(2));

      // Try to add whitespace-only destination - should not be added
      controller.addDestination('   ');
      expect(controller.destinations.length, equals(2));
    });

    test('should remove destinations correctly', () {
      // Add some destinations
      controller.addDestination('Mumbai, India');
      controller.addDestination('Delhi, India');
      expect(controller.destinations.length, equals(2));

      // Remove one destination
      controller.removeDestination('Mumbai, India');
      expect(controller.destinations.length, equals(1));
      expect(controller.destinations.contains('Delhi, India'), isTrue);

      // Remove non-existent destination - should not crash
      controller.removeDestination('Nonexistent City');
      expect(controller.destinations.length, equals(1));
    });

    test('should validate destinations correctly', () {
      // With no destinations, validation should fail
      expect(controller.destinations.isEmpty, isTrue);

      // Add a destination
      controller.addDestination('Mumbai, India');
      expect(controller.destinations.isEmpty, isFalse);
    });

    test('should trim destination names', () {
      // Add destination with extra whitespace
      controller.addDestination('  Mumbai, India  ');
      expect(controller.destinations.first, equals('Mumbai, India'));
    });
  });
}
