import 'package:flutter/foundation.dart';
import 'nominatim_service.dart';

/// Enhanced location service optimized for Indian travel
/// Combines multiple free APIs for best Indian location coverage
class IndianLocationService {
  static final IndianLocationService _instance =
      IndianLocationService._internal();
  static IndianLocationService get instance => _instance;

  IndianLocationService._internal();

  final NominatimService _nominatim = NominatimService.instance;

  /// Indian airport codes to full names mapping
  static const Map<String, Map<String, String>> _indianAirports = {
    'BOM': {
      'name': 'Chhatrapati Shivaji Maharaj International Airport',
      'city': 'Mumbai',
    },
    'DEL': {'name': 'Indira Gandhi International Airport', 'city': 'Delhi'},
    'BLR': {'name': 'Kempegowda International Airport', 'city': 'Bangalore'},
    'MAA': {'name': 'Chennai International Airport', 'city': 'Chennai'},
    'CCU': {
      'name': 'Netaji Subhas Chandra Bose International Airport',
      'city': 'Kolkata',
    },
    'HYD': {'name': 'Rajiv Gandhi International Airport', 'city': 'Hyderabad'},
    'PNQ': {'name': 'Pune Airport', 'city': 'Pune'},
    'AMD': {
      'name': 'Sardar Vallabhbhai Patel International Airport',
      'city': 'Ahmedabad',
    },
    'GOI': {'name': 'Goa International Airport', 'city': 'Goa'},
    'JAI': {'name': 'Jaipur International Airport', 'city': 'Jaipur'},
    'COK': {'name': 'Cochin International Airport', 'city': 'Kochi'},
    'TRV': {
      'name': 'Trivandrum International Airport',
      'city': 'Thiruvananthapuram',
    },
    'VNS': {'name': 'Lal Bahadur Shastri Airport', 'city': 'Varanasi'},
    'IXC': {'name': 'Chandigarh Airport', 'city': 'Chandigarh'},
    'GAU': {
      'name': 'Lokpriya Gopinath Bordoloi International Airport',
      'city': 'Guwahati',
    },
  };

  /// Common Indian city name variations
  static const Map<String, List<String>> _cityVariations = {
    'Mumbai': ['Bombay'],
    'Chennai': ['Madras'],
    'Kolkata': ['Calcutta'],
    'Bangalore': ['Bengaluru'],
    'Thiruvananthapuram': ['Trivandrum'],
    'Kochi': ['Cochin'],
    'Vadodara': ['Baroda'],
    'Mysore': ['Mysuru'],
  };

  /// Popular Indian destinations and landmarks
  static const List<String> _popularIndianPlaces = [
    'Gateway of India, Mumbai',
    'India Gate, Delhi',
    'Red Fort, Delhi',
    'Taj Mahal, Agra',
    'Hawa Mahal, Jaipur',
    'Golden Temple, Amritsar',
    'Mysore Palace',
    'Hampi',
    'Goa Beaches',
    'Kerala Backwaters',
    'Darjeeling',
    'Shimla',
    'Manali',
    'Rishikesh',
    'Varanasi Ghats',
    'Udaipur City Palace',
    'Jaisalmer Fort',
    'Mahabalipuram',
    'Pondicherry',
    'Ooty',
  ];

  /// Search for Indian locations with enhanced coverage
  Future<List<LocationPrediction>> searchIndianLocations(
    String query, {
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return [];

    final results = <LocationPrediction>[];

    // 1. Check if it's an airport code
    final airportResults = _searchAirportCodes(query);
    results.addAll(airportResults);

    // 2. Check city variations
    final cityVariationResults = await _searchCityVariations(query);
    results.addAll(cityVariationResults);

    // 3. Search popular places
    final popularResults = _searchPopularPlaces(query);
    results.addAll(popularResults);

    // 4. Use enhanced Nominatim search (India-first)
    try {
      final nominatimResults = await _nominatim.searchLocations(
        query,
        limit: limit,
        prioritizeIndia: true,
      );

      // Add non-duplicate results
      for (final result in nominatimResults) {
        if (!_isDuplicate(result, results)) {
          results.add(result);
        }
      }
    } catch (e) {
      debugPrint('❌ Error with Nominatim search: $e');
    }

    // 5. Return limited, prioritized results
    return _prioritizeResults(results, query).take(limit).toList();
  }

  /// Search airport codes
  List<LocationPrediction> _searchAirportCodes(String query) {
    final upperQuery = query.toUpperCase().trim();
    final results = <LocationPrediction>[];

    // Exact match
    if (_indianAirports.containsKey(upperQuery)) {
      final airport = _indianAirports[upperQuery]!;
      results.add(_createAirportPrediction(upperQuery, airport));
    }

    // Partial match for longer queries
    for (final entry in _indianAirports.entries) {
      if (entry.key.contains(upperQuery) ||
          entry.value['name']!.toLowerCase().contains(query.toLowerCase()) ||
          entry.value['city']!.toLowerCase().contains(query.toLowerCase())) {
        if (!results.any((r) => r.placeId == 'airport_${entry.key}')) {
          results.add(_createAirportPrediction(entry.key, entry.value));
        }
      }
    }

    return results;
  }

  /// Create airport prediction
  LocationPrediction _createAirportPrediction(
    String code,
    Map<String, String> airport,
  ) {
    return LocationPrediction(
      placeId: 'airport_$code',
      description: '${airport['name']}, ${airport['city']}, India',
      mainText: airport['name']!,
      secondaryText: '${airport['city']}, India ($code)',
      latitude: 0.0, // Would need to be looked up separately
      longitude: 0.0,
      type: 'airport',
    );
  }

  /// Search city variations
  Future<List<LocationPrediction>> _searchCityVariations(String query) async {
    final results = <LocationPrediction>[];
    final lowerQuery = query.toLowerCase();

    for (final entry in _cityVariations.entries) {
      final variations = entry.value.map((v) => v.toLowerCase()).toList();

      if (variations.any((v) => v.contains(lowerQuery))) {
        // Search for the main city name
        try {
          final nominatimResults = await _nominatim.searchLocations(
            entry.key,
            limit: 3,
            prioritizeIndia: true,
          );
          results.addAll(nominatimResults);
        } catch (e) {
          debugPrint('❌ Error searching city variation: $e');
        }
      }
    }

    return results;
  }

  /// Search popular places
  List<LocationPrediction> _searchPopularPlaces(String query) {
    final results = <LocationPrediction>[];
    final lowerQuery = query.toLowerCase();

    for (final place in _popularIndianPlaces) {
      if (place.toLowerCase().contains(lowerQuery)) {
        results.add(
          LocationPrediction(
            placeId: 'popular_${place.hashCode}',
            description: place,
            mainText: place.split(',').first,
            secondaryText: place.contains(',')
                ? place.split(',').skip(1).join(',').trim()
                : 'India',
            latitude: 0.0, // Would need geocoding
            longitude: 0.0,
            type: 'tourism',
          ),
        );
      }
    }

    return results;
  }

  /// Check for duplicates
  bool _isDuplicate(
    LocationPrediction location,
    List<LocationPrediction> existing,
  ) {
    return existing.any(
      (existing) =>
          existing.placeId == location.placeId ||
          existing.description.toLowerCase() ==
              location.description.toLowerCase(),
    );
  }

  /// Prioritize results for Indian users
  List<LocationPrediction> _prioritizeResults(
    List<LocationPrediction> results,
    String query,
  ) {
    // Sort by relevance to Indian travel
    results.sort((a, b) {
      // Airports first
      if (a.type == 'airport' && b.type != 'airport') return -1;
      if (b.type == 'airport' && a.type != 'airport') return 1;

      // Indian locations first
      final aIsIndian = a.description.toLowerCase().contains('india');
      final bIsIndian = b.description.toLowerCase().contains('india');
      if (aIsIndian && !bIsIndian) return -1;
      if (bIsIndian && !aIsIndian) return 1;

      // Exact name matches first
      final queryLower = query.toLowerCase();
      final aExact = a.mainText.toLowerCase() == queryLower;
      final bExact = b.mainText.toLowerCase() == queryLower;
      if (aExact && !bExact) return -1;
      if (bExact && !aExact) return 1;

      return 0;
    });

    return results;
  }
}
