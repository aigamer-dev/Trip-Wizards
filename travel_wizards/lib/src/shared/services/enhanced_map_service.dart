import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travel_wizards/src/shared/models/trip_location.dart' as trip_models;

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

  // Stream controller for map updates
  final StreamController<MapUpdate> _mapUpdateController =
      StreamController<MapUpdate>.broadcast();

  /// Stream of map updates for reactive UI
  Stream<MapUpdate> get mapUpdateStream => _mapUpdateController.stream;

  /// Initialize map controller for a specific map
  Future<void> initializeController(
    String mapId,
    GoogleMapController controller,
  ) async {
    if (!_controllers.containsKey(mapId)) {
      _controllers[mapId] = Completer<GoogleMapController>();
    }
    if (!_controllers[mapId]!.isCompleted) {
      _controllers[mapId]!.complete(controller);
    }

    // Initialize collections
    _markers[mapId] ??= {};
    _polylines[mapId] ??= {};
  }

  /// Get controller for a specific map
  Future<GoogleMapController?> getController(String mapId) async {
    if (!_controllers.containsKey(mapId)) return null;

    try {
      return await _controllers[mapId]!.future.timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('❌ Error getting controller for map $mapId: $e');
      return null;
    }
  }

  /// Adds location markers to the map
  Future<void> addMarkers(
    String mapId,
    List<trip_models.TripLocation> locations,
  ) async {
    try {
      final Set<Marker> newMarkers = {};

      for (final location in locations) {
        final marker = Marker(
          markerId: MarkerId(location.id),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title: location.name,
            snippet: location.description,
          ),
          icon: await _getMarkerIcon(location.type),
          onTap: () => _onMarkerTapped(mapId, location),
        );
        newMarkers.add(marker);
      }

      _markers[mapId] = newMarkers;

      // Notify listeners
      _mapUpdateController.add(
        MapUpdate(
          mapId: mapId,
          type: MapUpdateType.markersUpdated,
          markers: newMarkers,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error adding markers: $e');
    }
  }

  /// Adds route polylines between locations
  Future<void> addRoute(
    String mapId,
    List<trip_models.TripLocation> locations,
  ) async {
    if (locations.length < 2) return;

    try {
      final Set<Polyline> newPolylines = {};

      // Create polylines between consecutive locations
      for (int i = 0; i < locations.length - 1; i++) {
        final start = locations[i];
        final end = locations[i + 1];

        final polyline = Polyline(
          polylineId: PolylineId('route_${start.id}_${end.id}'),
          points: [
            LatLng(start.latitude, start.longitude),
            LatLng(end.latitude, end.longitude),
          ],
          color: const Color(0xFF2196F3),
          width: 4,
          patterns: [],
        );
        newPolylines.add(polyline);
      }

      _polylines[mapId] = newPolylines;

      // Notify listeners
      _mapUpdateController.add(
        MapUpdate(
          mapId: mapId,
          type: MapUpdateType.polylinesUpdated,
          polylines: newPolylines,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error adding route: $e');
    }
  }

  /// Centers the map on given locations
  Future<void> centerOnLocations(
    String mapId,
    List<trip_models.TripLocation> locations,
  ) async {
    if (locations.isEmpty) return;

    final controller = await getController(mapId);
    if (controller == null) return;

    try {
      if (locations.length == 1) {
        // Single location - center and zoom
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(locations.first.latitude, locations.first.longitude),
            15.0,
          ),
        );
      } else {
        // Multiple locations - fit bounds
        final bounds = _calculateBounds(locations);
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0),
        );
      }
    } catch (e) {
      debugPrint('❌ Error centering on locations: $e');
    }
  }

  /// Adds user location marker
  Future<void> addUserLocation(String mapId) async {
    try {
      final position = await getCurrentLocation();
      if (position != null) {
        _userLocations[mapId] = LatLng(position.latitude, position.longitude);

        // Add user location marker
        final userMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        _markers[mapId] ??= {};
        _markers[mapId]!.add(userMarker);

        // Notify listeners
        final userLatLng = LatLng(position.latitude, position.longitude);
        _mapUpdateController.add(
          MapUpdate(
            mapId: mapId,
            type: MapUpdateType.userLocationUpdated,
            userLocation: userLatLng,
            markers: _markers[mapId],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding user location: $e');
    }
  }

  /// Gets current user location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions are permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      return null;
    }
  }

  /// Calculates distance to a location
  Future<double?> getDistanceToLocation(
    trip_models.TripLocation location,
  ) async {
    try {
      final userPosition = await getCurrentLocation();
      if (userPosition == null) return null;

      return Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        location.latitude,
        location.longitude,
      );
    } catch (e) {
      debugPrint('❌ Error calculating distance: $e');
      return null;
    }
  }

  /// Search for nearby places (mock implementation)
  Future<List<trip_models.TripLocation>> searchNearbyPlaces(
    LatLng center,
    String query,
    double radiusMeters,
  ) async {
    // Mock implementation - in real app would use Google Places API
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      return [
        trip_models.TripLocation(
          id: 'nearby_1',
          name: 'Tourist Attraction',
          latitude: center.latitude + 0.001,
          longitude: center.longitude + 0.001,
          type: trip_models.TripLocationType.attraction,
          description: 'Popular tourist attraction nearby',
        ),
        trip_models.TripLocation(
          id: 'nearby_2',
          name: 'Local Restaurant',
          latitude: center.latitude - 0.001,
          longitude: center.longitude + 0.001,
          type: trip_models.TripLocationType.restaurant,
          description: 'Highly rated local restaurant',
        ),
      ];
    } catch (e) {
      debugPrint('❌ Error searching nearby places: $e');
      return [];
    }
  }

  /// Gets trip overview with statistics
  trip_models.TripOverview getTripOverview(
    List<trip_models.TripLocation> locations,
  ) {
    if (locations.isEmpty) {
      return trip_models.TripOverview.empty();
    }

    // Calculate total distance (approximate)
    double totalDistance = 0;
    for (int i = 0; i < locations.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        locations[i].latitude,
        locations[i].longitude,
        locations[i + 1].latitude,
        locations[i + 1].longitude,
      );
    }

    // Estimate duration (rough calculation)
    final estimatedDuration = Duration(
      minutes: (totalDistance / 1000 * 3).round(), // ~3 min per km
    );

    return trip_models.TripOverview(
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      locationCount: locations.length,
      orderedLocations: locations,
      bounds: locations.length > 1
          ? trip_models.LatLngBounds.fromLocations(locations)
          : null,
    );
  }

  /// Gets dark/light mode map style
  String? getMapStyle({bool isDarkMode = false}) {
    // Could return custom map styles for dark/light mode
    return null; // Use default style for now
  }

  /// Custom marker icons based on location type
  Future<BitmapDescriptor> _getMarkerIcon(
    trip_models.TripLocationType type,
  ) async {
    try {
      // For now, use default colored markers
      // In a real app, you'd load custom icon assets
      switch (type) {
        case trip_models.TripLocationType.hotel:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );

        case trip_models.TripLocationType.restaurant:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          );

        case trip_models.TripLocationType.attraction:
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        case trip_models.TripLocationType.transport:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );

        case trip_models.TripLocationType.activity:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          );

        case trip_models.TripLocationType.shopping:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueMagenta,
          );

        default:
          return BitmapDescriptor.defaultMarker;
      }
    } catch (e) {
      debugPrint('❌ Error creating marker icon: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Handles marker tap events
  void _onMarkerTapped(String mapId, trip_models.TripLocation location) {
    _mapUpdateController.add(
      MapUpdate(
        mapId: mapId,
        type: MapUpdateType.markerTapped,
        tappedLocation: location,
      ),
    );
  }

  /// Calculate bounds for a list of locations
  LatLngBounds _calculateBounds(List<trip_models.TripLocation> locations) {
    if (locations.isEmpty) {
      throw ArgumentError('Cannot calculate bounds for empty locations');
    }

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

    const padding = 0.01;
    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  /// Cleanup resources
  void dispose() {
    _mapUpdateController.close();
    _controllers.clear();
    _markers.clear();
    _polylines.clear();
    _userLocations.clear();
  }
}

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
