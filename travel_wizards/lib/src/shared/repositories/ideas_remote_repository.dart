import '../services/backend_service.dart';
import 'ideas_repository.dart';

/// Remote ideas repository that fetches from backend and converts to TravelIdea.
class IdeasRemoteRepository {
  IdeasRemoteRepository._();
  static final IdeasRemoteRepository instance = IdeasRemoteRepository._();

  Future<List<TravelIdea>> search({
    String? query,
    Set<String> tags = const {},
    String? budget,
    String? durationBucket, // '2-3' | '4-5' | '6+'
  }) async {
    final rows = await BackendService.instance.fetchIdeas(query: query);
    Iterable<TravelIdea> items = rows.map(_fromJson);

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

  TravelIdea _fromJson(Map<String, dynamic> j) {
    return TravelIdea(
      id: j['id'] as String,
      title: j['title'] as String,
      subtitle: j['subtitle'] as String? ?? '',
      tags: Set<String>.from(j['tags'] as List? ?? const []),
      durationDays: (j['durationDays'] as num?)?.toInt() ?? 3,
      budget: (j['budget'] as String?)?.toLowerCase() ?? 'medium',
    );
  }
}
