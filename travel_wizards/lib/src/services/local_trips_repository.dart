import 'package:hive/hive.dart';
import '../models/trip.dart';

class LocalTripsRepository {
  static const _boxName = 'trips';
  static Future<Box> _box() async => await Hive.openBox(_boxName);

  static Future<List<Trip>> listTrips() async {
    final box = await _box();
    return box.values
        .map((e) => Trip.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Stream<List<Trip>> watchTrips() async* {
    final box = await _box();
    yield box.values
        .map((e) => Trip.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    await for (final _ in box.watch()) {
      yield box.values
          .map((e) => Trip.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  static Future<void> upsertTrip(Trip trip) async {
    final box = await _box();
    await box.put(trip.id, trip.toMap());
  }

  static Future<void> deleteTrip(String id) async {
    final box = await _box();
    await box.delete(id);
  }

  static Future<void> clear() async {
    final box = await _box();
    await box.clear();
  }
}
