import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class CollaborativeTrip {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> destinations;
  final String? notes;

  // Collaboration fields
  final String ownerId;
  final List<TripMember> members;
  final List<TripInvitation> invitations;
  final TripPermissions permissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastUpdatedBy;

  // Real-time collaboration
  final Map<String, dynamic> realtimeState;

  const CollaborativeTrip({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.destinations,
    this.notes,
    required this.ownerId,
    this.members = const [],
    this.invitations = const [],
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
    required this.lastUpdatedBy,
    this.realtimeState = const {},
  });

  CollaborativeTrip copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? destinations,
    String? notes,
    String? ownerId,
    List<TripMember>? members,
    List<TripInvitation>? invitations,
    TripPermissions? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastUpdatedBy,
    Map<String, dynamic>? realtimeState,
  }) {
    return CollaborativeTrip(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      destinations: destinations ?? this.destinations,
      notes: notes ?? this.notes,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      invitations: invitations ?? this.invitations,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      realtimeState: realtimeState ?? this.realtimeState,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'destinations': destinations,
      'notes': notes,
      'ownerId': ownerId,
      'members': members.map((m) => m.toMap()).toList(),
      'invitations': invitations.map((i) => i.toMap()).toList(),
      'permissions': permissions.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastUpdatedBy': lastUpdatedBy,
      'realtimeState': realtimeState,
    };
  }

  factory CollaborativeTrip.fromMap(Map<String, dynamic> map) {
    return CollaborativeTrip(
      id: map['id'] as String,
      title: map['title'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      destinations: List<String>.from(map['destinations'] as List<dynamic>),
      notes: map['notes'] as String?,
      ownerId: map['ownerId'] as String,
      members: (map['members'] as List<dynamic>? ?? [])
          .map((m) => TripMember.fromMap(m as Map<String, dynamic>))
          .toList(),
      invitations: (map['invitations'] as List<dynamic>? ?? [])
          .map((i) => TripInvitation.fromMap(i as Map<String, dynamic>))
          .toList(),
      permissions: TripPermissions.fromMap(
        map['permissions'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      lastUpdatedBy: map['lastUpdatedBy'] as String,
      realtimeState: map['realtimeState'] as Map<String, dynamic>? ?? {},
    );
  }

  factory CollaborativeTrip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CollaborativeTrip.fromMap({...data, 'id': doc.id});
  }

  /// Check if user is the owner
  bool isOwner(String userId) => ownerId == userId;

  /// Check if user is a member
  bool isMember(String userId) => members.any((m) => m.userId == userId);

  /// Check if user has access to this trip
  bool hasAccess(String userId) => isOwner(userId) || isMember(userId);

  /// Get member by user ID
  TripMember? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Check if user can edit this trip
  bool canEdit(String userId) {
    if (isOwner(userId)) return true;
    final member = getMember(userId);
    return member?.role == TripRole.editor || member?.role == TripRole.admin;
  }

  /// Check if user can invite others
  bool canInvite(String userId) {
    if (isOwner(userId)) return true;
    final member = getMember(userId);
    return member?.role == TripRole.admin && permissions.allowMemberInvites;
  }

  /// Get display name for last updated user
  String getLastUpdatedByName() {
    if (ownerId == lastUpdatedBy) return 'Owner';
    final member = getMember(lastUpdatedBy);
    return member?.displayName ?? 'Unknown User';
  }

  /// Get all user IDs with access
  List<String> getAllUserIds() {
    return [ownerId, ...members.map((m) => m.userId)];
  }
}

@immutable
class TripMember {
  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final TripRole role;
  final DateTime joinedAt;
  final bool isActive;

  const TripMember({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
  });

  TripMember copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? photoUrl,
    TripRole? role,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return TripMember(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory TripMember.fromMap(Map<String, dynamic> map) {
    return TripMember(
      userId: map['userId'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: TripRole.values.firstWhere((r) => r.name == map['role']),
      joinedAt: DateTime.parse(map['joinedAt'] as String),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  String get displayNameOrEmail => displayName ?? email;
}

@immutable
class TripInvitation {
  final String id;
  final String tripId;
  final String inviterUserId;
  final String inviteeEmail;
  final TripRole proposedRole;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message;

  const TripInvitation({
    required this.id,
    required this.tripId,
    required this.inviterUserId,
    required this.inviteeEmail,
    required this.proposedRole,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  TripInvitation copyWith({
    String? id,
    String? tripId,
    String? inviterUserId,
    String? inviteeEmail,
    TripRole? proposedRole,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? message,
  }) {
    return TripInvitation(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      inviterUserId: inviterUserId ?? this.inviterUserId,
      inviteeEmail: inviteeEmail ?? this.inviteeEmail,
      proposedRole: proposedRole ?? this.proposedRole,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'inviterUserId': inviterUserId,
      'inviteeEmail': inviteeEmail,
      'proposedRole': proposedRole.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'message': message,
    };
  }

  factory TripInvitation.fromMap(Map<String, dynamic> map) {
    return TripInvitation(
      id: map['id'] as String,
      tripId: map['tripId'] as String,
      inviterUserId: map['inviterUserId'] as String,
      inviteeEmail: map['inviteeEmail'] as String,
      proposedRole: TripRole.values.firstWhere(
        (r) => r.name == map['proposedRole'],
      ),
      status: InvitationStatus.values.firstWhere(
        (s) => s.name == map['status'],
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'] as String)
          : null,
      message: map['message'] as String?,
    );
  }

  bool get isPending => status == InvitationStatus.pending;
  bool get isExpired =>
      createdAt.isBefore(DateTime.now().subtract(const Duration(days: 30)));
}

@immutable
class TripPermissions {
  final bool allowMemberInvites;
  final bool allowMemberEdit;
  final bool allowMemberDelete;
  final bool requireApprovalForChanges;
  final bool allowPublicSharing;

  const TripPermissions({
    this.allowMemberInvites = false,
    this.allowMemberEdit = true,
    this.allowMemberDelete = false,
    this.requireApprovalForChanges = false,
    this.allowPublicSharing = false,
  });

  TripPermissions copyWith({
    bool? allowMemberInvites,
    bool? allowMemberEdit,
    bool? allowMemberDelete,
    bool? requireApprovalForChanges,
    bool? allowPublicSharing,
  }) {
    return TripPermissions(
      allowMemberInvites: allowMemberInvites ?? this.allowMemberInvites,
      allowMemberEdit: allowMemberEdit ?? this.allowMemberEdit,
      allowMemberDelete: allowMemberDelete ?? this.allowMemberDelete,
      requireApprovalForChanges:
          requireApprovalForChanges ?? this.requireApprovalForChanges,
      allowPublicSharing: allowPublicSharing ?? this.allowPublicSharing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowMemberInvites': allowMemberInvites,
      'allowMemberEdit': allowMemberEdit,
      'allowMemberDelete': allowMemberDelete,
      'requireApprovalForChanges': requireApprovalForChanges,
      'allowPublicSharing': allowPublicSharing,
    };
  }

  factory TripPermissions.fromMap(Map<String, dynamic> map) {
    return TripPermissions(
      allowMemberInvites: map['allowMemberInvites'] as bool? ?? false,
      allowMemberEdit: map['allowMemberEdit'] as bool? ?? true,
      allowMemberDelete: map['allowMemberDelete'] as bool? ?? false,
      requireApprovalForChanges:
          map['requireApprovalForChanges'] as bool? ?? false,
      allowPublicSharing: map['allowPublicSharing'] as bool? ?? false,
    );
  }

  /// Default permissions for new trips
  static const TripPermissions defaultPermissions = TripPermissions(
    allowMemberEdit: true,
    allowMemberInvites: false,
    allowMemberDelete: false,
    requireApprovalForChanges: false,
    allowPublicSharing: false,
  );
}

enum TripRole {
  viewer, // Can only view the trip
  editor, // Can edit trip details
  admin, // Can edit and invite others
}

enum InvitationStatus { pending, accepted, declined, expired }

extension TripRoleExtension on TripRole {
  String get displayName {
    switch (this) {
      case TripRole.viewer:
        return 'Viewer';
      case TripRole.editor:
        return 'Editor';
      case TripRole.admin:
        return 'Admin';
    }
  }

  String get description {
    switch (this) {
      case TripRole.viewer:
        return 'Can view trip details';
      case TripRole.editor:
        return 'Can view and edit trip details';
      case TripRole.admin:
        return 'Can view, edit, and manage members';
    }
  }
}

extension InvitationStatusExtension on InvitationStatus {
  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.declined:
        return 'Declined';
      case InvitationStatus.expired:
        return 'Expired';
    }
  }
}
