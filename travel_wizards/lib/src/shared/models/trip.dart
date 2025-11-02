import 'package:flutter/foundation.dart';

/// Trip visibility modes
enum TripVisibility {
  /// Only creator can see
  private,
  /// Creator and collaborators can see
  shared,
  /// Everyone can see in community explore
  community,
}

@immutable
class Trip {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> destinations;
  final String? notes;
  
  // Permission fields
  final String ownerId;
  final TripVisibility visibility;
  final List<String> sharedWith;
  final bool isPublic;
  
  // Source tracking
  /// 'calendar' if imported from device calendar, 'app' if created manually (default)
  final String source;

  const Trip({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.destinations,
    this.notes,
    required this.ownerId,
    this.visibility = TripVisibility.private,
    this.sharedWith = const [],
    this.isPublic = false,
    this.source = 'app',
  });

  Trip copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? destinations,
    String? notes,
    String? ownerId,
    TripVisibility? visibility,
    List<String>? sharedWith,
    bool? isPublic,
    String? source,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      destinations: destinations ?? this.destinations,
      notes: notes ?? this.notes,
      ownerId: ownerId ?? this.ownerId,
      visibility: visibility ?? this.visibility,
      sharedWith: sharedWith ?? this.sharedWith,
      isPublic: isPublic ?? this.isPublic,
      source: source ?? this.source,
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
      'visibility': visibility.name,
      'sharedWith': sharedWith,
      'isPublic': isPublic,
      'source': source,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      title: map['title'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      destinations: List<String>.from(map['destinations'] as List<dynamic>),
      notes: map['notes'] as String?,
      ownerId: map['ownerId'] as String? ?? '',
      visibility: _parseVisibility(map['visibility']),
      sharedWith: map['sharedWith'] != null 
          ? List<String>.from(map['sharedWith'] as List<dynamic>)
          : const [],
      isPublic: map['isPublic'] as bool? ?? false,
      source: map['source'] as String? ?? 'app',
    );
  }

  static TripVisibility _parseVisibility(dynamic value) {
    if (value == null) return TripVisibility.private;
    if (value is TripVisibility) return value;
    
    final str = value.toString().toLowerCase();
    return TripVisibility.values.firstWhere(
      (v) => v.name == str,
      orElse: () => TripVisibility.private,
    );
  }
}
