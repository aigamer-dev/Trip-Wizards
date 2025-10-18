import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_wizards/src/shared/models/trip.dart';
import 'package:travel_wizards/src/shared/services/trips_repository.dart';
import 'package:travel_wizards/src/features/trip_planning/data/plan_trip_store.dart';

/// Budget options for trip planning
enum Budget { low, medium, high }

/// Trip planning controller that manages state without global variables
class TripPlanningController extends ChangeNotifier {
  // Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController originController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // State
  final List<String> _destinations = [];
  DateTimeRange? _dates;
  int? _durationDays;
  Budget _budget = Budget.medium;
  String _notes = '';
  String _travelParty = 'Solo';
  String _pace = 'Balanced';
  bool _preferSurface = true;
  String _stayType = 'Hotel';
  final Set<String> _interests = {};
  bool _dirty = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Test-only properties (separated from production code)
  String? _testAutoPopAction;

  // Getters
  List<String> get destinations => List.unmodifiable(_destinations);
  DateTimeRange? get dates => _dates;
  int? get durationDays => _durationDays;
  Budget get budget => _budget;
  String get notes => _notes;
  String get travelParty => _travelParty;
  String get pace => _pace;
  bool get preferSurface => _preferSurface;
  String get stayType => _stayType;
  Set<String> get interests => Set.unmodifiable(_interests);
  bool get isDirty => _dirty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Check if form has any non-default values
  bool get hasChanges =>
      titleController.text.trim().isNotEmpty ||
      originController.text.trim().isNotEmpty ||
      _destinations.isNotEmpty ||
      _dates != null ||
      _durationDays != null ||
      _budget != Budget.medium ||
      _notes.isNotEmpty ||
      _travelParty != 'Solo' ||
      _pace != 'Balanced' ||
      _stayType != 'Hotel' ||
      _preferSurface != true ||
      _interests.isNotEmpty;

  /// Duration options for selection
  static const List<int> durationOptions = [2, 3, 4, 5, 7, 10, 14];

  /// Initialize with arguments from navigation
  void initializeFromArgs({String? ideaId, String? title, Set<String>? tags}) {
    if (title?.isNotEmpty == true && titleController.text.isEmpty) {
      titleController.text = title!;
      _setDirty();
    }
    if (tags?.isNotEmpty == true) {
      _interests.addAll(tags!);
      _setDirty();
    }
  }

  /// Load existing trip for editing
  Future<void> loadTripForEditing(String tripId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Fetch trip document from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(tripId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          // Populate form with existing trip data
          titleController.text = data['title'] as String? ?? '';
          originController.text = data['origin'] as String? ?? '';
          notesController.text = data['notes'] as String? ?? '';

          final destList = data['destinations'] as List?;
          if (destList != null) {
            _destinations.clear();
            _destinations.addAll(destList.cast<String>());
          }

          // Parse dates
          final startDateStr = data['startDate'] as String?;
          final endDateStr = data['endDate'] as String?;
          if (startDateStr != null && endDateStr != null) {
            try {
              final startDate = DateTime.parse(startDateStr);
              final endDate = DateTime.parse(endDateStr);
              _dates = DateTimeRange(start: startDate, end: endDate);
              _durationDays = endDate.difference(startDate).inDays;
            } catch (e) {
              // Ignore date parsing errors
            }
          }

          // Load other properties if they exist in metadata
          final meta = data['metadata'] as Map<String, dynamic>?;
          if (meta != null) {
            if (meta['budget'] != null) {
              _budget = Budget.values.firstWhere(
                (b) => b.name == meta['budget'],
                orElse: () => Budget.medium,
              );
            }
            if (meta['travelParty'] != null) {
              _travelParty = meta['travelParty'] as String;
            }
            if (meta['pace'] != null) {
              _pace = meta['pace'] as String;
            }
            if (meta['stayType'] != null) {
              _stayType = meta['stayType'] as String;
            }
            if (meta['preferSurface'] != null) {
              _preferSurface = meta['preferSurface'] as bool;
            }
            if (meta['interests'] != null) {
              _interests.clear();
              _interests.addAll((meta['interests'] as List).cast<String>());
            }
          }

          _notes = data['notes'] as String? ?? '';
          _dirty = false; // Not dirty since we just loaded
        }
      }
    } catch (e) {
      _setError('Failed to load trip: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load draft from persistent storage
  Future<void> loadDraft() async {
    try {
      final store = PlanTripStore.instance;
      await store.load();

      // Load saved values
      if (store.durationDays != null) {
        _durationDays = store.durationDays;
      }
      if (store.budget?.isNotEmpty == true) {
        _budget = Budget.values.firstWhere(
          (b) => b.name == store.budget,
          orElse: () => Budget.medium,
        );
      }
      if (store.notes?.isNotEmpty == true) {
        _notes = store.notes!;
        notesController.text = store.notes!;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load draft: $e');
    }
  }

  /// Set destinations
  void setDestinations(List<String> destinations) {
    _destinations.clear();
    _destinations.addAll(destinations);
    _setDirty();
  }

  /// Add destination
  void addDestination(String destination) {
    if (destination.trim().isNotEmpty &&
        !_destinations.contains(destination.trim())) {
      _destinations.add(destination.trim());
      _setDirty();
    }
  }

  /// Remove destination
  void removeDestination(String destination) {
    _destinations.remove(destination);
    _setDirty();
  }

  /// Set date range
  void setDates(DateTimeRange? dates) {
    _dates = dates;
    if (dates != null) {
      _durationDays = dates.end.difference(dates.start).inDays;
      if (_durationDays != null && _durationDays! <= 0) _durationDays = 1;
    }
    _setDirty();
  }

  /// Set duration in days
  void setDuration(int? days) {
    _durationDays = days;
    _setDirty();
  }

  /// Set budget
  void setBudget(Budget budget) {
    _budget = budget;
    _setDirty();
  }

  /// Set notes
  void setNotes(String notes) {
    _notes = notes;
    notesController.text = notes;
    _setDirty();
  }

  /// Set travel party
  void setTravelParty(String party) {
    _travelParty = party;
    _setDirty();
  }

  /// Set travel pace
  void setPace(String pace) {
    _pace = pace;
    _setDirty();
  }

  /// Set surface preference
  void setPreferSurface(bool prefer) {
    _preferSurface = prefer;
    _setDirty();
  }

  /// Set stay type
  void setStayType(String type) {
    _stayType = type;
    _setDirty();
  }

  /// Add interest
  void addInterest(String interest) {
    _interests.add(interest);
    _setDirty();
  }

  /// Remove interest
  void removeInterest(String interest) {
    _interests.remove(interest);
    _setDirty();
  }

  /// Clear all interests
  void clearInterests() {
    _interests.clear();
    _setDirty();
  }

  /// Generate trip and save to repository
  Future<String?> generateTrip({String? fallbackTitle}) async {
    if (_isLoading) return null;

    _setLoading(true);
    _clearError();

    try {
      // Check authentication first
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create trips');
      }

      // Create new trip
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      final start = _dates?.start ?? now;
      final end = _dates?.end ?? now.add(Duration(days: (_durationDays ?? 3)));

      final trip = Trip(
        id: newId,
        title: titleController.text.trim().isNotEmpty
            ? titleController.text.trim()
            : (fallbackTitle ?? 'New Trip'),
        startDate: start,
        endDate: end,
        destinations: _destinations,
        notes: _buildNotesString(),
      );

      await TripsRepository.instance.upsertTrip(trip);

      if (_destinations.isNotEmpty) {
        await TripsRepository.instance.addDestinations(newId, _destinations);
      }

      // Clear draft after successful creation
      await _clearDraft();

      return newId;
    } catch (e) {
      // Enhanced error logging
      debugPrint('Trip creation failed: $e');
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }
      _setError('Failed to create trip: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Save current state as draft
  Future<void> saveDraft() async {
    try {
      final store = PlanTripStore.instance;

      await store.setDuration(_durationDays);
      await store.setBudget(_budget.name);
      await store.setNotes(
        notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : _notes.trim(),
      );

      _dirty = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to save draft: $e');
    }
  }

  /// Clear draft and reset form
  Future<void> clearDraft() async {
    await _clearDraft();
    _resetForm();
  }

  /// Handle back navigation with save/discard logic
  Future<bool> handleBackNavigation() async {
    // For testing: use predetermined action
    if (_testAutoPopAction != null) {
      switch (_testAutoPopAction) {
        case 'save':
          await saveDraft();
          return true;
        case 'discard':
          await clearDraft();
          return true;
        default:
          return true;
      }
    }

    // Production behavior: auto-save if dirty
    if (_dirty && hasChanges) {
      await saveDraft();
    }

    return true;
  }

  /// Build notes string from all user inputs
  String _buildNotesString() {
    final notes = <String>[];

    if (_notes.isNotEmpty) {
      notes.add(_notes);
    }

    notes.add('Party: $_travelParty, Pace: $_pace, Stay: $_stayType');

    if (originController.text.trim().isNotEmpty) {
      notes.add('Origin: ${originController.text.trim()}');
    }

    if (_interests.isNotEmpty) {
      notes.add('Interests: ${_interests.join(', ')}');
    }

    if (_preferSurface) {
      notes.add('Prefers trains & road trips');
    }

    return notes.where((e) => e.isNotEmpty).join('\n');
  }

  /// Clear persistent draft storage
  Future<void> _clearDraft() async {
    await PlanTripStore.instance.clear();
  }

  /// Reset form to default state
  void _resetForm() {
    titleController.clear();
    originController.clear();
    notesController.clear();
    _destinations.clear();
    _dates = null;
    _durationDays = null;
    _budget = Budget.medium;
    _notes = '';
    _travelParty = 'Solo';
    _pace = 'Balanced';
    _preferSurface = true;
    _stayType = 'Hotel';
    _interests.clear();
    _dirty = false;
    notifyListeners();
  }

  /// Mark state as dirty and notify listeners
  void markDirty() {
    _setDirty();
  }

  /// Mark state as dirty
  void _setDirty() {
    _dirty = true;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Test-only methods (clearly separated)
  /// Set auto pop action for testing
  void setTestAutoPopAction(String? action) {
    _testAutoPopAction = action;
  }

  /// Set duration for testing
  void setTestDuration(int days) {
    setDuration(days);
  }

  /// Set budget for testing
  void setTestBudget(Budget budget) {
    setBudget(budget);
  }

  /// Set notes for testing
  void setTestNotes(String notes) {
    setNotes(notes);
  }

  @override
  void dispose() {
    titleController.dispose();
    originController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
