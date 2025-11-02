import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/shared/services/nominatim_service.dart';

void main() {
  group('NominatimService Tests', () {
    late NominatimService service;

    setUp(() {
      service = NominatimService.instance;
    });

    test('should search for locations and return results', () async {
      // Test searching for a well-known city
      final results = await service.searchLocations('Mumbai');

      expect(results, isNotEmpty);
      expect(results.first.description, contains('Mumbai'));
      expect(results.first.latitude, isNotNull);
      expect(results.first.longitude, isNotNull);
    });

    test('should handle empty search query', () async {
      final results = await service.searchLocations('');
      expect(results, isEmpty);
    });

    test('should handle very short query and return results', () async {
      final results = await service.searchLocations('a');
      // Nominatim may return results for single letters, that's okay
      expect(results, isA<List<LocationPrediction>>());
    });

    test('should limit results properly', () async {
      final results = await service.searchLocations('New York', limit: 3);
      expect(results.length, lessThanOrEqualTo(3));
    });

    test('should parse location prediction correctly', () async {
      final results = await service.searchLocations('Paris, France');

      if (results.isNotEmpty) {
        final result = results.first;
        expect(result.placeId, isNotEmpty);
        expect(result.description, isNotEmpty);
        expect(result.mainText, isNotEmpty);
        expect(result.latitude, isA<double>());
        expect(result.longitude, isA<double>());
      }
    });
  });
}
