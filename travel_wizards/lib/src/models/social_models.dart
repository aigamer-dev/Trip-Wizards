// Social Models for Travel Wizards Enhanced Social Features
// Defines data models for social interactions, comments, reactions, and group features

enum TripReactionType { like, love, excited, thumbsUp, helpful, wow }

enum ActivityType {
  tripCreated,
  tripUpdated,
  memberAdded,
  memberRemoved,
  commentAdded,
  reactionAdded,
  photoAdded,
  itineraryUpdated,
  bookingConfirmed,
  checkIn,
  checkOut,
  emergencyAlert,
}

enum BuddyRequestStatus { pending, accepted, rejected }

class TripComment {
  final String id;
  final String tripId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final String? parentCommentId; // For threaded comments
  final List<String> mentionedUserIds;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripComment({
    required this.id,
    required this.tripId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.parentCommentId,
    required this.mentionedUserIds,
    this.likeCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'parentCommentId': parentCommentId,
      'mentionedUserIds': mentionedUserIds,
      'likeCount': likeCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TripComment.fromJson(Map<String, dynamic> json) {
    return TripComment(
      id: json['id'] ?? '',
      tripId: json['tripId'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      authorPhotoUrl: json['authorPhotoUrl'],
      content: json['content'] ?? '',
      parentCommentId: json['parentCommentId'],
      mentionedUserIds: List<String>.from(json['mentionedUserIds'] ?? []),
      likeCount: json['likeCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  TripComment copyWith({
    String? id,
    String? tripId,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? content,
    String? parentCommentId,
    List<String>? mentionedUserIds,
    int? likeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripComment(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      content: content ?? this.content,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TripReaction {
  final String id;
  final String tripId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final TripReactionType reactionType;
  final DateTime createdAt;

  TripReaction({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.reactionType,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'reactionType': reactionType.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TripReaction.fromJson(Map<String, dynamic> json) {
    return TripReaction(
      id: json['id'] ?? '',
      tripId: json['tripId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhotoUrl: json['userPhotoUrl'],
      reactionType: TripReactionType.values.firstWhere(
        (e) => e.name == json['reactionType'],
        orElse: () => TripReactionType.like,
      ),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ActivityFeedItem {
  final String id;
  final String tripId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final ActivityType activityType;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  ActivityFeedItem({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.activityType,
    required this.description,
    required this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'activityType': activityType.name,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityFeedItem.fromJson(Map<String, dynamic> json) {
    return ActivityFeedItem(
      id: json['id'] ?? '',
      tripId: json['tripId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhotoUrl: json['userPhotoUrl'],
      activityType: ActivityType.values.firstWhere(
        (e) => e.name == json['activityType'],
        orElse: () => ActivityType.tripUpdated,
      ),
      description: json['description'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class BuddyRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String recipientId;
  final String? message;
  final BuddyRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  BuddyRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.recipientId,
    this.message,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'recipientId': recipientId,
      'message': message,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  factory BuddyRequest.fromJson(Map<String, dynamic> json) {
    return BuddyRequest(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderPhotoUrl: json['senderPhotoUrl'],
      recipientId: json['recipientId'] ?? '',
      message: json['message'],
      status: BuddyRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BuddyRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
    );
  }
}

class TripRecommendation {
  final String id;
  final String tripId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String recipientId;
  final String? message;
  final DateTime createdAt;
  final bool viewed;

  TripRecommendation({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.recipientId,
    this.message,
    required this.createdAt,
    this.viewed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'recipientId': recipientId,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'viewed': viewed,
    };
  }

  factory TripRecommendation.fromJson(Map<String, dynamic> json) {
    return TripRecommendation(
      id: json['id'] ?? '',
      tripId: json['tripId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderPhotoUrl: json['senderPhotoUrl'],
      recipientId: json['recipientId'] ?? '',
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      viewed: json['viewed'] ?? false,
    );
  }
}

class TravelGroup {
  final String id;
  final String name;
  final String description;
  final String? photoUrl;
  final String creatorId;
  final List<String> adminIds;
  final List<String> memberIds;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount;

  TravelGroup({
    required this.id,
    required this.name,
    required this.description,
    this.photoUrl,
    required this.creatorId,
    required this.adminIds,
    required this.memberIds,
    required this.isPrivate,
    required this.createdAt,
    required this.updatedAt,
  }) : memberCount = memberIds.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'creatorId': creatorId,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'isPrivate': isPrivate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TravelGroup.fromJson(Map<String, dynamic> json) {
    return TravelGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      photoUrl: json['photoUrl'],
      creatorId: json['creatorId'] ?? '',
      adminIds: List<String>.from(json['adminIds'] ?? []),
      memberIds: List<String>.from(json['memberIds'] ?? []),
      isPrivate: json['isPrivate'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class TripPhotoAlbum {
  final String id;
  final String tripId;
  final String name;
  final String? description;
  final String creatorId;
  final List<String> contributorIds;
  final int photoCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripPhotoAlbum({
    required this.id,
    required this.tripId,
    required this.name,
    this.description,
    required this.creatorId,
    required this.contributorIds,
    required this.photoCount,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'contributorIds': contributorIds,
      'photoCount': photoCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TripPhotoAlbum.fromJson(Map<String, dynamic> json) {
    return TripPhotoAlbum(
      id: json['id'] ?? '',
      tripId: json['tripId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      creatorId: json['creatorId'] ?? '',
      contributorIds: List<String>.from(json['contributorIds'] ?? []),
      photoCount: json['photoCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class TripPhoto {
  final String id;
  final String albumId;
  final String photoUrl;
  final String caption;
  final String? location;
  final String uploaderId;
  final String uploaderName;
  final DateTime createdAt;
  final List<String> likedByIds;

  TripPhoto({
    required this.id,
    required this.albumId,
    required this.photoUrl,
    required this.caption,
    this.location,
    required this.uploaderId,
    required this.uploaderName,
    required this.createdAt,
    this.likedByIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'albumId': albumId,
      'photoUrl': photoUrl,
      'caption': caption,
      'location': location,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'createdAt': createdAt.toIso8601String(),
      'likedByIds': likedByIds,
    };
  }

  factory TripPhoto.fromJson(Map<String, dynamic> json) {
    return TripPhoto(
      id: json['id'] ?? '',
      albumId: json['albumId'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      caption: json['caption'] ?? '',
      location: json['location'],
      uploaderId: json['uploaderId'] ?? '',
      uploaderName: json['uploaderName'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      likedByIds: List<String>.from(json['likedByIds'] ?? []),
    );
  }
}

class TravelBuddy {
  final String id;
  final String name;
  final String? photoUrl;
  final String? bio;
  final List<String> travelInterests;
  final List<String> visitedCountries;
  final DateTime addedAt;
  final bool isOnline;

  TravelBuddy({
    required this.id,
    required this.name,
    this.photoUrl,
    this.bio,
    required this.travelInterests,
    required this.visitedCountries,
    required this.addedAt,
    this.isOnline = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'bio': bio,
      'travelInterests': travelInterests,
      'visitedCountries': visitedCountries,
      'addedAt': addedAt.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  factory TravelBuddy.fromJson(Map<String, dynamic> json) {
    return TravelBuddy(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'],
      bio: json['bio'],
      travelInterests: List<String>.from(json['travelInterests'] ?? []),
      visitedCountries: List<String>.from(json['visitedCountries'] ?? []),
      addedAt: DateTime.parse(json['addedAt']),
      isOnline: json['isOnline'] ?? false,
    );
  }
}
