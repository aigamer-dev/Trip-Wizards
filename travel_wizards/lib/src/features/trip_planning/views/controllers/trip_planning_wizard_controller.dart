import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/models/trip.dart';

/// Represents different steps in the trip planning wizard
enum TripPlanningStep {
  basics, // Title, destinations, dates
  preferences, // Travel party, pace, budget, stay type
  details, // Notes, interests, transportation
  review, // Summary and confirmation
}

/// Validation state for each step
class StepValidation {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const StepValidation({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  const StepValidation.valid() : this(isValid: true);

  const StepValidation.invalid(List<String> errors)
    : this(isValid: false, errors: errors);

  StepValidation withWarnings(List<String> warnings) {
    return StepValidation(isValid: isValid, errors: errors, warnings: warnings);
  }
}

/// Manages the state and validation for the trip planning wizard
class TripPlanningWizardController extends ChangeNotifier {
  // Current state
  TripPlanningStep _currentStep = TripPlanningStep.basics;

  // Form data
  String _title = '';
  final List<String> _destinations = [];
  DateTimeRange? _dates;
  int? _durationDays;
  String _travelParty = 'Solo';
  String _pace = 'Balanced';
  String _budget = 'medium';
  String _stayType = 'Hotel';
  bool _preferSurface = true;
  final Set<String> _interests = {};
  String _notes = '';
  String _origin = '';

  // Getters
  TripPlanningStep get currentStep => _currentStep;
  String get title => _title;
  List<String> get destinations => List.unmodifiable(_destinations);
  DateTimeRange? get dates => _dates;
  int? get durationDays => _durationDays;
  String get travelParty => _travelParty;
  String get pace => _pace;
  String get budget => _budget;
  String get stayType => _stayType;
  bool get preferSurface => _preferSurface;
  Set<String> get interests => Set.unmodifiable(_interests);
  String get notes => _notes;
  String get origin => _origin;

  /// Update title and trigger validation
  void updateTitle(String title) {
    _title = title.trim();
    notifyListeners();
  }

  /// Add a destination
  void addDestination(String destination) {
    if (destination.trim().isNotEmpty &&
        !_destinations.contains(destination.trim())) {
      _destinations.add(destination.trim());
      notifyListeners();
    }
  }

  /// Remove a destination
  void removeDestination(String destination) {
    _destinations.remove(destination);
    notifyListeners();
  }

  /// Update dates
  void updateDates(DateTimeRange? dates) {
    _dates = dates;
    if (dates != null) {
      _durationDays = dates.end.difference(dates.start).inDays;
      if (_durationDays! <= 0) _durationDays = 1;
    }
    notifyListeners();
  }

  /// Update duration (when not using date picker)
  void updateDuration(int? days) {
    _durationDays = days;
    notifyListeners();
  }

  /// Update travel party
  void updateTravelParty(String party) {
    _travelParty = party;
    notifyListeners();
  }

  /// Update pace
  void updatePace(String pace) {
    _pace = pace;
    notifyListeners();
  }

  /// Update budget
  void updateBudget(String budget) {
    _budget = budget;
    notifyListeners();
  }

  /// Update stay type
  void updateStayType(String stayType) {
    _stayType = stayType;
    notifyListeners();
  }

  /// Update surface preference
  void updatePreferSurface(bool prefer) {
    _preferSurface = prefer;
    notifyListeners();
  }

  /// Toggle interest
  void toggleInterest(String interest) {
    if (_interests.contains(interest)) {
      _interests.remove(interest);
    } else {
      _interests.add(interest);
    }
    notifyListeners();
  }

  /// Update notes
  void updateNotes(String notes) {
    _notes = notes.trim();
    notifyListeners();
  }

  /// Update origin
  void updateOrigin(String origin) {
    _origin = origin.trim();
    notifyListeners();
  }

  /// Validate current step
  StepValidation validateCurrentStep() {
    return validateStep(_currentStep);
  }

  /// Validate specific step
  StepValidation validateStep(TripPlanningStep step) {
    switch (step) {
      case TripPlanningStep.basics:
        return _validateBasics();
      case TripPlanningStep.preferences:
        return _validatePreferences();
      case TripPlanningStep.details:
        return _validateDetails();
      case TripPlanningStep.review:
        return _validateReview();
    }
  }

  StepValidation _validateBasics() {
    final errors = <String>[];
    final warnings = <String>[];

    if (_title.isEmpty) {
      errors.add('Trip title is required');
    }

    if (_destinations.isEmpty) {
      errors.add('At least one destination is required');
    }

    if (_dates == null && _durationDays == null) {
      errors.add('Trip dates or duration must be specified');
    }

    if (_dates != null &&
        _dates!.start.isBefore(
          DateTime.now().subtract(const Duration(days: 1)),
        )) {
      warnings.add('Trip start date is in the past');
    }

    if (_durationDays != null && _durationDays! > 30) {
      warnings.add('Long trips (>30 days) may require additional planning');
    }

    return StepValidation(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  StepValidation _validatePreferences() {
    // Preferences are mostly optional, but we can provide guidance
    final warnings = <String>[];

    if (_travelParty == 'Family' && _stayType == 'Hostel') {
      warnings.add(
        'Consider hotels or family-friendly accommodations for family trips',
      );
    }

    if (_pace == 'Relaxed' && _destinations.length > 3) {
      warnings.add('Consider fewer destinations for a relaxed pace');
    }

    return StepValidation.valid().withWarnings(warnings);
  }

  StepValidation _validateDetails() {
    final warnings = <String>[];

    if (_interests.isEmpty) {
      warnings.add(
        'Adding interests helps create better itinerary suggestions',
      );
    }

    if (_origin.isEmpty) {
      warnings.add('Origin helps with transportation planning');
    }

    return StepValidation.valid().withWarnings(warnings);
  }

  StepValidation _validateReview() {
    // Final validation - check all required fields
    final errors = <String>[];

    final basicsValidation = _validateBasics();
    errors.addAll(basicsValidation.errors);

    return StepValidation(isValid: errors.isEmpty, errors: errors);
  }

  /// Check if we can proceed to next step
  bool canProceedToNext() {
    return validateCurrentStep().isValid;
  }

  /// Go to next step
  bool goToNextStep() {
    if (!canProceedToNext()) return false;

    switch (_currentStep) {
      case TripPlanningStep.basics:
        _currentStep = TripPlanningStep.preferences;
        break;
      case TripPlanningStep.preferences:
        _currentStep = TripPlanningStep.details;
        break;
      case TripPlanningStep.details:
        _currentStep = TripPlanningStep.review;
        break;
      case TripPlanningStep.review:
        return false; // Can't go beyond review
    }

    notifyListeners();
    return true;
  }

  /// Go to previous step
  bool goToPreviousStep() {
    switch (_currentStep) {
      case TripPlanningStep.basics:
        return false; // Can't go back from first step
      case TripPlanningStep.preferences:
        _currentStep = TripPlanningStep.basics;
        break;
      case TripPlanningStep.details:
        _currentStep = TripPlanningStep.preferences;
        break;
      case TripPlanningStep.review:
        _currentStep = TripPlanningStep.details;
        break;
    }

    notifyListeners();
    return true;
  }

  /// Jump to specific step (only if previous steps are valid)
  bool goToStep(TripPlanningStep step) {
    // Check if all steps before the target step are valid
    final steps = TripPlanningStep.values;
    final targetIndex = steps.indexOf(step);

    for (int i = 0; i < targetIndex; i++) {
      if (!validateStep(steps[i]).isValid) {
        return false;
      }
    }

    _currentStep = step;
    notifyListeners();
    return true;
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    switch (_currentStep) {
      case TripPlanningStep.basics:
        return 0.25;
      case TripPlanningStep.preferences:
        return 0.5;
      case TripPlanningStep.details:
        return 0.75;
      case TripPlanningStep.review:
        return 1.0;
    }
  }

  /// Create Trip object from current state
  Trip createTrip() {
    final now = DateTime.now();
    final startDate = _dates?.start ?? now;
    final endDate = _dates?.end ?? now.add(Duration(days: _durationDays ?? 3));

    return Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _title.isNotEmpty ? _title : 'New Trip',
      startDate: startDate,
      endDate: endDate,
      destinations: _destinations,
      notes: [
        if (_notes.isNotEmpty) _notes,
        'Party: $_travelParty, Pace: $_pace, Budget: $_budget, Stay: $_stayType',
        if (_origin.isNotEmpty) 'Origin: $_origin',
        if (_interests.isNotEmpty) 'Interests: ${_interests.join(', ')}',
        if (_preferSurface) 'Prefers trains & road trips',
      ].where((e) => e.isNotEmpty).join('\n'),
    );
  }

  /// Reset to initial state
  void reset() {
    _currentStep = TripPlanningStep.basics;
    _title = '';
    _destinations.clear();
    _dates = null;
    _durationDays = null;
    _travelParty = 'Solo';
    _pace = 'Balanced';
    _budget = 'medium';
    _stayType = 'Hotel';
    _preferSurface = true;
    _interests.clear();
    _notes = '';
    _origin = '';
    notifyListeners();
  }

  /// Load data from args (for prefilling)
  void loadFromArgs({String? title, Set<String>? tags}) {
    if (title != null && title.isNotEmpty && _title.isEmpty) {
      _title = title;
    }
    if (tags != null && tags.isNotEmpty) {
      _interests.addAll(tags);
    }
    notifyListeners();
  }
}
