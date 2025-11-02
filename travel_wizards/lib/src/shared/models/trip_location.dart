import 'dart:math' as math;

/// Trip location model for enhanced map integration
class TripLocation {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final TripLocationType type;
  final String? address;
  final DateTime? visitTime;
  final Duration? estimatedStayDuration;
  final Map<String, dynamic>? metadata;

  const TripLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.description,
    this.address,
    this.visitTime,
    this.estimatedStayDuration,
    this.metadata,
  });

  factory TripLocation.fromJson(Map<String, dynamic> json) {
    return TripLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: TripLocationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TripLocationType.attraction,
      ),
      description: json['description'] as String?,
      address: json['address'] as String?,
      visitTime: json['visitTime'] != null
          ? DateTime.parse(json['visitTime'] as String)
          : null,
      estimatedStayDuration: json['estimatedStayDuration'] != null
          ? Duration(minutes: json['estimatedStayDuration'] as int)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      if (description != null) 'description': description,
      if (address != null) 'address': address,
      if (visitTime != null) 'visitTime': visitTime!.toIso8601String(),
      if (estimatedStayDuration != null)
        'estimatedStayDuration': estimatedStayDuration!.inMinutes,
      if (metadata != null) 'metadata': metadata,
    };
  }

  TripLocation copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    TripLocationType? type,
    String? address,
    DateTime? visitTime,
    Duration? estimatedStayDuration,
    Map<String, dynamic>? metadata,
  }) {
    return TripLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      address: address ?? this.address,
      visitTime: visitTime ?? this.visitTime,
      estimatedStayDuration:
          estimatedStayDuration ?? this.estimatedStayDuration,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripLocation &&
        other.id == id &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, latitude, longitude, type);
  }

  @override
  String toString() {
    return 'TripLocation(id: $id, name: $name, lat: $latitude, lng: $longitude, type: $type)';
  }
}

/// Types of trip locations for proper categorization and visualization
enum TripLocationType {
  attraction('Attraction', 'attraction'),
  restaurant('Restaurant', 'restaurant'),
  hotel('Hotel', 'lodging'),
  transport('Transport', 'transit_station'),
  shopping('Shopping', 'shopping_mall'),
  activity('Activity', 'local_activity'),
  viewpoint('Viewpoint', 'landscape'),
  museum('Museum', 'museum'),
  park('Park', 'park'),
  beach('Beach', 'beach_access'),
  mountain('Mountain', 'terrain'),
  city('City', 'location_city'),
  custom('Custom', 'place');

  const TripLocationType(this.displayName, this.googlePlaceType);

  final String displayName;
  final String googlePlaceType;

  /// Get icon data for the location type
  String get iconName {
    switch (this) {
      case TripLocationType.attraction:
        return 'star';
      case TripLocationType.restaurant:
        return 'restaurant';
      case TripLocationType.hotel:
        return 'hotel';
      case TripLocationType.transport:
        return 'directions_transit';
      case TripLocationType.shopping:
        return 'shopping_bag';
      case TripLocationType.activity:
        return 'local_activity';
      case TripLocationType.viewpoint:
        return 'landscape';
      case TripLocationType.museum:
        return 'museum';
      case TripLocationType.park:
        return 'park';
      case TripLocationType.beach:
        return 'beach_access';
      case TripLocationType.mountain:
        return 'terrain';
      case TripLocationType.city:
        return 'location_city';
      case TripLocationType.custom:
        return 'place';
    }
  }

  /// Get marker color for the location type
  String get markerColor {
    switch (this) {
      case TripLocationType.attraction:
        return 'red';
      case TripLocationType.restaurant:
        return 'orange';
      case TripLocationType.hotel:
        return 'blue';
      case TripLocationType.transport:
        return 'green';
      case TripLocationType.shopping:
        return 'purple';
      case TripLocationType.activity:
        return 'yellow';
      case TripLocationType.viewpoint:
        return 'pink';
      case TripLocationType.museum:
        return 'brown';
      case TripLocationType.park:
        return 'green';
      case TripLocationType.beach:
        return 'cyan';
      case TripLocationType.mountain:
        return 'grey';
      case TripLocationType.city:
        return 'black';
      case TripLocationType.custom:
        return 'violet';
    }
  }
}

/// Trip overview data for route visualization
class TripOverview {
  final double totalDistance; // in meters
  final Duration estimatedDuration;
  final int locationCount;
  final LatLngBounds? bounds;
  final List<TripLocation> orderedLocations;

  const TripOverview({
    required this.totalDistance,
    required this.estimatedDuration,
    required this.locationCount,
    required this.orderedLocations,
    this.bounds,
  });

  factory TripOverview.empty() {
    return const TripOverview(
      totalDistance: 0,
      estimatedDuration: Duration.zero,
      locationCount: 0,
      orderedLocations: [],
    );
  }
}

/// Map bounds for trip visualization
class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;

  const LatLngBounds({required this.southwest, required this.northeast});

  factory LatLngBounds.fromLocations(List<TripLocation> locations) {
    if (locations.isEmpty) {
      throw ArgumentError('Cannot create bounds from empty location list');
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

    // Add some padding
    const padding = 0.01;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
        point.latitude <= northeast.latitude &&
        point.longitude >= southwest.longitude &&
        point.longitude <= northeast.longitude;
  }
}

/// Simple LatLng class for coordinates
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  factory LatLng.fromJson(Map<String, dynamic> json) {
    return LatLng(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );
  }
}
