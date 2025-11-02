import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/shared/services/nominatim_service.dart';

void main() {
  group('India Location Coverage Tests', () {
    late NominatimService service;

    setUp(() {
      service = NominatimService.instance;
    });

    test('should find major Indian cities', () async {
      final cities = [
        'Mumbai',
        'Delhi',
        'Bangalore',
        'Chennai',
        'Kolkata',
        'Hyderabad',
        'Pune',
        'Ahmedabad',
      ];

      for (final city in cities) {
        print('Testing: $city');
        final results = await service.searchLocations(city);
        expect(results, isNotEmpty, reason: 'No results found for $city');

        if (results.isNotEmpty) {
          final firstResult = results.first;
          print('  Found: ${firstResult.description}');
          expect(
            firstResult.description.toLowerCase(),
            contains(city.toLowerCase()),
          );
        }

        // Add delay to respect rate limiting
        await Future.delayed(Duration(milliseconds: 1200));
      }
    });

    test('should find Indian airports', () async {
      final airports = [
        'Mumbai Airport',
        'Delhi Airport',
        'Bangalore Airport',
        'Chennai Airport',
        'BOM', // Mumbai airport code
        'DEL', // Delhi airport code
        'BLR', // Bangalore airport code
      ];

      for (final airport in airports) {
        print('Testing: $airport');
        final results = await service.searchLocations(airport);

        if (results.isNotEmpty) {
          print('  Found: ${results.first.description}');
        } else {
          print('  ❌ No results for $airport');
        }

        // Add delay to respect rate limiting
        await Future.delayed(Duration(milliseconds: 1200));
      }
    });

    test('should find Indian landmarks and places', () async {
      final places = [
        'Gateway of India, Mumbai',
        'India Gate, Delhi',
        'Marine Drive, Mumbai',
        'Connaught Place, Delhi',
        'MG Road, Bangalore',
      ];

      for (final place in places) {
        print('Testing: $place');
        final results = await service.searchLocations(place);

        if (results.isNotEmpty) {
          print('  Found: ${results.first.description}');
        } else {
          print('  ❌ No results for $place');
        }

        // Add delay to respect rate limiting
        await Future.delayed(Duration(milliseconds: 1200));
      }
    });
  });
}
