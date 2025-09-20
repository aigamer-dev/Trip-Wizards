import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/data/ideas_repository.dart';

void main() {
  final repo = IdeasRepository.instance;
  final all = repo.getAll();

  group('IdeasRepository', () {
    test('returns all ideas by default', () {
      expect(repo.search(), all);
    });

    test('filters by query (case-insensitive)', () {
      final result = repo.search(query: 'hampi');
      expect(result.length, 1);
      expect(result.first.title, contains('Hampi'));
    });

    test('filters by tags (AND)', () {
      // Only 'Weekend in Hampi' has both Weekend and Budget
      final result = repo.search(tags: {'Weekend', 'Budget'});
      expect(result.length, 1);
      expect(result.first.title, contains('Hampi'));
    });

    test('filters by budget', () {
      final result = repo.search(budget: 'high');
      expect(result.length, 1);
      expect(result.first.title, contains('Ladakh'));
    });

    test('filters by duration bucket 2-3', () {
      final result = repo.search(durationBucket: '2-3');
      expect(
        result.every((e) => e.durationDays >= 2 && e.durationDays <= 3),
        isTrue,
      );
    });

    test('filters by duration bucket 4-5', () {
      final result = repo.search(durationBucket: '4-5');
      expect(
        result.every((e) => e.durationDays >= 4 && e.durationDays <= 5),
        isTrue,
      );
    });

    test('filters by duration bucket 6+', () {
      final result = repo.search(durationBucket: '6+');
      expect(result.every((e) => e.durationDays >= 6), isTrue);
    });

    test('filters by query, tags, budget, and duration together (AND)', () {
      // Only 'Weekend in Hampi' matches all
      final result = repo.search(
        query: 'hampi',
        tags: {'Weekend', 'Budget'},
        budget: 'low',
        durationBucket: '2-3',
      );
      expect(result.length, 1);
      expect(result.first.title, contains('Hampi'));
    });

    test('returns empty list for no matches', () {
      final result = repo.search(query: 'notarealplace');
      expect(result, isEmpty);
    });
  });
}
