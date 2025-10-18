import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.uid,
    this.email,
    this.name,
    this.username,
    this.photoUrl,
    this.languageCode,
    this.state,
    this.city,
    this.country,
    this.gender,
    this.dob,
    this.foodPreferences = const <String>[],
    this.allergies,
    this.lastUpdated,
  });

  final String uid;
  final String? email;
  final String? name;
  final String? username;
  final String? photoUrl;
  final String? languageCode;
  final String? state;
  final String? city;
  final String? country;
  final String? gender;
  final DateTime? dob;
  final List<String> foodPreferences;
  final String? allergies;
  final DateTime? lastUpdated;

  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    String? username,
    String? photoUrl,
    String? languageCode,
    String? state,
    String? city,
    String? country,
    String? gender,
    DateTime? dob,
    List<String>? foodPreferences,
    String? allergies,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      languageCode: languageCode ?? this.languageCode,
      state: state ?? this.state,
      city: city ?? this.city,
      country: country ?? this.country,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      allergies: allergies ?? this.allergies,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final prefs = foodPreferences;
    return {
      'name': name,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'languageCode': languageCode,
      'locale': languageCode,
      'state': state,
      'city': city,
      'country': country,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'foodPreferences': prefs,
      'foodPrefs': prefs,
      'allergies': allergies,
      'lastUpdated': lastUpdated?.toIso8601String(),
    }..removeWhere((_, value) => value == null || value == '');
  }

  Map<String, dynamic> toCacheMap() {
    final map = toFirestoreMap();
    map['uid'] = uid;
    return map;
  }

  static UserProfile fromFirestoreMap(String uid, Map<String, dynamic> map) {
    final List<dynamic>? foodPrefsDynamic =
        (map['foodPreferences'] as List?) ?? (map['foodPrefs'] as List?);
    return UserProfile(
      uid: uid,
      email: map['email'] as String?,
      name: map['name'] as String?,
      username: map['username'] as String?,
      photoUrl: map['photoUrl'] as String?,
      languageCode:
          (map['languageCode'] as String?) ?? (map['locale'] as String?),
      state: map['state'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
      gender: map['gender'] as String?,
      dob: _parseDate(map['dob']),
      foodPreferences: foodPrefsDynamic == null
          ? const <String>[]
          : List<String>.from(foodPrefsDynamic),
      allergies: map['allergies'] as String?,
      lastUpdated: _parseDate(map['lastUpdated']),
    );
  }

  static UserProfile fromCacheMap(Map<String, dynamic> map) {
    return fromFirestoreMap(map['uid'] as String? ?? 'local', map);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
