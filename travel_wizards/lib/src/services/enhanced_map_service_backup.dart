import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travel_wizards/src/models/trip_location.dart' as trip_models;

/// Enhanced map service for travel planning and trip visualization
class EnhancedMapService {
  static final EnhancedMapService _instance = EnhancedMapService._internal();
  static EnhancedMapService get instance => _instance;
  EnhancedMapService._internal();

  // Map state
  final Map<String, Completer<GoogleMapController>> _controllers = {};
  final Map<String, Set<Marker>> _markers = {};
  final Map<String, Set<Polyline>> _polylines = {};
  final Map<String, LatLng?> _userLocations = {};

  // Stream controllers
  final StreamController<MapUpdate> _mapUpdateController =
      StreamController<MapUpdate>.broadcast();

  // Getters
  Stream<MapUpdate> get mapUpdateStream => _mapUpdateController.stream;

  /// Initialize map controller for a specific map
  Future<GoogleMapController> initializeController(
    String mapId,
    GoogleMapController controller,
  ) async {
    if (_controllers.containsKey(mapId)) {
      _controllers[mapId]!.complete(controller);
    } else {
      final completer = Completer<GoogleMapController>();
      completer.complete(controller);
      _controllers[mapId] = completer;
    }

    return controller;
  }

  /// Get map controller for specific map
  Future<GoogleMapController?> getController(String mapId) async {
    try {
      if (_controllers.containsKey(mapId)) {
        return await _controllers[mapId]!.future;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting map controller: $e');
      return null;
    }
  }

  /// Adds location markers to the map
  Future<void> addMarkers(String mapId, List<trip_models.TripLocation> locations) async {
    try {
      final markers = <Marker>{};

      for (int i = 0; i < locations.length; i++) {
        final location = locations[i];

        final marker = Marker(
          markerId: MarkerId('${mapId}_${location.id}'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title: location.name,
            snippet: location.description,
          ),
          icon: await _getMarkerIcon(location.type),
          onTap: () => _onMarkerTapped(mapId, location),
        );

        markers.add(marker);
      }

      _markers[mapId] = markers;

      // Update map
      final controller = await getController(mapId);
      if (controller != null) {
        // Map will be updated through the markers parameter in GoogleMap widget
        _mapUpdateController.add(
          MapUpdate(
            mapId: mapId,
            type: MapUpdateType.markersUpdated,
            markers: markers,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding markers: $e');
    }
  }

  /// Add route polyline between locations
  Future<void> addRoute(String mapId, List<TripLocation> locations) async {
    try {
      if (locations.length < 2) return;

      final polylines = <Polyline>{};

      // Create route between consecutive locations
      for (int i = 0; i < locations.length - 1; i++) {
        final start = locations[i];
        final end = locations[i + 1];

        final polyline = Polyline(
          polylineId: PolylineId('${mapId}_route_$i'),
          points: [
            LatLng(start.latitude, start.longitude),
            LatLng(end.latitude, end.longitude),
          ],
          color: const Color(0xFF2196F3),
          width: 4,
          patterns: [],
        );

        polylines.add(polyline);
      }

      _polylines[mapId] = polylines;

      _mapUpdateController.add(
        MapUpdate(
          mapId: mapId,
          type: MapUpdateType.polylinesUpdated,
          polylines: polylines,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error adding route: $e');
    }
  }

  /// Center map on locations
  Future<void> centerOnLocations(
    String mapId,
    List<TripLocation> locations,
  ) async {
    try {
      if (locations.isEmpty) return;

      final controller = await getController(mapId);
      if (controller == null) return;

      if (locations.length == 1) {
        // Single location - center on it
        await controller.animateCamera(
          CameraUpdateOptions.newLatLngZoom(
            LatLng(locations.first.latitude, locations.first.longitude),
            14.0,
          ),
        );
      } else {
        // Multiple locations - fit all in view
        final bounds = _calculateBounds(locations);
        await controller.animateCamera(
          CameraUpdateOptions.newLatLngBounds(bounds, 100.0),
        );
      }
    } catch (e) {
      debugPrint('❌ Error centering map: $e');
    }
  }

  /// Get user's current location
  Future<Position?> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestedPermission = await Geolocator.requestPermission();
        if (requestedPermission == LocationPermission.denied) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      return null;
    }
  }

  /// Add user location marker
  Future<void> addUserLocation(String mapId, {Position? userLocation}) async {
    try {
      userLocation ??= await getCurrentLocation();
      if (userLocation == null) return;

      final userLatLng = LatLng(userLocation.latitude, userLocation.longitude);
      _userLocations[mapId] = userLatLng;

      // Add user location marker
      final userMarker = Marker(
        markerId: const MarkerId('user_location'),
        position: userLatLng,
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Current location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      // Add to existing markers
      final currentMarkers = _markers[mapId] ?? <Marker>{};
      currentMarkers.add(userMarker);
      _markers[mapId] = currentMarkers;

      _mapUpdateController.add(
        MapUpdate(
          mapId: mapId,
          type: MapUpdateType.userLocationUpdated,
          userLocation: userLatLng,
          markers: currentMarkers,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error adding user location: $e');
    }
  }

  /// Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Get distance to location from user
  Future<double?> getDistanceToLocation(TripLocation location) async {
    try {
      final userLocation = await getCurrentLocation();
      if (userLocation == null) return null;

      return calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        location.latitude,
        location.longitude,
      );
    } catch (e) {
      debugPrint('❌ Error calculating distance: $e');
      return null;
    }
  }

  /// Search nearby places
  Future<List<TripLocation>> searchNearbyPlaces(
    LatLng center,
    String query, {
    double radiusKm = 5.0,
  }) async {
    try {
      // This would typically integrate with Google Places API
      // For now, return mock data
      return [
        TripLocation(
          id: 'nearby_1',
          name: 'Tourist Attraction',
          latitude: center.latitude + 0.01,
          longitude: center.longitude + 0.01,
          description: 'Popular tourist destination',
          type: TripLocationType.attraction,
        ),
        TripLocation(
          id: 'nearby_2',
          name: 'Restaurant',
          latitude: center.latitude - 0.01,
          longitude: center.longitude + 0.01,
          description: 'Highly rated restaurant',
          type: TripLocationType.restaurant,
        ),
      ];
    } catch (e) {
      debugPrint('❌ Error searching nearby places: $e');
      return [];
    }
  }

  /// Get trip overview with map bounds and center
  TripMapOverview getTripOverview(List<TripLocation> locations) {
    if (locations.isEmpty) {
      return const TripMapOverview(
        center: LatLng(0, 0),
        bounds: null,
        totalDistance: 0,
        estimatedDuration: Duration.zero,
      );
    }

    final bounds = _calculateBounds(locations);
    final center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    // Calculate total route distance
    double totalDistance = 0;
    for (int i = 0; i < locations.length - 1; i++) {
      totalDistance += calculateDistance(
        locations[i].latitude,
        locations[i].longitude,
        locations[i + 1].latitude,
        locations[i + 1].longitude,
      );
    }

    // Estimate duration (assuming 50km/h average travel speed)
    final estimatedDuration = Duration(
      minutes: ((totalDistance / 1000) * 60 / 50).round(),
    );

    return TripMapOverview(
      center: center,
      bounds: bounds,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
    );
  }

  /// Get map style for different themes
  String getMapStyle({bool isDarkMode = false}) {
    if (isDarkMode) {
      return '''[
        {
          "elementType": "geometry",
          "stylers": [{"color": "#242f3e"}]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#242f3e"}]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#746855"}]
        }
      ]''';
    }
    return '[]'; // Default style
  }

  /// Get markers for map
  Set<Marker> getMarkers(String mapId) {
    return _markers[mapId] ?? <Marker>{};
  }

  /// Get polylines for map
  Set<Polyline> getPolylines(String mapId) {
    return _polylines[mapId] ?? <Polyline>{};
  }

  /// Private helper methods
  Future<BitmapDescriptor> _getMarkerIcon(TripLocationType type) async {
    try {
      switch (type) {
        case TripLocationType.hotel:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
        case TripLocationType.restaurant:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          );
        case TripLocationType.attraction:
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        case TripLocationType.transport:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );
        case TripLocationType.activity:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          );
        case TripLocationType.shopping:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueCyan,
          );
        case TripLocationType.other:
          return BitmapDescriptor.defaultMarker;
      }
    } catch (e) {
      debugPrint('❌ Error creating marker icon: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  void _onMarkerTapped(String mapId, TripLocation location) {
    debugPrint('📍 Marker tapped: ${location.name}');

    _mapUpdateController.add(
      MapUpdate(
        mapId: mapId,
        type: MapUpdateType.markerTapped,
        tappedLocation: location,
      ),
    );
  }

  LatLngBounds _calculateBounds(List<TripLocation> locations) {
    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final location in locations) {
      minLat = math.min(minLat, location.latitude);
      maxLat = math.max(maxLat, location.latitude);
      minLng = math.min(minLng, location.longitude);
      maxLng = math.max(maxLng, location.longitude);
    }

    // Add padding
    const padding = 0.01;
    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  /// Dispose resources
  void dispose() {
    _mapUpdateController.close();
    _controllers.clear();
    _markers.clear();
    _polylines.clear();
    _userLocations.clear();
  }
}

// Data models
class MapUpdate {
  final String mapId;
  final MapUpdateType type;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final LatLng? userLocation;
  final trip_models.TripLocation? tappedLocation;

  const MapUpdate({
    required this.mapId,
    required this.type,
    this.markers,
    this.polylines,
    this.userLocation,
    this.tappedLocation,
  });
}

enum MapUpdateType {
  markersUpdated,
  polylinesUpdated,
  userLocationUpdated,
  markerTapped,
}

// Extension for easier CameraUpdate usage
extension CameraUpdateOptions on CameraUpdate {
  static CameraUpdate newLatLngZoom(LatLng latLng, double zoom) {
    return CameraUpdate.newLatLngZoom(latLng, zoom);
  }

  static CameraUpdate newLatLngBounds(LatLngBounds bounds, double padding) {
    return CameraUpdate.newLatLngBounds(bounds, padding);
  }
}
