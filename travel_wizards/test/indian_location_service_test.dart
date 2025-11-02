import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/shared/services/indian_location_service.dart';

void main() {
  group('Indian Location Service Tests', () {
    late IndianLocationService service;

    setUp(() {
      service = IndianLocationService.instance;
    });

    test('should find Indian airport codes', () async {
      final testCodes = ['BOM', 'DEL', 'BLR', 'MAA', 'CCU'];

      for (final code in testCodes) {
        print('Testing airport code: $code');
        final results = await service.searchIndianLocations(code);

        expect(
          results,
          isNotEmpty,
          reason: 'No results for airport code $code',
        );
        expect(results.first.type, equals('airport'));
        expect(results.first.description.toLowerCase(), contains('airport'));

        print('  Found: ${results.first.description}');
      }
    });

    test('should find major Indian cities with variations', () async {
      final testCities = {
        'Mumbai': 'Bombay',
        'Chennai': 'Madras',
        'Kolkata': 'Calcutta',
        'Bangalore': 'Bengaluru',
      };

      for (final entry in testCities.entries) {
        final mainCity = entry.key;
        final variation = entry.value;

        print('Testing city: $mainCity (variation: $variation)');

        // Test main city name
        final mainResults = await service.searchIndianLocations(mainCity);
        expect(mainResults, isNotEmpty, reason: 'No results for $mainCity');

        // Test variation
        final varResults = await service.searchIndianLocations(variation);
        expect(varResults, isNotEmpty, reason: 'No results for $variation');

        print('  Main: ${mainResults.first.description}');
        print('  Variation: ${varResults.first.description}');

        await Future.delayed(Duration(milliseconds: 1200)); // Rate limiting
      }
    });

    test('should prioritize Indian locations', () async {
      final results = await service.searchIndianLocations('Delhi');

      expect(results, isNotEmpty);

      // First result should be Indian Delhi, not Delaware or other places
      final firstResult = results.first;
      expect(firstResult.description.toLowerCase(), contains('india'));
      // Should contain delhi or related terms (like airport names)
      final containsDelhi =
          firstResult.mainText.toLowerCase().contains('delhi') ||
          firstResult.description.toLowerCase().contains('delhi') ||
          firstResult.mainText.toLowerCase().contains('indira gandhi');
      expect(
        containsDelhi,
        isTrue,
        reason: 'Should find Delhi-related location',
      );

      print('Prioritized result: ${firstResult.description}');
    });

    test('should find popular Indian tourist places', () async {
      final touristPlaces = [
        'Gateway of India',
        'India Gate',
        'Taj Mahal',
        'Red Fort',
        'Golden Temple',
      ];

      for (final place in touristPlaces) {
        print('Testing tourist place: $place');
        final results = await service.searchIndianLocations(place);

        if (results.isNotEmpty) {
          print('  Found: ${results.first.description}');
          // Check if the result is related to the place (more flexible matching)
          final placeWords = place.toLowerCase().split(' ');
          final hasRelevantWord = placeWords.any(
            (word) =>
                results.first.description.toLowerCase().contains(word) ||
                results.first.mainText.toLowerCase().contains(word),
          );
          expect(
            hasRelevantWord,
            isTrue,
            reason: 'Should find relevant result for $place',
          );
        }
      }
    });

    test('should handle mixed queries efficiently', () async {
      final mixedQueries = [
        'Mumbai Airport',
        'Delhi Metro',
        'Bangalore IT Hub',
        'Chennai Beach',
        'Goa Airport',
      ];

      for (final query in mixedQueries) {
        print('Testing mixed query: $query');
        final results = await service.searchIndianLocations(query);

        if (results.isNotEmpty) {
          print('  Found: ${results.first.description}');
          // Should find Indian locations
          expect(
            results.any((r) => r.description.toLowerCase().contains('india')),
            isTrue,
          );
        }

        await Future.delayed(Duration(milliseconds: 1200)); // Rate limiting
      }
    });

    test('should handle empty and invalid queries gracefully', () async {
      final invalidQueries = ['', ' ', 'xyz123', '###'];

      for (final query in invalidQueries) {
        final results = await service.searchIndianLocations(query);
        expect(
          results,
          isA<List>(),
          reason: 'Should return list for query: "$query"',
        );
      }
    });
  });
}
