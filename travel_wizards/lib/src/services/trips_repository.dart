import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_wizards/src/models/trip.dart';

class TripsRepository {
  TripsRepository._();
  static final TripsRepository instance = TripsRepository._();

  CollectionReference<Map<String, dynamic>> _userTripsCollection(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips');
  }

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to access trips');
    }
    return user.uid;
  }

  Future<List<Trip>> listTrips() async {
    final snapshot = await _userTripsCollection(
      _uid,
    ).orderBy('startDate').get();
    return snapshot.docs.map((d) => Trip.fromMap(d.data())).toList();
  }

  Stream<List<Trip>> watchTrips() {
    return _userTripsCollection(_uid)
        .orderBy('startDate')
        .snapshots()
        .map((s) => s.docs.map((d) => Trip.fromMap(d.data())).toList());
  }

  Future<void> upsertTrip(Trip trip) async {
    await _userTripsCollection(_uid).doc(trip.id).set(trip.toMap());
  }

  Future<void> deleteTrip(String id) async {
    await _userTripsCollection(_uid).doc(id).delete();
  }

  Future<void> addDestinations(String id, List<String> destinations) async {
    if (destinations.isEmpty) return;
    await _userTripsCollection(_uid).doc(id).set({
      'destinations': FieldValue.arrayUnion(destinations),
    }, SetOptions(merge: true));
  }

  Future<void> updateMeta(
    String id, {
    DateTime? start,
    DateTime? end,
    String? title,
    String? notes,
  }) async {
    final Map<String, dynamic> data = {};
    if (start != null) data['startDate'] = start.toIso8601String();
    if (end != null) data['endDate'] = end.toIso8601String();
    if (title != null) data['title'] = title;
    if (notes != null) data['notes'] = notes;
    if (data.isEmpty) return;
    await _userTripsCollection(_uid).doc(id).set(data, SetOptions(merge: true));
  }
}
