import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';
import 'error_handling_service.dart';

/// Data Portability Service for user data export and deletion (GDPR compliance)
class DataPortabilityService {
  static final DataPortabilityService instance = DataPortabilityService._();
  DataPortabilityService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  /// Export all user data as a JSON string
  Future<String> exportUserData({required String uid}) async {
    final userData = <String, dynamic>{};

    // Export profile
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      userData['profile'] = userDoc.data();
    }

    // Export personal trips
    final personalTrips = await _firestore
        .collection('users')
        .doc(uid)
        .collection('trips')
        .get();
    userData['trips'] = personalTrips.docs.map((d) => d.data()).toList();

    // Export collaborative trips where user is member/owner
    final collaborativeTrips = await _firestore
        .collection('collaborative_trips')
        .where('members', arrayContains: uid)
        .get();
    userData['collaborative_trips'] = collaborativeTrips.docs
        .map((d) => d.data())
        .toList();

    // Export trip invitations
    final invitations = await _firestore
        .collection('trip_invitations')
        .where('inviteeEmail', isEqualTo: userDoc.data()?['email'] ?? '')
        .get();
    userData['trip_invitations'] = invitations.docs
        .map((d) => d.data())
        .toList();

    // Export preferences
    final prefs = await _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .get();
    userData['preferences'] = prefs.docs.map((d) => d.data()).toList();

    // Export notifications
    final notifs = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .get();
    userData['notifications'] = notifs.docs.map((d) => d.data()).toList();

    // Export receipts (metadata only)
    final receipts = await _firestore
        .collection('users')
        .doc(uid)
        .collection('receipts')
        .get();
    userData['receipts'] = receipts.docs.map((d) => d.data()).toList();

    // Export local Hive data (if any)
    if (Hive.isBoxOpen('user_$uid')) {
      userData['local_cache'] = Hive.box('user_$uid').toMap();
    }

    // Export FCM tokens
    final tokens = await _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .get();
    userData['fcmTokens'] = tokens.docs.map((d) => d.data()).toList();

    // Export social features
    final buddies = await _firestore
        .collection('users')
        .doc(uid)
        .collection('buddies')
        .get();
    userData['buddies'] = buddies.docs.map((d) => d.data()).toList();

    // Export bookings
    final bookings = await _firestore
        .collection('users')
        .doc(uid)
        .collection('bookings')
        .get();
    userData['bookings'] = bookings.docs.map((d) => d.data()).toList();

    // Export emergency incidents
    final incidents = await _firestore
        .collection('users')
        .doc(uid)
        .collection('emergencyIncidents')
        .get();
    userData['emergencyIncidents'] = incidents.docs
        .map((d) => d.data())
        .toList();

    // Export settings
    final settings = await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .get();
    userData['settings'] = settings.docs.map((d) => d.data()).toList();

    return jsonEncode(userData);
  }

  /// Delete all user data (Firestore, Storage, local cache)
  Future<void> deleteUserData({required String uid}) async {
    // Delete all subcollections under user profile
    final userRef = _firestore.collection('users').doc(uid);
    final collections = [
      'trips',
      'preferences',
      'notifications',
      'receipts',
      'fcmTokens',
      'buddies',
      'bookings',
      'emergencyIncidents',
      'settings',
    ];
    for (final col in collections) {
      final snap = await userRef.collection(col).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }
    // Delete user profile
    await userRef.delete();

    // Delete collaborative trips where user is owner
    final ownedTrips = await _firestore
        .collection('collaborative_trips')
        .where('ownerId', isEqualTo: uid)
        .get();
    for (final doc in ownedTrips.docs) {
      await doc.reference.delete();
    }

    // Remove user from collaborative trips where they're a member
    final memberTrips = await _firestore
        .collection('collaborative_trips')
        .where('members', arrayContains: uid)
        .get();
    for (final doc in memberTrips.docs) {
      final data = doc.data();
      final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      members.removeWhere((m) => m['userId'] == uid);
      await doc.reference.update({'members': members});
    }

    // Delete trip invitations for this user
    final userEmail = (await _firestore.collection('users').doc(uid).get())
        .data()?['email'];
    if (userEmail != null) {
      final invitations = await _firestore
          .collection('trip_invitations')
          .where('inviteeEmail', isEqualTo: userEmail)
          .get();
      for (final doc in invitations.docs) {
        await doc.reference.delete();
      }
    }

    // Delete receipts from Storage
    final storageRef = _storage.ref().child('users/$uid/receipts');
    try {
      final items = await storageRef.listAll();
      for (final item in items.items) {
        await item.delete();
      }
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'DataPortabilityService: Delete user receipts from storage',
        showToUser: false,
      );
    }

    // Delete local Hive cache
    if (Hive.isBoxOpen('user_$uid')) {
      await Hive.box('user_$uid').clear();
    }

    // Log deletion event (for audit trail)
    await _firestore.collection('deletion_audit').add({
      'uid': uid,
      'deletedAt': DateTime.now().toIso8601String(),
      'by': _auth.currentUser?.uid,
    });
  }
}
