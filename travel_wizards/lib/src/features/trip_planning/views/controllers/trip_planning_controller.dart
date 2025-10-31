import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_wizards/src/shared/models/trip.dart';
import 'package:travel_wizards/src/shared/services/trips_repository.dart';
import 'package:travel_wizards/src/features/trip_planning/data/plan_trip_store.dart';

/// Represents different steps in the trip planning wizard
enum TripPlanningStep {
  style, // Step 1: Trip Style (Solo/Group/Family/Couple/Business)
  details, // Step 2: Trip Details (Travel prefs, origin/destination, dates, buddies)
  stayActivities, // Step 3: Stay & Activities (Accommodation, activities, budget, itinerary)
  review, // Step 4: Review & Generate
}

/// Budget options for trip planning
enum Budget { low, medium, high }

/// Trip planning controller that manages state without global variables
class TripPlanningController extends ChangeNotifier {
  // Step management
  TripPlanningStep _currentStep = TripPlanningStep.style;

  // Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // Step 1: Trip Style
  String _tripStyle = 'Solo'; // Solo, Group, Family, Couple, Business
  // Business fields
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController businessPurposeController =
      TextEditingController();
  final TextEditingController businessRequirementsController =
      TextEditingController();
  // Family fields
  int _adultsCount = 1;
  int _teenagersCount = 0;
  int _childrenCount = 0;
  int _toddlersCount = 0;

  // Step 2: Trip Details
  String _travelPreference = 'Flight'; // Flight, Train, Bus, Car
  final List<String> _destinations = [];
  DateTimeRange? _dates;
  final List<String> _buddies = [];
  final TextEditingController specialRequirementsController =
      TextEditingController();

  // Step 3: Stay & Activities
  String _accommodationType = 'Hotel'; // Hotel, Airbnb, Hostel
  int? _starRating;
  final Set<String> _selectedActivities = {};
  Budget _budget = Budget.medium;
  String _itineraryType = 'Flexible'; // Flexible, Fixed

  // State
  int? _durationDays;
  String _notes = '';
  bool _dirty = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Legacy fields (for backward compatibility)
  String _travelParty = 'Solo';
  String _pace = 'Balanced';
  bool _preferSurface = true;
  String _stayType = 'Hotel';
  final Set<String> _interests = {};

  // Test-only properties (separated from production code)
  String? _testAutoPopAction;

  // Getters
  TripPlanningStep get currentStep => _currentStep;
  List<String> get destinations => List.unmodifiable(_destinations);
  DateTimeRange? get dates => _dates;
  int? get durationDays => _durationDays;
  Budget get budget => _budget;
  String get notes => _notes;
  bool get isDirty => _dirty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Step 1 getters
  String get tripStyle => _tripStyle;
  String get companyName => companyNameController.text;
  String get businessPurpose => businessPurposeController.text;
  String get businessRequirements => businessRequirementsController.text;
  int get adultsCount => _adultsCount;
  int get teenagersCount => _teenagersCount;
  int get childrenCount => _childrenCount;
  int get toddlersCount => _toddlersCount;

  // Step 2 getters
  String get travelPreference => _travelPreference;
  List<String> get buddies => List.unmodifiable(_buddies);
  String get specialRequirements => specialRequirementsController.text;

  // Step 3 getters
  String get accommodationType => _accommodationType;
  int? get starRating => _starRating;
  Set<String> get selectedActivities => Set.unmodifiable(_selectedActivities);
  String get itineraryType => _itineraryType;

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

  // Step navigation methods
  void nextStep() {
    switch (_currentStep) {
      case TripPlanningStep.style:
        _currentStep = TripPlanningStep.details;
        break;
      case TripPlanningStep.details:
        _currentStep = TripPlanningStep.stayActivities;
        break;
      case TripPlanningStep.stayActivities:
        _currentStep = TripPlanningStep.review;
        break;
      case TripPlanningStep.review:
        // Stay on review step
        break;
    }
    notifyListeners();
  }

  void previousStep() {
    switch (_currentStep) {
      case TripPlanningStep.style:
        // Stay on first step
        break;
      case TripPlanningStep.details:
        _currentStep = TripPlanningStep.style;
        break;
      case TripPlanningStep.stayActivities:
        _currentStep = TripPlanningStep.details;
        break;
      case TripPlanningStep.review:
        _currentStep = TripPlanningStep.stayActivities;
        break;
    }
    notifyListeners();
  }

  void goToStep(TripPlanningStep step) {
    _currentStep = step;
    notifyListeners();
  }

  // Step 1 setters
  void setTripStyle(String style) {
    _tripStyle = style;
    _setDirty();
  }

  void setAdultsCount(int count) {
    _adultsCount = count.clamp(0, 20);
    _setDirty();
  }

  void setTeenagersCount(int count) {
    _teenagersCount = count.clamp(0, 20);
    _setDirty();
  }

  void setChildrenCount(int count) {
    _childrenCount = count.clamp(0, 20);
    _setDirty();
  }

  void setToddlersCount(int count) {
    _toddlersCount = count.clamp(0, 20);
    _setDirty();
  }

  // Step 2 setters
  void setTravelPreference(String preference) {
    _travelPreference = preference;
    _setDirty();
  }

  void addBuddy(String buddy) {
    if (!_buddies.contains(buddy)) {
      _buddies.add(buddy);
      _setDirty();
    }
  }

  void removeBuddy(String buddy) {
    _buddies.remove(buddy);
    _setDirty();
  }

  // Step 3 setters
  void setAccommodationType(String type) {
    _accommodationType = type;
    _setDirty();
  }

  void setStarRating(int? rating) {
    _starRating = rating;
    _setDirty();
  }

  void addSelectedActivity(String activity) {
    _selectedActivities.add(activity);
    _setDirty();
  }

  void removeSelectedActivity(String activity) {
    _selectedActivities.remove(activity);
    _setDirty();
  }

  void setItineraryType(String type) {
    _itineraryType = type;
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
        ownerId: '', // Will be set by repository
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

  /// Generate trip from ADK response
  Future<String?> generateTripFromAdkResponse(List<String> responses) async {
    if (_isLoading) return null;

    _setLoading(true);
    _clearError();

    try {
      // Check authentication first
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create trips');
      }

      // Combine all responses
      final fullResponse = responses.join('\n');

      // Parse the ADK response to extract itinerary information
      // For now, create a basic trip structure - this can be enhanced to parse structured itinerary data
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      final start = _dates?.start ?? now;
      final end = _dates?.end ?? now.add(Duration(days: (_durationDays ?? 3)));

      final trip = Trip(
        id: newId,
        title: titleController.text.trim().isNotEmpty
            ? titleController.text.trim()
            : (_destinations.isNotEmpty
                  ? 'Trip to ${_destinations.join(", ")}'
                  : 'Generated Trip'),
        startDate: start,
        endDate: end,
        destinations: _destinations,
        notes: _buildNotesStringWithItinerary(fullResponse),
        ownerId: '', // Will be set by repository
      );

      await TripsRepository.instance.upsertTrip(trip);

      if (_destinations.isNotEmpty) {
        await TripsRepository.instance.addDestinations(newId, _destinations);
      }

      // Clear draft after successful creation
      await _clearDraft();

      return newId;
    } catch (e) {
      debugPrint('Trip creation from ADK failed: $e');
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }
      _setError('Failed to create trip from AI response: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  String _buildNotesStringWithItinerary(String adkResponse) {
    final buffer = StringBuffer();

    // Add original notes
    if (notesController.text.trim().isNotEmpty) {
      buffer.writeln('Notes: ${notesController.text.trim()}');
      buffer.writeln();
    }

    // Add trip planning details
    buffer.writeln('Trip Details:');
    buffer.writeln('- Style: $_tripStyle');
    buffer.writeln('- Travel: $_travelPreference');
    buffer.writeln('- Accommodation: $_accommodationType');
    if (_starRating != null) {
      buffer.writeln('- Star Rating: $_starRating');
    }
    buffer.writeln('- Budget: ${_budget.name}');
    buffer.writeln('- Itinerary Type: $_itineraryType');
    if (_selectedActivities.isNotEmpty) {
      buffer.writeln('- Activities: ${_selectedActivities.join(", ")}');
    }
    buffer.writeln();

    // Add AI-generated itinerary
    buffer.writeln('AI-Generated Itinerary:');
    buffer.writeln(adkResponse);

    return buffer.toString();
  }

  // Validation Methods
  String? validateStep1() {
    if (_tripStyle.isEmpty) {
      return 'Please select a trip style';
    }

    // Business validation
    if (_tripStyle == 'Business') {
      if (companyNameController.text.trim().isEmpty) {
        return 'Company name is required for business trips';
      }
      if (businessPurposeController.text.trim().isEmpty) {
        return 'Business purpose is required for business trips';
      }
    }

    // Family validation
    if (_tripStyle == 'Family') {
      if (_adultsCount < 1) {
        return 'At least one adult is required for family trips';
      }
    }

    return null; // Valid
  }

  String? validateStep2() {
    if (originController.text.trim().isEmpty) {
      return 'Please enter an origin location';
    }

    if (destinationController.text.trim().isEmpty) {
      return 'Please enter a destination location';
    }

    if (_dates == null) {
      return 'Please select travel dates';
    }

    // Validate date range
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_dates!.start.isBefore(today)) {
      return 'Start date cannot be in the past';
    }

    if (_dates!.end.isBefore(_dates!.start)) {
      return 'End date must be after start date';
    }

    return null; // Valid
  }

  String? validateStep3() {
    // Budget validation
    // Note: Budget is always set to a default value, so this should always pass
    // But we can add additional validation if needed

    return null; // Valid
  }

  String? validateCurrentStep() {
    switch (_currentStep) {
      case TripPlanningStep.style:
        return validateStep1();
      case TripPlanningStep.details:
        return validateStep2();
      case TripPlanningStep.stayActivities:
        return validateStep3();
      case TripPlanningStep.review:
        // Review step doesn't need validation as it's just a summary
        return null;
    }
  }

  bool canProceedToNextStep() {
    return validateCurrentStep() == null;
  }

  @override
  void dispose() {
    titleController.dispose();
    originController.dispose();
    destinationController.dispose();
    notesController.dispose();
    companyNameController.dispose();
    businessPurposeController.dispose();
    businessRequirementsController.dispose();
    specialRequirementsController.dispose();
    super.dispose();
  }
}
