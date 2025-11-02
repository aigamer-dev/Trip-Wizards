import 'package:travel_wizards/src/shared/models/trip.dart';
import 'package:travel_wizards/src/shared/services/trips_repository.dart';
import 'package:travel_wizards/src/shared/services/error_handling_service.dart';
import 'package:travel_wizards/src/shared/services/generation_service.dart';
import 'package:travel_wizards/src/shared/services/offline_service.dart';

enum TripStatus { ongoing, planned, suggested, completed }

class TripCategorization {
  final List<Trip> ongoingTrips;
  final List<Trip> plannedTrips;
  final List<Trip> suggestedTrips;
  final List<Trip> completedTrips;

  const TripCategorization({
    required this.ongoingTrips,
    required this.plannedTrips,
    required this.suggestedTrips,
    required this.completedTrips,
  });

  bool get hasOngoingTrips => ongoingTrips.isNotEmpty;
  bool get hasPlannedTrips => plannedTrips.isNotEmpty;
  bool get hasSuggestedTrips => suggestedTrips.isNotEmpty;
  bool get hasCompletedTrips => completedTrips.isNotEmpty;
  bool get hasAnyTrips =>
      ongoingTrips.isNotEmpty ||
      plannedTrips.isNotEmpty ||
      suggestedTrips.isNotEmpty ||
      completedTrips.isNotEmpty;
}

class HomeDataService {
  HomeDataService._();
  static final HomeDataService instance = HomeDataService._();

  /// Stream that provides categorized trip data for the home screen
  /// Uses watchAccessibleTrips() to show owned + shared trips (respects visibility)
  Stream<TripCategorization> get tripsStream {
    return TripsRepository.instance.watchAccessibleTrips().map(
      _categorizeTrips,
    );
  }

  /// Fetch categorized trips once
  Future<TripCategorization> getTrips() async {
    try {
      final trips = await TripsRepository.instance.listTrips();
      return _categorizeTrips(trips);
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'HomeDataService: Getting trips',
        showToUser: true,
        userContext: null,
      );
      return const TripCategorization(
        ongoingTrips: [],
        plannedTrips: [],
        suggestedTrips: [],
        completedTrips: [],
      );
    }
  }

  /// Get ongoing trips (currently happening)
  Future<List<Trip>> getOngoingTrips() async {
    final categorization = await getTrips();
    return categorization.ongoingTrips;
  }

  /// Get planned trips (future trips)
  Future<List<Trip>> getPlannedTrips() async {
    final categorization = await getTrips();
    return categorization.plannedTrips;
  }

  /// Get recent trips for suggestions
  Future<List<Trip>> getRecentTrips() async {
    final categorization = await getTrips();
    return categorization.completedTrips.take(3).toList();
  }

  /// Generate suggested trips based on user's trip history
  Future<List<Map<String, String>>> getSuggestedTrips() async {
    try {
      final categorization = await getTrips();

      // If user has no trips, show default suggestions
      if (!categorization.hasAnyTrips) {
        return _getDefaultSuggestions();
      }

      // Generate suggestions based on user's past destinations and preferences
      return _generatePersonalizedSuggestions(categorization);
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'HomeDataService: Getting suggested trips',
        showToUser: false,
      );
      return _getDefaultSuggestions();
    }
  }

  TripCategorization _categorizeTrips(List<Trip> trips) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<Trip> ongoing = [];
    final List<Trip> planned = [];
    final List<Trip> suggested = [];
    final List<Trip> completed = [];

    for (final trip in trips) {
      final startDate = DateTime(
        trip.startDate.year,
        trip.startDate.month,
        trip.startDate.day,
      );
      final endDate = DateTime(
        trip.endDate.year,
        trip.endDate.month,
        trip.endDate.day,
      );

      if (startDate.isBefore(today) || startDate.isAtSameMomentAs(today)) {
        if (endDate.isAfter(today) || endDate.isAtSameMomentAs(today)) {
          // Trip is currently happening
          ongoing.add(trip);
        } else {
          // Trip has ended
          completed.add(trip);
        }
      } else {
        // Trip is in the future
        planned.add(trip);
      }
    }

    return TripCategorization(
      ongoingTrips: ongoing,
      plannedTrips: planned,
      suggestedTrips:
          suggested, // Currently empty, could be populated from external sources
      completedTrips: completed,
    );
  }

  List<Map<String, String>> _getDefaultSuggestions() {
    return [
      {
        'title': 'Spiritual Journey to Varanasi',
        'description': 'Experience the holy ghats and ancient traditions',
        'duration': '3 days',
        'image':
            'https://images.unsplash.com/photo-1564507623973-8d48b7ce6f35?w=400&h=300&fit=crop',
      },
      {
        'title': 'Kerala Backwaters Adventure',
        'description': 'Cruise through serene waterways and lush landscapes',
        'duration': '5 days',
        'image':
            'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=400&h=300&fit=crop',
      },
      {
        'title': 'Rajasthan Royal Heritage',
        'description': 'Explore majestic palaces and vibrant culture',
        'duration': '7 days',
        'image':
            'https://images.unsplash.com/photo-1539650116574-75c0c6d73f6e?w=400&h=300&fit=crop',
      },
    ];
  }

  List<Map<String, String>> _generatePersonalizedSuggestions(
    TripCategorization categorization,
  ) {
    // Analyze user's trip history
    final allTrips = [
      ...categorization.ongoingTrips,
      ...categorization.plannedTrips,
      ...categorization.completedTrips,
    ];

    // Extract preferences from past trips
    final Set<String> visitedDestinations = {};
    for (final trip in allTrips) {
      visitedDestinations.addAll(trip.destinations);
    }

    // Generate suggestions based on visited destinations
    if (visitedDestinations.any(
      (d) =>
          d.toLowerCase().contains('beach') ||
          d.toLowerCase().contains('goa') ||
          d.toLowerCase().contains('kerala'),
    )) {
      // User likes beaches/coastal areas
      return [
        {
          'title': 'Andaman Islands Escape',
          'description': 'Pristine beaches and crystal clear waters',
          'duration': '6 days',
          'image':
              'https://images.unsplash.com/photo-1559563458-527cfc78c5ec?w=400&h=300&fit=crop',
        },
        {
          'title': 'Lakshadweep Paradise',
          'description': 'Untouched coral islands and lagoons',
          'duration': '4 days',
          'image':
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop',
        },
        {
          'title': 'Pondicherry French Quarter',
          'description': 'Colonial charm meets coastal beauty',
          'duration': '3 days',
          'image':
              'https://images.unsplash.com/photo-1580408318076-4e5d3e1c4fbc?w=400&h=300&fit=crop',
        },
      ];
    } else if (visitedDestinations.any(
      (d) =>
          d.toLowerCase().contains('mountain') ||
          d.toLowerCase().contains('himalaya') ||
          d.toLowerCase().contains('kashmir'),
    )) {
      // User likes mountains
      return [
        {
          'title': 'Ladakh High Altitude Desert',
          'description': 'Moonscapes and ancient monasteries',
          'duration': '8 days',
          'image':
              'https://images.unsplash.com/photo-1609137144351-d4c4a7a72b4a?w=400&h=300&fit=crop',
        },
        {
          'title': 'Spiti Valley Adventure',
          'description': 'Remote Himalayan villages and stark beauty',
          'duration': '7 days',
          'image':
              'https://images.unsplash.com/photo-1605538883669-825200433431?w=400&h=300&fit=crop',
        },
        {
          'title': 'Sikkim Mountain Retreat',
          'description': 'Rhododendrons and sacred peaks',
          'duration': '5 days',
          'image':
              'https://images.unsplash.com/photo-1570263413267-d3ea7f8b3c5e?w=400&h=300&fit=crop',
        },
      ];
    } else {
      // Default cultural/diverse suggestions
      return [
        {
          'title': 'Golden Triangle Circuit',
          'description': 'Delhi, Agra, and Jaipur highlights',
          'duration': '6 days',
          'image':
              'https://images.unsplash.com/photo-1564507623973-8d48b7ce6f35?w=400&h=300&fit=crop',
        },
        {
          'title': 'South India Temple Trail',
          'description': 'Ancient temples and rich traditions',
          'duration': '8 days',
          'image':
              'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=400&h=300&fit=crop',
        },
        {
          'title': 'Northeast India Explorer',
          'description': 'Unexplored tribes and pristine nature',
          'duration': '10 days',
          'image':
              'https://images.unsplash.com/photo-1605538883669-825200433431?w=400&h=300&fit=crop',
        },
      ];
    }
  }

  /// Check if there are any ongoing AI generation processes
  /// This would typically connect to the AI service to check status
  Future<List<Map<String, dynamic>>> getGenerationInProgress() async {
    try {
      await OfflineService.instance.initialize();

      final generationService = GenerationService.instance;
      final List<Map<String, dynamic>> jobs = generationService.activeJobs
          .map((job) => job.toSummaryMap())
          .toList();

      final pendingActions = OfflineService.instance.getPendingActions();
      for (final action in pendingActions) {
        final type = (action['type'] as String?)?.toLowerCase();
        if (type == null) continue;

        final isGenerationAction =
            type.contains('generate') || type.contains('ai_plan');
        if (!isGenerationAction) continue;

        final timestampMs =
            action['timestamp'] as int? ??
            DateTime.now().millisecondsSinceEpoch;
        final queuedAt = DateTime.fromMillisecondsSinceEpoch(
          timestampMs,
        ).toIso8601String();

        jobs.add({
          'id': action['id']?.toString() ?? 'queued_$timestampMs',
          'type': action['type'],
          'status': GenerationJobState.queued.name,
          'queuedAt': queuedAt,
          'progress': 0,
          'payload': action,
          'message': 'Queued while offline',
        });
      }

      jobs.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['queuedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            DateTime.tryParse(b['queuedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return jobs;
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'HomeDataService: Getting generation progress',
        showToUser: false,
      );
      return [];
    }
  }

  /// Get trip statistics for display
  Future<Map<String, int>> getTripStatistics() async {
    try {
      final categorization = await getTrips();
      return {
        'ongoing': categorization.ongoingTrips.length,
        'planned': categorization.plannedTrips.length,
        'completed': categorization.completedTrips.length,
        'total':
            categorization.ongoingTrips.length +
            categorization.plannedTrips.length +
            categorization.completedTrips.length,
      };
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'HomeDataService: Getting trip statistics',
        showToUser: false,
      );
      return {'ongoing': 0, 'planned': 0, 'completed': 0, 'total': 0};
    }
  }
}
