import 'package:flutter/foundation.dart';

@immutable
class TravelIdea {
  final String id;
  final String title;
  final String subtitle;
  final Set<String> tags; // e.g. {Weekend, Adventure, Budget}
  final int durationDays; // approximate trip length
  final String budget; // 'low' | 'medium' | 'high'

  const TravelIdea({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.durationDays,
    required this.budget,
  });
}

/// Simple in-memory repository of public travel ideas.
class IdeasRepository {
  IdeasRepository._internal();
  static final IdeasRepository instance = IdeasRepository._internal();

  static final List<TravelIdea> _all = <TravelIdea>[
    const TravelIdea(
      id: 'hampi_weekend',
      title: 'Weekend in Hampi',
      subtitle: 'Heritage • 2 days • Budget friendly',
      tags: {'Weekend', 'Budget', 'Heritage'},
      durationDays: 2,
      budget: 'low',
    ),
    const TravelIdea(
      id: 'goa_beach_getaway',
      title: 'Goa Beach Getaway',
      subtitle: 'Relax • 4 days • Nightlife',
      tags: {'Beach', 'Relax'},
      durationDays: 4,
      budget: 'medium',
    ),
    const TravelIdea(
      id: 'manali_adventure',
      title: 'Manali Adventure',
      subtitle: 'Trek • 5 days • Scenic',
      tags: {'Adventure', 'Mountains'},
      durationDays: 5,
      budget: 'medium',
    ),
    const TravelIdea(
      id: 'jaipur_culture',
      title: 'Jaipur Cultural Circuit',
      subtitle: 'Palaces • 3 days • Heritage',
      tags: {'Weekend', 'Heritage'},
      durationDays: 3,
      budget: 'low',
    ),
    const TravelIdea(
      id: 'alleppey_backwaters',
      title: 'Alleppey Backwaters',
      subtitle: 'Houseboat • 2 days • Relax',
      tags: {'Weekend', 'Relax'},
      durationDays: 2,
      budget: 'medium',
    ),
    const TravelIdea(
      id: 'ladakh_roadtrip',
      title: 'Ladakh Road Trip',
      subtitle: 'High passes • 7 days • Adventure',
      tags: {'Adventure', 'Roadtrip'},
      durationDays: 7,
      budget: 'high',
    ),
  ];

  List<TravelIdea> getAll() => List.unmodifiable(_all);

  List<TravelIdea> search({
    String? query,
    Set<String> tags = const {},
    String? budget,
    String? durationBucket, // '2-3' | '4-5' | '6+'
  }) {
    Iterable<TravelIdea> items = _all;
    if (query != null && query.trim().isNotEmpty) {
      final ql = query.trim().toLowerCase();
      items = items.where((e) => e.title.toLowerCase().contains(ql));
    }
    if (tags.isNotEmpty) {
      items = items.where((e) => tags.every(e.tags.contains));
    }
    if (budget != null && budget.isNotEmpty) {
      items = items.where((e) => e.budget == budget);
    }
    if (durationBucket != null && durationBucket.isNotEmpty) {
      items = items.where((e) {
        final d = e.durationDays;
        switch (durationBucket) {
          case '2-3':
            return d >= 2 && d <= 3;
          case '4-5':
            return d >= 4 && d <= 5;
          case '6+':
            return d >= 6;
        }
        return true;
      });
    }
    return items.toList(growable: false);
  }
}
