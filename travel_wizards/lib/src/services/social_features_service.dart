// Enhanced Social Features Service for Travel Wizards
// Provides comprehensive social interaction capabilities beyond basic collaboration
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/social_models.dart';

class SocialFeaturesService extends ChangeNotifier {
  static final SocialFeaturesService _instance =
      SocialFeaturesService._internal();
  factory SocialFeaturesService() => _instance;
  SocialFeaturesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Trip Comments and Discussions
  Future<void> addTripComment({
    required String tripId,
    required String content,
    String? parentCommentId,
    List<String>? mentionedUserIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final comment = TripComment(
      id: _firestore
          .collection('trips')
          .doc(tripId)
          .collection('comments')
          .doc()
          .id,
      tripId: tripId,
      authorId: user.uid,
      authorName: user.displayName ?? 'Anonymous',
      authorPhotoUrl: user.photoURL,
      content: content,
      parentCommentId: parentCommentId,
      mentionedUserIds: mentionedUserIds ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('comments')
        .doc(comment.id)
        .set(comment.toJson());

    // Notify mentioned users
    if (mentionedUserIds != null && mentionedUserIds.isNotEmpty) {
      await _sendMentionNotifications(tripId, comment, mentionedUserIds);
    }

    notifyListeners();
  }

  Stream<List<TripComment>> getTripComments(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TripComment.fromJson(doc.data()))
              .toList(),
        );
  }

  // Trip Reactions (like, love, thumbs up, etc.)
  Future<void> addTripReaction({
    required String tripId,
    required TripReactionType reactionType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final reaction = TripReaction(
      id: '${user.uid}_$tripId',
      tripId: tripId,
      userId: user.uid,
      userName: user.displayName ?? 'Anonymous',
      userPhotoUrl: user.photoURL,
      reactionType: reactionType,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('reactions')
        .doc(reaction.id)
        .set(reaction.toJson());

    notifyListeners();
  }

  Future<void> removeTripReaction({required String tripId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('reactions')
        .doc('${user.uid}_$tripId')
        .delete();

    notifyListeners();
  }

  Stream<Map<TripReactionType, List<TripReaction>>> getTripReactions(
    String tripId,
  ) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('reactions')
        .snapshots()
        .map((snapshot) {
          final reactions = snapshot.docs
              .map((doc) => TripReaction.fromJson(doc.data()))
              .toList();

          final groupedReactions = <TripReactionType, List<TripReaction>>{};
          for (final reaction in reactions) {
            groupedReactions
                .putIfAbsent(reaction.reactionType, () => [])
                .add(reaction);
          }

          return groupedReactions;
        });
  }

  // Activity Feed
  Future<void> createActivityFeedItem({
    required String tripId,
    required ActivityType activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final activity = ActivityFeedItem(
      id: _firestore
          .collection('trips')
          .doc(tripId)
          .collection('activity')
          .doc()
          .id,
      tripId: tripId,
      userId: user.uid,
      userName: user.displayName ?? 'Anonymous',
      userPhotoUrl: user.photoURL,
      activityType: activityType,
      description: description,
      metadata: metadata ?? {},
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('activity')
        .doc(activity.id)
        .set(activity.toJson());

    notifyListeners();
  }

  Stream<List<ActivityFeedItem>> getTripActivityFeed(
    String tripId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('activity')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityFeedItem.fromJson(doc.data()))
              .toList(),
        );
  }

  // Travel Buddy Connections
  Future<void> sendBuddyRequest({
    required String recipientId,
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final request = BuddyRequest(
      id: _firestore.collection('buddy_requests').doc().id,
      senderId: user.uid,
      senderName: user.displayName ?? 'Anonymous',
      senderPhotoUrl: user.photoURL,
      recipientId: recipientId,
      message: message,
      status: BuddyRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('buddy_requests')
        .doc(request.id)
        .set(request.toJson());

    // Add to recipient's pending requests
    await _firestore
        .collection('users')
        .doc(recipientId)
        .collection('pending_buddy_requests')
        .doc(request.id)
        .set({'requestId': request.id, 'createdAt': request.createdAt});

    notifyListeners();
  }

  Future<void> respondToBuddyRequest({
    required String requestId,
    required bool accept,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final requestDoc = await _firestore
        .collection('buddy_requests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) throw Exception('Request not found');

    final request = BuddyRequest.fromJson(requestDoc.data()!);

    if (request.recipientId != user.uid) {
      throw Exception('Unauthorized to respond to this request');
    }

    // Update request status
    await _firestore.collection('buddy_requests').doc(requestId).update({
      'status': accept
          ? BuddyRequestStatus.accepted.name
          : BuddyRequestStatus.rejected.name,
      'respondedAt': DateTime.now(),
    });

    if (accept) {
      // Add to both users' buddy lists
      await _addToBuddyList(user.uid, request.senderId);
      await _addToBuddyList(request.senderId, user.uid);
    }

    // Remove from pending requests
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pending_buddy_requests')
        .doc(requestId)
        .delete();

    notifyListeners();
  }

  Future<void> _addToBuddyList(String userId, String buddyId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('travel_buddies')
        .doc(buddyId)
        .set({'buddyId': buddyId, 'addedAt': DateTime.now()});
  }

  Stream<List<BuddyRequest>> getPendingBuddyRequests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pending_buddy_requests')
        .snapshots()
        .asyncMap((snapshot) async {
          final requestIds = snapshot.docs.map((doc) => doc.id).toList();
          if (requestIds.isEmpty) return <BuddyRequest>[];

          final requests = await Future.wait(
            requestIds.map(
              (id) => _firestore
                  .collection('buddy_requests')
                  .doc(id)
                  .get()
                  .then(
                    (doc) =>
                        doc.exists ? BuddyRequest.fromJson(doc.data()!) : null,
                  ),
            ),
          );

          return requests.whereType<BuddyRequest>().toList();
        });
  }

  // Trip Recommendations
  Future<void> recommendTrip({
    required String tripId,
    required List<String> recipientIds,
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    for (final recipientId in recipientIds) {
      final recommendation = TripRecommendation(
        id: _firestore.collection('trip_recommendations').doc().id,
        tripId: tripId,
        senderId: user.uid,
        senderName: user.displayName ?? 'Anonymous',
        senderPhotoUrl: user.photoURL,
        recipientId: recipientId,
        message: message,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('trip_recommendations')
          .doc(recommendation.id)
          .set(recommendation.toJson());

      // Add to recipient's recommendations
      await _firestore
          .collection('users')
          .doc(recipientId)
          .collection('trip_recommendations')
          .doc(recommendation.id)
          .set({
            'recommendationId': recommendation.id,
            'createdAt': recommendation.createdAt,
          });
    }

    notifyListeners();
  }

  Stream<List<TripRecommendation>> getTripRecommendations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('trip_recommendations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final recommendationIds = snapshot.docs.map((doc) => doc.id).toList();
          if (recommendationIds.isEmpty) return <TripRecommendation>[];

          final recommendations = await Future.wait(
            recommendationIds.map(
              (id) => _firestore
                  .collection('trip_recommendations')
                  .doc(id)
                  .get()
                  .then(
                    (doc) => doc.exists
                        ? TripRecommendation.fromJson(doc.data()!)
                        : null,
                  ),
            ),
          );

          return recommendations.whereType<TripRecommendation>().toList();
        });
  }

  // Group Travel Features
  Future<TravelGroup> createTravelGroup({
    required String name,
    required String description,
    String? photoUrl,
    bool isPrivate = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final group = TravelGroup(
      id: _firestore.collection('travel_groups').doc().id,
      name: name,
      description: description,
      photoUrl: photoUrl,
      creatorId: user.uid,
      adminIds: [user.uid],
      memberIds: [user.uid],
      isPrivate: isPrivate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('travel_groups')
        .doc(group.id)
        .set(group.toJson());

    notifyListeners();
    return group;
  }

  Future<void> joinTravelGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('travel_groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([user.uid]),
      'updatedAt': DateTime.now(),
    });

    notifyListeners();
  }

  Stream<List<TravelGroup>> getUserTravelGroups() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('travel_groups')
        .where('memberIds', arrayContains: user.uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TravelGroup.fromJson(doc.data()))
              .toList(),
        );
  }

  // Trip Photo Albums
  Future<void> createTripPhotoAlbum({
    required String tripId,
    required String albumName,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final album = TripPhotoAlbum(
      id: _firestore
          .collection('trips')
          .doc(tripId)
          .collection('photo_albums')
          .doc()
          .id,
      tripId: tripId,
      name: albumName,
      description: description,
      creatorId: user.uid,
      contributorIds: [user.uid],
      photoCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('photo_albums')
        .doc(album.id)
        .set(album.toJson());

    notifyListeners();
  }

  Future<void> addPhotoToAlbum({
    required String tripId,
    required String albumId,
    required String photoUrl,
    required String caption,
    String? location,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final photo = TripPhoto(
      id: _firestore
          .collection('trips')
          .doc(tripId)
          .collection('photo_albums')
          .doc(albumId)
          .collection('photos')
          .doc()
          .id,
      albumId: albumId,
      photoUrl: photoUrl,
      caption: caption,
      location: location,
      uploaderId: user.uid,
      uploaderName: user.displayName ?? 'Anonymous',
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('photo_albums')
        .doc(albumId)
        .collection('photos')
        .doc(photo.id)
        .set(photo.toJson());

    // Update album photo count
    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('photo_albums')
        .doc(albumId)
        .update({
          'photoCount': FieldValue.increment(1),
          'updatedAt': DateTime.now(),
        });

    notifyListeners();
  }

  // Private helper methods
  Future<void> _sendMentionNotifications(
    String tripId,
    TripComment comment,
    List<String> mentionedUserIds,
  ) async {
    // This would integrate with the notification service
    // For now, we'll create a simple notification record
    for (final userId in mentionedUserIds) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'type': 'trip_mention',
            'tripId': tripId,
            'commentId': comment.id,
            'message': '${comment.authorName} mentioned you in a trip comment',
            'createdAt': DateTime.now(),
            'read': false,
          });
    }
  }
}
