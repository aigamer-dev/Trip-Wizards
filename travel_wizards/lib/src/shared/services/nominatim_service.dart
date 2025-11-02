import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Represents a location prediction from Nominatim (OpenStreetMap)
class LocationPrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double latitude;
  final double longitude;
  final String type;

  LocationPrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  factory LocationPrediction.fromNominatimJson(Map<String, dynamic> json) {
    // Extract display name parts
    final displayName = json['display_name'] as String;
    final nameParts = displayName.split(',');
    final mainText = nameParts.first.trim();
    final secondaryText = nameParts.length > 1
        ? nameParts.skip(1).join(',').trim()
        : '';

    return LocationPrediction(
      placeId: json['place_id'].toString(),
      description: displayName,
      mainText: mainText,
      secondaryText: secondaryText,
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      type: json['type'] as String? ?? 'unknown',
    );
  }

  // Convert to PlacePrediction for backward compatibility
  Map<String, dynamic> toPlacePrediction() {
    return {
      'placeId': placeId,
      'description': description,
      'mainText': mainText,
      'secondaryText': secondaryText,
      'types': [type],
    };
  }
}

/// Free geocoding service using OpenStreetMap's Nominatim API
/// NO API KEY REQUIRED - Completely free to use
///
/// Usage Policy: https://operations.osmfoundation.org/policies/nominatim/
/// - Max 1 request per second
/// - Must provide a valid User-Agent header
/// - For production, consider running your own Nominatim instance
class NominatimService {
  static final NominatimService _instance = NominatimService._internal();
  static NominatimService get instance => _instance;

  NominatimService._internal();

  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'TravelWizards/1.0 (Flutter App)';

  // Rate limiting: 1 request per second as per Nominatim usage policy
  DateTime? _lastRequestTime;
  static const _minRequestInterval = Duration(milliseconds: 1100);

  /// Enforce rate limiting (1 request per second)
  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Search for locations using autocomplete with India-first priority
  ///
  /// This is completely FREE and requires NO API KEY
  /// Optimized for Indian locations and travel patterns
  Future<List<LocationPrediction>> searchLocations(
    String query, {
    String? language = 'en',
    int limit = 10,
    bool prioritizeIndia = true,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      await _enforceRateLimit();

      List<LocationPrediction> results = [];

      // First, try India-specific search for better results
      if (prioritizeIndia) {
        results = await _searchWithCountryBias(query, 'IN', language, limit);

        // If we have good results, return them
        if (results.isNotEmpty && _hasRelevantIndianResults(results, query)) {
          return results;
        }
      }

      // Fallback to global search
      final globalResults = await _searchGlobal(query, language, limit);

      // Combine results, giving priority to Indian locations
      if (results.isNotEmpty) {
        final combinedResults = <LocationPrediction>[];
        combinedResults.addAll(results.where((r) => _isIndianLocation(r)));
        combinedResults.addAll(
          globalResults.where((r) => !_isDuplicate(r, combinedResults)),
        );
        return combinedResults.take(limit).toList();
      }

      return globalResults;
    } catch (e) {
      debugPrint('❌ Nominatim service error: $e');
      return [];
    }
  }

  /// Search with country bias (India-first)
  Future<List<LocationPrediction>> _searchWithCountryBias(
    String query,
    String countryCode,
    String? language,
    int limit,
  ) async {
    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': limit.toString(),
        'countrycodes': countryCode,
        'accept-language': language ?? 'en',
        'dedupe': '1',
      },
    );

    final response = await http.get(uri, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map(
            (item) => LocationPrediction.fromNominatimJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } else {
      debugPrint('❌ Nominatim HTTP error: ${response.statusCode}');
      return [];
    }
  }

  /// Global search (fallback)
  Future<List<LocationPrediction>> _searchGlobal(
    String query,
    String? language,
    int limit,
  ) async {
    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': limit.toString(),
        'accept-language': language ?? 'en',
        'dedupe': '1',
      },
    );

    final response = await http.get(uri, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map(
            (item) => LocationPrediction.fromNominatimJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } else {
      debugPrint('❌ Nominatim HTTP error: ${response.statusCode}');
      return [];
    }
  }

  /// Check if location is in India
  bool _isIndianLocation(LocationPrediction location) {
    return location.description.toLowerCase().contains('india') ||
        location.description.toLowerCase().contains('bharat');
  }

  /// Check if we have relevant Indian results
  bool _hasRelevantIndianResults(
    List<LocationPrediction> results,
    String query,
  ) {
    if (results.isEmpty) return false;

    // At least one result should be in India and match the query reasonably
    return results.any(
      (result) =>
          _isIndianLocation(result) &&
          result.mainText.toLowerCase().contains(
            query.toLowerCase().split(' ').first,
          ),
    );
  }

  /// Check for duplicate locations
  bool _isDuplicate(
    LocationPrediction location,
    List<LocationPrediction> existing,
  ) {
    return existing.any(
      (existing) =>
          existing.placeId == location.placeId ||
          (existing.latitude == location.latitude &&
              existing.longitude == location.longitude),
    );
  }

  /// Search for cities and airports for travel planning
  Future<List<LocationPrediction>> searchCitiesAndAirports(
    String query, {
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      await _enforceRateLimit();

      // Search with city/town/airport emphasis
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': limit.toString(),
          // Prioritize cities, towns, and airports
          'featuretype': 'city',
          'accept-language': 'en',
        },
      );

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Filter to prioritize cities, towns, and airports
        final predictions = data
            .map(
              (item) => LocationPrediction.fromNominatimJson(
                item as Map<String, dynamic>,
              ),
            )
            .where((pred) {
              final type = pred.type.toLowerCase();
              final desc = pred.description.toLowerCase();
              return type.contains('city') ||
                  type.contains('town') ||
                  type.contains('village') ||
                  type.contains('airport') ||
                  desc.contains('airport');
            })
            .toList();

        return predictions;
      } else {
        debugPrint('❌ Nominatim HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error searching cities/airports: $e');
      return [];
    }
  }

  /// Get details of a specific location by place ID
  /// Note: Nominatim uses OSM IDs, not Google Place IDs
  Future<LocationPrediction?> getLocationDetails(String osmId) async {
    try {
      await _enforceRateLimit();

      final uri = Uri.parse('$_baseUrl/details').replace(
        queryParameters: {
          'osmtype': 'N', // Node (can be N for node, W for way, R for relation)
          'osmid': osmId,
          'format': 'json',
        },
      );

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LocationPrediction.fromNominatimJson(data);
      } else {
        debugPrint('❌ Error getting location details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting location details: $e');
      return null;
    }
  }

  /// Reverse geocode: Get location from coordinates
  Future<LocationPrediction?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      await _enforceRateLimit();

      final uri = Uri.parse('$_baseUrl/reverse').replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'format': 'json',
          'addressdetails': '1',
        },
      );

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LocationPrediction.fromNominatimJson(data);
      } else {
        debugPrint('❌ Error reverse geocoding: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error reverse geocoding: $e');
      return null;
    }
  }
}
