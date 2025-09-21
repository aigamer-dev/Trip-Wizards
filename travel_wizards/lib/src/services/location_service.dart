import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> checkPermission() async {
    if (kIsWeb) return true; // Browser will prompt via Geolocator APIs
    final status = await Permission.location.status;
    return status.isGranted;
  }

  static Future<Position?> getCurrentLocation() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition();
  }

  static Stream<Position> watchLocation() async* {
    final hasPermission = await checkPermission();
    if (!hasPermission) return;
    yield* Geolocator.getPositionStream();
  }
}
