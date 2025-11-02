import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final Map<String, dynamic> settings;
  final List<String> buddies;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.settings = const {},
    this.buddies = const [],
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? settings,
    List<String>? buddies,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      settings: settings ?? this.settings,
      buddies: buddies ?? this.buddies,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'settings': settings,
      'buddies': buddies,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      buddies: List<String>.from(map['buddies'] ?? []),
    );
  }
}
