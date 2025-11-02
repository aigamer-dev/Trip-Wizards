import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/core/app/app.dart';
import 'package:travel_wizards/src/features/trip_planning/views/controllers/trip_planning_controller.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/plan_trip_screen.dart';
import 'package:travel_wizards/src/shared/services/accessibility_service.dart';
import 'package:travel_wizards/src/shared/widgets/places_autocomplete_field.dart';
import 'mocks/mock_places_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Accessibility baseline', () {
    testWidgets(
      'TravelWizardsApp applies text scaling from AccessibilityService',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final accessibility = AccessibilityService.instance;
        accessibility.setTextScaleFactor(1.5);
        addTearDown(() => accessibility.setTextScaleFactor(1.0));

        final captureKey = GlobalKey();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: Builder(
                    key: captureKey,
                    builder: (context) => const Text('Sample text'),
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          TravelWizardsApp(
            lightTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
            ),
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        final context = captureKey.currentContext!;
        final scaler = MediaQuery.of(context).textScaler;
        expect(scaler.scale(10), closeTo(15, 0.01));
      },
    );

    testWidgets('PlanTrip step indicator exposes descriptive semantics', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final controller = TripPlanningController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(home: PlanTripScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      final handle = tester.ensureSemantics();
      try {
        final finder = find.bySemanticsLabel('Step 1 of 4: Trip style');
        expect(finder, findsOneWidget);
        final node = tester.getSemantics(finder);
        expect(node.value, 'Current step');
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Autocomplete suggestions include screen reader labels', (
      tester,
    ) async {
      PlacesAutocompleteField.overrideDefaultServiceForTesting(
        MockPlacesApiService(),
      );
      addTearDown(
        () => PlacesAutocompleteField.overrideDefaultServiceForTesting(null),
      );
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: PlacesAutocompleteField(
                controller: controller,
                labelText: 'Destination',
                hintText: 'Enter destination city',
              ),
            ),
          ),
        ),
      );

      final fieldFinder = find.byType(TextField);
      expect(fieldFinder, findsOneWidget);

      await tester.tap(fieldFinder);
      await tester.enterText(fieldFinder, 'Bang');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final handle = tester.ensureSemantics();
      try {
        final finder = find.bySemanticsLabel('Bangalore, India');
        expect(finder, findsWidgets);
        final node = tester.getSemantics(finder);
        expect(node.hint, 'Select place suggestion');
      } finally {
        handle.dispose();
      }
    });
  });
}
