import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/screens/trip/plan_trip_screen.dart';
import 'package:travel_wizards/src/data/plan_trip_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanTrip draft flow', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PlanTripStore.instance.clear();
    });

    Future<void> pumpPlanTrip(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PlanTripScreen())),
      );
      // Let async load in initState complete
      await tester.pumpAndSettle();
      expect(latestPlanTripState, isNotNull);
    }

    testWidgets('save persists duration, budget, notes', (tester) async {
      await pumpPlanTrip(tester);
      // Use debug helpers to set state
      latestPlanTripState!.debugSetDuration(5);
      latestPlanTripState!.debugSetBudget(Budget.high);
      latestPlanTripState!.debugJumpToReview();
      const notesText = 'This is a test note.';
      latestPlanTripState!.debugSetNotes(notesText);
      await tester.pumpAndSettle();

      // Ensure nothing persisted yet
      await PlanTripStore.instance.load();
      expect(PlanTripStore.instance.durationDays, isNull);
      expect(PlanTripStore.instance.budget, isNull);
      expect(PlanTripStore.instance.notes, isNull);

      // Trigger back with auto action 'save'
      latestPlanTripState!.debugSetAutoPopAction('save');
      final ctx = tester.element(find.byType(PlanTripScreen));
      final didPop = await latestPlanTripState!.attemptPop(ctx);
      expect(didPop, isTrue);

      // Verify persisted
      await PlanTripStore.instance.load();
      expect(PlanTripStore.instance.durationDays, 5);
      expect(PlanTripStore.instance.budget, 'high');
      expect(PlanTripStore.instance.notes, notesText);
    });

    testWidgets('discard clears persisted values', (tester) async {
      await pumpPlanTrip(tester);
      // Use debug helpers
      latestPlanTripState!.debugSetDuration(4);
      latestPlanTripState!.debugSetBudget(Budget.low);
      latestPlanTripState!.debugJumpToReview();
      latestPlanTripState!.debugSetNotes('Temp notes');
      await tester.pumpAndSettle();

      // Discard
      latestPlanTripState!.debugSetAutoPopAction('discard');
      final ctx = tester.element(find.byType(PlanTripScreen));
      final didPop = await latestPlanTripState!.attemptPop(ctx);
      expect(didPop, isTrue);

      await PlanTripStore.instance.load();
      expect(PlanTripStore.instance.durationDays, isNull);
      expect(PlanTripStore.instance.budget, isNull);
      expect(PlanTripStore.instance.notes, isNull);
    });

    testWidgets('preloads existing notes into review field', (tester) async {
      // Seed existing notes in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'plan_trip_notes': 'Seeded note from storage',
      });

      await pumpPlanTrip(tester);

      // Jump directly to review
      latestPlanTripState!.debugJumpToReview();
      await tester.pumpAndSettle();

      // The TextField should show the seeded note
      expect(find.byType(TextField), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Seeded note from storage');
    });
  });
}
