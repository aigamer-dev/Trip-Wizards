import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/data/plan_trip_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanTripStore', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PlanTripStore.instance.clear();
    });

    test('load returns nulls when empty', () async {
      await PlanTripStore.instance.load();
      expect(PlanTripStore.instance.durationDays, isNull);
      expect(PlanTripStore.instance.budget, isNull);
    });

    test('set and load duration/budget', () async {
      await PlanTripStore.instance.setDuration(5);
      await PlanTripStore.instance.setBudget('low');

      final store2 = PlanTripStore.instance;
      await store2.load();
      expect(store2.durationDays, 5);
      expect(store2.budget, 'low');
    });

    test('clear removes stored values', () async {
      await PlanTripStore.instance.setDuration(4);
      await PlanTripStore.instance.setBudget('high');
      await PlanTripStore.instance.clear();

      final store2 = PlanTripStore.instance;
      await store2.load();
      expect(store2.durationDays, isNull);
      expect(store2.budget, isNull);
    });
  });
}
