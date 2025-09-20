import 'dart:async';
import 'local_trips_repository.dart';
import 'trips_repository.dart';

/// Keeps local Hive and Firestore in sync for trips, supports offline-first.
class TripSyncService {
  TripSyncService._();
  static final TripSyncService instance = TripSyncService._();

  final _firestore = TripsRepository.instance;
  StreamSubscription? _firestoreSub;

  Future<void> start() async {
    // Listen to Firestore and update local
    _firestoreSub?.cancel();
    _firestoreSub = _firestore.watchTrips().listen((trips) async {
      for (final trip in trips) {
        await LocalTripsRepository.upsertTrip(trip);
      }
    });
    // Optionally: Listen to local and push to Firestore (conflict resolution needed)
  }

  Future<void> stop() async {
    await _firestoreSub?.cancel();
  }

  Future<void> syncToCloud() async {
    final localTrips = await LocalTripsRepository.listTrips();
    for (final trip in localTrips) {
      await _firestore.upsertTrip(trip);
    }
  }

  Future<void> syncFromCloud() async {
    final cloudTrips = await _firestore.listTrips();
    for (final trip in cloudTrips) {
      await LocalTripsRepository.upsertTrip(trip);
    }
  }
}
