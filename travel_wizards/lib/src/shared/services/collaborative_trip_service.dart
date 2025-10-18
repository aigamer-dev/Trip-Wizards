import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:travel_wizards/src/shared/models/collaborative_trip.dart';
import 'package:travel_wizards/src/shared/models/user.dart';

/// Service for managing collaborative trips with real-time updates
class CollaborativeTripService {
  static CollaborativeTripService? _instance;

  static CollaborativeTripService get instance {
    _instance ??= CollaborativeTripService._();
    return _instance!;
  }

  CollaborativeTripService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current authenticated user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Collection references
  CollectionReference get _tripsCollection =>
      _firestore.collection('collaborative_trips');
  CollectionReference get _invitationsCollection =>
      _firestore.collection('trip_invitations');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Create a new collaborative trip
  Future<CollaborativeTrip> createTrip({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> destinations,
    String? notes,
    TripPermissions? permissions,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User must be logged in to create trips');
    }

    final now = DateTime.now();
    final tripId = _tripsCollection.doc().id;

    final trip = CollaborativeTrip(
      id: tripId,
      title: title,
      startDate: startDate,
      endDate: endDate,
      destinations: destinations,
      notes: notes,
      ownerId: currentUserId,
      permissions: permissions ?? TripPermissions.defaultPermissions,
      createdAt: now,
      updatedAt: now,
      lastUpdatedBy: currentUserId,
    );

    await _tripsCollection.doc(tripId).set(trip.toMap());
    return trip;
  }

  /// Get trips where current user has access
  Stream<List<CollaborativeTrip>> getUserTrips() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _tripsCollection
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<CollaborativeTrip> trips = [];

          // Get trips where user is owner
          final ownerQuery = await _tripsCollection
              .where('ownerId', isEqualTo: currentUserId)
              .get();

          for (final doc in ownerQuery.docs) {
            trips.add(CollaborativeTrip.fromFirestore(doc));
          }

          // Get trips where user is member
          for (final doc in snapshot.docs) {
            final trip = CollaborativeTrip.fromFirestore(doc);
            if (!trips.any((t) => t.id == trip.id)) {
              trips.add(trip);
            }
          }

          return trips..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        });
  }

  /// Get a specific trip by ID
  Future<CollaborativeTrip?> getTrip(String tripId) async {
    try {
      final doc = await _tripsCollection.doc(tripId).get();
      if (!doc.exists) return null;

      final trip = CollaborativeTrip.fromFirestore(doc);

      // Check if current user has access
      final currentUserId = _currentUserId;
      if (currentUserId != null && trip.hasAccess(currentUserId)) {
        return trip;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting trip: $e');
      return null;
    }
  }

  /// Get real-time trip updates
  Stream<CollaborativeTrip?> getTripStream(String tripId) {
    return _tripsCollection.doc(tripId).snapshots().map((doc) {
      if (!doc.exists) return null;

      final trip = CollaborativeTrip.fromFirestore(doc);
      final currentUserId = _currentUserId;

      if (currentUserId != null && trip.hasAccess(currentUserId)) {
        return trip;
      }

      return null;
    });
  }

  /// Update trip details
  Future<void> updateTrip(
    String tripId, {
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? destinations,
    String? notes,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User must be logged in to update trips');
    }

    final trip = await getTrip(tripId);
    if (trip == null) {
      throw Exception('Trip not found or access denied');
    }

    if (!trip.canEdit(currentUserId)) {
      throw Exception('User does not have edit permissions');
    }

    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
      'lastUpdatedBy': currentUserId,
    };

    if (title != null) updates['title'] = title;
    if (startDate != null) updates['startDate'] = startDate.toIso8601String();
    if (endDate != null) updates['endDate'] = endDate.toIso8601String();
    if (destinations != null) updates['destinations'] = destinations;
    if (notes != null) updates['notes'] = notes;

    await _tripsCollection.doc(tripId).update(updates);
  }

  /// Invite user to trip
  Future<TripInvitation> inviteUser({
    required String tripId,
    required String inviteeEmail,
    required TripRole role,
    String? message,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User must be logged in to send invitations');
    }

    final trip = await getTrip(tripId);
    if (trip == null) {
      throw Exception('Trip not found or access denied');
    }

    if (!trip.canInvite(currentUserId)) {
      throw Exception('User does not have invite permissions');
    }

    // Check if user is already a member
    if (trip.members.any((m) => m.email == inviteeEmail)) {
      throw Exception('User is already a member of this trip');
    }

    // Check if there's already a pending invitation
    final existingInvitations = await _invitationsCollection
        .where('tripId', isEqualTo: tripId)
        .where('inviteeEmail', isEqualTo: inviteeEmail)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .get();

    if (existingInvitations.docs.isNotEmpty) {
      throw Exception('User already has a pending invitation');
    }

    final invitationId = _invitationsCollection.doc().id;
    final invitation = TripInvitation(
      id: invitationId,
      tripId: tripId,
      inviterUserId: currentUserId,
      inviteeEmail: inviteeEmail,
      proposedRole: role,
      status: InvitationStatus.pending,
      createdAt: DateTime.now(),
      message: message,
    );

    await _invitationsCollection.doc(invitationId).set(invitation.toMap());

    // Update trip's invitations list
    await _tripsCollection.doc(tripId).update({
      'invitations': FieldValue.arrayUnion([invitation.toMap()]),
      'updatedAt': DateTime.now().toIso8601String(),
      'lastUpdatedBy': currentUserId,
    });

    return invitation;
  }

  /// Get invitations for current user
  Stream<List<TripInvitation>> getUserInvitations() {
    final currentUser = _auth.currentUser;
    if (currentUser?.email == null) {
      return Stream.value([]);
    }

    return _invitationsCollection
        .where('inviteeEmail', isEqualTo: currentUser!.email)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => TripInvitation.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }),
              )
              .where((invitation) => !invitation.isExpired)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
  }

  /// Accept trip invitation
  Future<void> acceptInvitation(String invitationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to accept invitations');
    }

    final invitationDoc = await _invitationsCollection.doc(invitationId).get();
    if (!invitationDoc.exists) {
      throw Exception('Invitation not found');
    }

    final invitation = TripInvitation.fromMap({
      ...invitationDoc.data() as Map<String, dynamic>,
      'id': invitationDoc.id,
    });

    if (invitation.inviteeEmail != currentUser.email) {
      throw Exception('Invalid invitation');
    }

    if (invitation.status != InvitationStatus.pending) {
      throw Exception('Invitation is no longer valid');
    }

    final member = TripMember(
      userId: currentUser.uid,
      email: currentUser.email!,
      displayName: currentUser.displayName,
      photoUrl: currentUser.photoURL,
      role: invitation.proposedRole,
      joinedAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    // Update invitation status
    batch.update(invitationDoc.reference, {
      'status': InvitationStatus.accepted.name,
      'respondedAt': DateTime.now().toIso8601String(),
    });

    // Add member to trip
    final tripRef = _tripsCollection.doc(invitation.tripId);
    batch.update(tripRef, {
      'members': FieldValue.arrayUnion([member.toMap()]),
      'updatedAt': DateTime.now().toIso8601String(),
      'lastUpdatedBy': currentUser.uid,
    });

    await batch.commit();
  }

  /// Decline trip invitation
  Future<void> declineInvitation(String invitationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to decline invitations');
    }

    final invitationDoc = await _invitationsCollection.doc(invitationId).get();
    if (!invitationDoc.exists) {
      throw Exception('Invitation not found');
    }

    final invitation = TripInvitation.fromMap({
      ...invitationDoc.data() as Map<String, dynamic>,
      'id': invitationDoc.id,
    });

    if (invitation.inviteeEmail != currentUser.email) {
      throw Exception('Invalid invitation');
    }

    await invitationDoc.reference.update({
      'status': InvitationStatus.declined.name,
      'respondedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Remove member from trip
  Future<void> removeMember(String tripId, String memberUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User must be logged in to remove members');
    }

    final trip = await getTrip(tripId);
    if (trip == null) {
      throw Exception('Trip not found or access denied');
    }

    // Only owner or admin can remove members
    if (!trip.isOwner(currentUserId)) {
      final currentMember = trip.getMember(currentUserId);
      if (currentMember?.role != TripRole.admin) {
        throw Exception('Insufficient permissions to remove members');
      }
    }

    // Cannot remove owner
    if (trip.ownerId == memberUserId) {
      throw Exception('Cannot remove trip owner');
    }

    final memberToRemove = trip.getMember(memberUserId);
    if (memberToRemove == null) {
      throw Exception('Member not found');
    }

    await _tripsCollection.doc(tripId).update({
      'members': FieldValue.arrayRemove([memberToRemove.toMap()]),
      'updatedAt': DateTime.now().toIso8601String(),
      'lastUpdatedBy': currentUserId,
    });
  }

  /// Update member role
  Future<void> updateMemberRole(
    String tripId,
    String memberUserId,
    TripRole newRole,
  ) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User must be logged in to update member roles');
    }

    final trip = await getTrip(tripId);
    if (trip == null) {
      throw Exception('Trip not found or access denied');
    }

    // Only owner can update roles
    if (!trip.isOwner(currentUserId)) {
      throw Exception('Only trip owner can update member roles');
    }

    final memberToUpdate = trip.getMember(memberUserId);
    if (memberToUpdate == null) {
      throw Exception('Member not found');
    }

    final updatedMember = memberToUpdate.copyWith(role: newRole);
    final updatedMembers = trip.members.map((m) {
      return m.userId == memberUserId ? updatedMember : m;
    }).toList();

    await _tripsCollection.doc(tripId).update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
      'lastUpdatedBy': currentUserId,
    });
  }

  /// Delete trip (owner only)
  Future<void> deleteTrip(String tripId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User must be logged in to delete trips');
    }

    final trip = await getTrip(tripId);
    if (trip == null) {
      throw Exception('Trip not found or access denied');
    }

    if (!trip.isOwner(currentUserId)) {
      throw Exception('Only trip owner can delete trips');
    }

    final batch = _firestore.batch();

    // Delete trip
    batch.delete(_tripsCollection.doc(tripId));

    // Delete all related invitations
    final invitations = await _invitationsCollection
        .where('tripId', isEqualTo: tripId)
        .get();

    for (final doc in invitations.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Update trip permissions (owner only)
  Future<void> updateTripPermissions(
    String tripId,
    TripPermissions newPermissions,
  ) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User must be logged in to update permissions');
    }

    final trip = await getTrip(tripId);
    if (trip == null) {
      throw Exception('Trip not found or access denied');
    }

    if (!trip.isOwner(currentUserId)) {
      throw Exception('Only trip owner can update permissions');
    }

    await _tripsCollection.doc(tripId).update({
      'permissions': newPermissions.toMap(),
      'updatedAt': DateTime.now().toIso8601String(),
      'lastUpdatedBy': currentUserId,
    });
  }

  /// Leave trip (members only)
  Future<void> leaveTrip(String tripId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User must be logged in to leave trips');
    }

    final trip = await getTrip(tripId);
    if (trip == null) {
      throw Exception('Trip not found or access denied');
    }

    if (trip.isOwner(currentUserId)) {
      throw Exception(
        'Trip owner cannot leave trip. Transfer ownership or delete trip instead.',
      );
    }

    await removeMember(tripId, currentUserId);
  }

  /// Respond to a trip invitation
  Future<void> respondToInvitation(
    String tripId,
    String invitationId,
    bool accept,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();
    final tripRef = _firestore.collection('collaborative_trips').doc(tripId);

    try {
      final trip = await getTrip(tripId);
      if (trip == null) throw Exception('Trip not found');

      final invitation = trip.invitations.firstWhere(
        (inv) => inv.id == invitationId,
        orElse: () => throw Exception('Invitation not found'),
      );

      if (!invitation.isPending) {
        throw Exception('Invitation already responded to');
      }

      // Update invitation status
      final updatedInvitations = trip.invitations.map((inv) {
        if (inv.id == invitationId) {
          return inv.copyWith(
            status: accept
                ? InvitationStatus.accepted
                : InvitationStatus.declined,
            respondedAt: DateTime.now(),
          );
        }
        return inv;
      }).toList();

      // If accepted, add user as member
      List<TripMember> updatedMembers = [...trip.members];
      if (accept) {
        final user = _auth.currentUser!;
        updatedMembers.add(
          TripMember(
            userId: userId,
            email: user.email ?? invitation.inviteeEmail,
            displayName: user.displayName,
            photoUrl: user.photoURL,
            role: invitation.proposedRole,
            joinedAt: DateTime.now(),
          ),
        );
      }

      // Update trip
      batch.update(tripRef, {
        'invitations': updatedInvitations.map((inv) => inv.toMap()).toList(),
        'members': updatedMembers.map((member) => member.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastUpdatedBy': userId,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to respond to invitation: $e');
    }
  }

  /// Search users for invitation (by email)
  Future<AppUser?> searchUserByEmail(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return AppUser.fromMap({
          ...querySnapshot.docs.first.data() as Map<String, dynamic>,
          'uid': querySnapshot.docs.first.id,
        });
      }

      return null;
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }
}
