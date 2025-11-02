import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const CameraPosition _initial = CameraPosition(
    target: LatLng(28.6139, 77.2090), // New Delhi
    zoom: 10,
  );

  @override
  Widget build(BuildContext context) {
    return ModernPageScaffold(
      pageTitle: 'Map',
      body: GoogleMap(
        initialCameraPosition: _initial,
        onMapCreated: (c) {},
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: true,
      ),
    );
  }
}
