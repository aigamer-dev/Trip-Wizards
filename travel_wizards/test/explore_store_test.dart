import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/data/explore_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Ensure a clean instance state per test
    await ExploreStore.instance.setTags({});
    await ExploreStore.instance.setFilterBudget(null);
    await ExploreStore.instance.setFilterDuration(null);
  });

  test('initial load has empty selections', () async {
    await ExploreStore.instance.load();
    expect(ExploreStore.instance.selectedTags, isEmpty);
    expect(ExploreStore.instance.savedIdeaIds, isEmpty);
    expect(ExploreStore.instance.filterBudget, isNull);
    expect(ExploreStore.instance.filterDuration, isNull);
  });

  test('toggle tag persists across loads', () async {
    await ExploreStore.instance.toggleTag('Weekend');
    await ExploreStore.instance.toggleTag('Adventure');

    // Simulate app restart by reloading from SharedPreferences
    await ExploreStore.instance.load();
    expect(
      ExploreStore.instance.selectedTags,
      containsAll({'Weekend', 'Adventure'}),
    );

    // Toggle off and verify persistence
    await ExploreStore.instance.toggleTag('Weekend');
    await ExploreStore.instance.load();
    expect(ExploreStore.instance.selectedTags, isNot(contains('Weekend')));
    expect(ExploreStore.instance.selectedTags, contains('Adventure'));
  });

  test('saved ideas toggle and isSaved()', () async {
    await ExploreStore.instance.toggleSaved('idea_1');
    expect(ExploreStore.instance.isSaved('idea_1'), isTrue);

    await ExploreStore.instance.toggleSaved('idea_1');
    expect(ExploreStore.instance.isSaved('idea_1'), isFalse);

    // Persist and reload
    await ExploreStore.instance.toggleSaved('idea_2');
    await ExploreStore.instance.load();
    expect(ExploreStore.instance.isSaved('idea_2'), isTrue);
  });

  test('filters (budget/duration) persist across loads', () async {
    await ExploreStore.instance.setFilterBudget('low');
    await ExploreStore.instance.setFilterDuration('2-3');

    await ExploreStore.instance.load();
    expect(ExploreStore.instance.filterBudget, 'low');
    expect(ExploreStore.instance.filterDuration, '2-3');

    // Clear filters
    await ExploreStore.instance.setFilterBudget(null);
    await ExploreStore.instance.setFilterDuration(null);

    await ExploreStore.instance.load();
    expect(ExploreStore.instance.filterBudget, isNull);
    expect(ExploreStore.instance.filterDuration, isNull);
  });
}
