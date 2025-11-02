import 'package:travel_wizards/src/shared/services/places_api_service.dart';

/// Deterministic mock implementation of [PlacesApiService] for widget tests.
class MockPlacesApiService implements PlacesApiService {
  @override
  Future<List<PlacePrediction>> searchPlaces(
    String query, {
    String? sessionToken,
    String? language = 'en',
    List<String>? types,
    String? components,
  }) async {
    final lower = query.toLowerCase();
    if (lower.contains('bang')) {
      return [
        PlacePrediction(
          placeId: '1',
          description: 'Bangalore, India',
          mainText: 'Bangalore',
          secondaryText: 'India',
          types: const ['locality'],
        ),
      ];
    }
    if (lower.contains('chen')) {
      return [
        PlacePrediction(
          placeId: '2',
          description: 'Chennai, India',
          mainText: 'Chennai',
          secondaryText: 'India',
          types: const ['locality'],
        ),
      ];
    }
    return [];
  }

  @override
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String? language = 'en',
    List<String>? fields,
  }) async {
    if (placeId == '1') {
      return PlaceDetails(
        placeId: '1',
        name: 'Bangalore',
        address: 'Bangalore, India',
        latitude: 12.97,
        longitude: 77.59,
        formattedAddress: 'Bangalore, India',
        types: const ['locality'],
      );
    }
    if (placeId == '2') {
      return PlaceDetails(
        placeId: '2',
        name: 'Chennai',
        address: 'Chennai, India',
        latitude: 13.08,
        longitude: 80.27,
        formattedAddress: 'Chennai, India',
        types: const ['locality'],
      );
    }
    return null;
  }

  @override
  Future<List<PlacePrediction>> searchCitiesAndAirports(
    String query, {
    String? sessionToken,
  }) async {
    return searchPlaces(
      query,
      sessionToken: sessionToken,
      types: const ['(cities)', 'airport'],
    );
  }

  @override
  Future<List<PlacePrediction>> searchLocations(
    String query, {
    String? sessionToken,
  }) async {
    return searchPlaces(
      query,
      sessionToken: sessionToken,
      types: const ['(cities)', 'locality'],
    );
  }
}
