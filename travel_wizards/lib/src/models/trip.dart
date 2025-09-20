import 'package:flutter/foundation.dart';

@immutable
class Trip {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> destinations;
  final String? notes;

  const Trip({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.destinations,
    this.notes,
  });

  Trip copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? destinations,
    String? notes,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      destinations: destinations ?? this.destinations,
      notes: notes ?? this.notes,
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
    );
  }
}
