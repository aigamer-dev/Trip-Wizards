import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:travel_wizards/src/shared/services/secrets_management_service.dart';

/// Represents a place prediction from Google Places API
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final List<String> types;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.types,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
      mainText: json['structured_formatting']['main_text'] as String,
      secondaryText: json['structured_formatting']['secondary_text'] as String,
      types: List<String>.from(json['types'] as List),
    );
  }
}

/// Represents detailed place information
class PlaceDetails {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? formattedAddress;
  final List<String> types;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    required this.types,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return PlaceDetails(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      address: json['formatted_address'] as String,
      latitude: location['lat'] as double,
      longitude: location['lng'] as double,
      formattedAddress: json['formatted_address'] as String,
      types: List<String>.from(json['types'] as List),
    );
  }
}

/// Service for Google Places API integration
class PlacesApiService {
  static final PlacesApiService _instance = PlacesApiService._internal();
  static PlacesApiService get instance => _instance;

  PlacesApiService._internal();

  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Get the Places API key from secrets management
  Future<String?> _getApiKey() async {
    try {
      final secrets = SecretsManagementService.instance.getGoogleApiSecrets();
      return secrets.placesApiKey;
    } catch (e) {
      debugPrint('❌ Error getting Places API key: $e');
      return null;
    }
  }

  /// Search for places using autocomplete
  Future<List<PlacePrediction>> searchPlaces(
    String query, {
    String? sessionToken,
    String? language = 'en',
    List<String>? types,
    String? components,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final apiKey = await _getApiKey();
      if (apiKey == null) {
        debugPrint('❌ Places API key not available');
        return [];
      }

      final uri = Uri.parse('$_baseUrl/autocomplete/json').replace(
        queryParameters: {
          'input': query,
          'key': apiKey,
          'language': language,
          if (sessionToken != null) 'sessiontoken': sessionToken,
          if (types != null && types.isNotEmpty) 'types': types.join('|'),
          if (components != null) 'components': components,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions
              .map(
                (prediction) => PlacePrediction.fromJson(
                  prediction as Map<String, dynamic>,
                ),
              )
              .toList();
        } else {
          debugPrint('❌ Places API error: ${data['status']}');
          return [];
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error searching places: $e');
      return [];
    }
  }

  /// Get detailed information about a place
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String? language = 'en',
    List<String>? fields,
  }) async {
    try {
      final apiKey = await _getApiKey();
      if (apiKey == null) {
        debugPrint('❌ Places API key not available');
        return null;
      }

      final uri = Uri.parse('$_baseUrl/details/json').replace(
        queryParameters: {
          'place_id': placeId,
          'key': apiKey,
          'language': language,
          if (sessionToken != null) 'sessiontoken': sessionToken,
          if (fields != null && fields.isNotEmpty) 'fields': fields.join(','),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result'] as Map<String, dynamic>);
        } else {
          debugPrint('❌ Places API details error: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting place details: $e');
      return null;
    }
  }

  /// Search for cities/airports for travel planning
  Future<List<PlacePrediction>> searchCitiesAndAirports(
    String query, {
    String? sessionToken,
  }) async {
    return searchPlaces(
      query,
      sessionToken: sessionToken,
      types: ['(cities)', 'airport'],
      components:
          'country:us|country:ca|country:mx|country:gb|country:de|country:fr|country:it|country:es|country:jp|country:au',
    );
  }

  /// Search for general locations (cities, towns, etc.)
  Future<List<PlacePrediction>> searchLocations(
    String query, {
    String? sessionToken,
  }) async {
    return searchPlaces(
      query,
      sessionToken: sessionToken,
      types: ['(cities)', 'locality', 'administrative_area_level_1'],
    );
  }
}
