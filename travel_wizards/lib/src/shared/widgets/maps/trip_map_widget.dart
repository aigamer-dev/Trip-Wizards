import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travel_wizards/src/shared/services/enhanced_map_service.dart';
import 'package:travel_wizards/src/shared/models/trip_location.dart'
    as trip_models;
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

/// Enhanced map widget for trip visualization and planning
class TripMapWidget extends StatefulWidget {
  final String tripId;
  final List<trip_models.TripLocation> locations;
  final bool showUserLocation;
  final bool showRoute;
  final bool isInteractive;
  final double height;
  final void Function(trip_models.TripLocation)? onLocationTapped;
  final void Function(LatLng)? onMapTapped;

  const TripMapWidget({
    super.key,
    required this.tripId,
    required this.locations,
    this.showUserLocation = true,
    this.showRoute = true,
    this.isInteractive = true,
    this.height = 300,
    this.onLocationTapped,
    this.onMapTapped,
  });

  @override
  State<TripMapWidget> createState() => _TripMapWidgetState();
}

class _TripMapWidgetState extends State<TripMapWidget> {
  final EnhancedMapService _mapService = EnhancedMapService.instance;
  GoogleMapController? _controller;

  // Map state
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;

  // Default camera position
  static const LatLng _defaultPosition = LatLng(28.6139, 77.2090); // New Delhi

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _listenToMapUpdates();
  }

  Future<void> _initializeMap() async {
    try {
      // Add user location if requested
      if (widget.showUserLocation) {
        await _mapService.addUserLocation(widget.tripId);
      }

      // Add trip locations
      if (widget.locations.isNotEmpty) {
        await _mapService.addMarkers(widget.tripId, widget.locations);

        // Add route if requested
        if (widget.showRoute && widget.locations.length > 1) {
          await _mapService.addRoute(widget.tripId, widget.locations);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error initializing map: $e');
      setState(() => _isLoading = false);
    }
  }

  void _listenToMapUpdates() {
    _mapService.mapUpdateStream.listen((update) {
      if (update.mapId == widget.tripId && mounted) {
        setState(() {
          if (update.markers != null) {
            _markers.clear();
            _markers.addAll(update.markers!);
          }

          if (update.polylines != null) {
            _polylines.clear();
            _polylines.addAll(update.polylines!);
          }
        });

        // Handle marker taps
        if (update.type == MapUpdateType.markerTapped &&
            update.tappedLocation != null &&
            widget.onLocationTapped != null) {
          widget.onLocationTapped!(update.tappedLocation!);
        }
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    await _mapService.initializeController(widget.tripId, controller);

    // Center map on locations if available
    if (widget.locations.isNotEmpty) {
      await _mapService.centerOnLocations(widget.tripId, widget.locations);
    }
  }

  LatLng _getInitialPosition() {
    if (widget.locations.isNotEmpty) {
      final first = widget.locations.first;
      return LatLng(first.latitude, first.longitude);
    }
    return _defaultPosition;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _getInitialPosition(),
                zoom: 12.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: widget.showUserLocation,
              myLocationButtonEnabled: widget.isInteractive,
              zoomControlsEnabled: false,
              compassEnabled: widget.isInteractive,
              mapToolbarEnabled: false,
              onTap: widget.onMapTapped,
              style: _mapService.getMapStyle(
                isDarkMode: theme.brightness == Brightness.dark,
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: theme.colorScheme.surface.withAlpha(204),
                child: const Center(child: CircularProgressIndicator()),
              ),

            // Map controls overlay
            if (widget.isInteractive) ...[
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  children: [
                    _buildMapControl(
                      icon: Icons.my_location,
                      onTap: _centerOnUserLocation,
                      tooltip: 'My Location',
                    ),
                    const SizedBox(height: 8),
                    _buildMapControl(
                      icon: Icons.map,
                      onTap: _centerOnTrip,
                      tooltip: 'View Trip',
                    ),
                  ],
                ),
              ),
            ],

            // Trip overview info
            if (widget.locations.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: _buildTripOverviewCard(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildTripOverviewCard() {
    final overview = _mapService.getTripOverview(widget.locations);

    return Container(
      padding: Insets.allSm,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(242),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.locations.length} stops',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          if (overview.totalDistance > 0) ...[
            const SizedBox(width: 12),
            Icon(
              Icons.straighten,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDistance(overview.totalDistance),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
          if (overview.estimatedDuration.inMinutes > 0) ...[
            const SizedBox(width: 12),
            Icon(
              Icons.access_time,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(overview.estimatedDuration),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  // Action methods
  Future<void> _centerOnUserLocation() async {
    if (_controller == null) return;

    final location = await _mapService.getCurrentLocation();
    if (location != null) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          15.0,
        ),
      );
    }
  }

  Future<void> _centerOnTrip() async {
    if (_controller == null || widget.locations.isEmpty) return;

    await _mapService.centerOnLocations(widget.tripId, widget.locations);
  }

  // Helper methods
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Compact map widget for cards and list items
class CompactTripMapWidget extends StatelessWidget {
  final List<trip_models.TripLocation> locations;
  final double height;
  final VoidCallback? onTap;

  const CompactTripMapWidget({
    super.key,
    required this.locations,
    this.height = 120,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 32,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 4),
              Text(
                'No locations',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final center = locations.length == 1
        ? LatLng(locations.first.latitude, locations.first.longitude)
        : LatLng(
            locations.map((l) => l.latitude).reduce((a, b) => a + b) /
                locations.length,
            locations.map((l) => l.longitude).reduce((a, b) => a + b) /
                locations.length,
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: center,
                  zoom: 10.0,
                ),
                markers: locations
                    .map(
                      (location) => Marker(
                        markerId: MarkerId(location.id),
                        position: LatLng(location.latitude, location.longitude),
                      ),
                    )
                    .toSet(),
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
              ),

              // Overlay to prevent interaction
              if (onTap != null)
                Positioned.fill(child: Container(color: Colors.transparent)),

              // Location count badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${locations.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
