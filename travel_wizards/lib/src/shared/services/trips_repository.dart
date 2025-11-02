import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_wizards/src/shared/models/trip.dart';

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

  /// Watch only private trips (owned by current user, not shared)
  Stream<List<Trip>> watchMyPrivateTrips() {
    return _userTripsCollection(_uid)
        .where('visibility', isEqualTo: 'private')
        .orderBy('startDate')
        .snapshots()
        .map((s) => s.docs.map((d) => Trip.fromMap(d.data())).toList());
  }

  /// Watch trips shared with current user
  /// Note: This is a simplified version. Full implementation would require
  /// querying other users' trips where sharedWith array contains current user
  Stream<List<Trip>> watchSharedTrips() {
    return _userTripsCollection(_uid)
        .where('sharedWith', arrayContains: _uid)
        .orderBy('startDate')
        .snapshots()
        .map((s) => s.docs.map((d) => Trip.fromMap(d.data())).toList());
  }

  /// Watch community trips (public trips from all users)
  /// Note: This requires a collection group query across all users
  Stream<List<Trip>> watchCommunityTrips() {
    return FirebaseFirestore.instance
        .collectionGroup('trips')
        .where('isPublic', isEqualTo: true)
        .where('visibility', isEqualTo: 'community')
        .orderBy('startDate', descending: true)
        .limit(50) // Limit to prevent excessive data
        .snapshots()
        .map((s) => s.docs.map((d) => Trip.fromMap(d.data())).toList());
  }

  /// Watch trips accessible to current user (owned + shared)
  Stream<List<Trip>> watchAccessibleTrips() {
    // This combines trips owned by user and trips shared with user
    // For simplicity, we'll just return owned trips
    // A full implementation would merge both streams
    return watchTrips();
  }

  Future<void> upsertTrip(Trip trip) async {
    await _userTripsCollection(_uid).doc(trip.id).set(trip.toMap());
  }

  /// Update trip visibility
  Future<void> updateTripVisibility({
    required String tripId,
    required String visibility,
    required bool isPublic,
    List<String>? sharedWith,
  }) async {
    final Map<String, dynamic> data = {
      'visibility': visibility,
      'isPublic': isPublic,
    };
    if (sharedWith != null) {
      data['sharedWith'] = sharedWith;
    }
    await _userTripsCollection(
      _uid,
    ).doc(tripId).set(data, SetOptions(merge: true));
  }

  /// Publish trip to community
  Future<void> publishToCommunity(String tripId) async {
    await updateTripVisibility(
      tripId: tripId,
      visibility: 'community',
      isPublic: true,
    );
  }

  /// Make trip private
  Future<void> makePrivate(String tripId) async {
    await updateTripVisibility(
      tripId: tripId,
      visibility: 'private',
      isPublic: false,
      sharedWith: [],
    );
  }

  /// Share trip with specific users
  Future<void> shareWith(String tripId, List<String> userIds) async {
    await updateTripVisibility(
      tripId: tripId,
      visibility: 'shared',
      isPublic: false,
      sharedWith: userIds,
    );
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
