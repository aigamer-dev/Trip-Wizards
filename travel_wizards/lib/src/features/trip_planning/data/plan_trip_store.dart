import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlanTripStore {
  PlanTripStore._internal();
  static final PlanTripStore instance = PlanTripStore._internal();

  static const _keyDuration = 'plan_trip_duration_days';
  static const _keyBudget = 'plan_trip_budget'; // 'low' | 'medium' | 'high'
  static const _keyNotes = 'plan_trip_notes';
  static const _keyTitle = 'plan_trip_title';
  static const _keyOrigin = 'plan_trip_origin';
  static const _keyDestinations = 'plan_trip_destinations';
  static const _keyStartDate = 'plan_trip_start_date';
  static const _keyEndDate = 'plan_trip_end_date';
  static const _keyTravelParty = 'plan_trip_travel_party';
  static const _keyPace = 'plan_trip_pace';
  static const _keyStayType = 'plan_trip_stay_type';
  static const _keyInterests = 'plan_trip_interests';
  static const _keyPreferSurface = 'plan_trip_prefer_surface';

  int? _durationDays;
  String? _budget;
  String? _notes;
  String? _title;
  String? _origin;
  List<String>? _destinations;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _travelParty;
  String? _pace;
  String? _stayType;
  List<String>? _interests;
  bool? _preferSurface;

  int? get durationDays => _durationDays;
  String? get budget => _budget;
  String? get notes => _notes;
  String? get title => _title;
  String? get origin => _origin;
  List<String>? get destinations => _destinations;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get travelParty => _travelParty;
  String? get pace => _pace;
  String? get stayType => _stayType;
  List<String>? get interests => _interests;
  bool? get preferSurface => _preferSurface;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _durationDays = prefs.getInt(_keyDuration);
    _budget = prefs.getString(_keyBudget);
    _notes = prefs.getString(_keyNotes);
    _title = prefs.getString(_keyTitle);
    _origin = prefs.getString(_keyOrigin);

    final destJson = prefs.getString(_keyDestinations);
    _destinations = destJson != null && destJson.isNotEmpty
        ? (jsonDecode(destJson) as List).cast<String>()
        : null;

    final startDateStr = prefs.getString(_keyStartDate);
    _startDate = startDateStr != null ? DateTime.tryParse(startDateStr) : null;

    final endDateStr = prefs.getString(_keyEndDate);
    _endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;

    _travelParty = prefs.getString(_keyTravelParty);
    _pace = prefs.getString(_keyPace);
    _stayType = prefs.getString(_keyStayType);

    final interestsJson = prefs.getString(_keyInterests);
    _interests = interestsJson != null && interestsJson.isNotEmpty
        ? (jsonDecode(interestsJson) as List).cast<String>()
        : null;

    _preferSurface = prefs.getBool(_keyPreferSurface);
  }

  Future<void> setDuration(int? days) async {
    _durationDays = days;
    final prefs = await SharedPreferences.getInstance();
    if (days == null) {
      await prefs.remove(_keyDuration);
    } else {
      await prefs.setInt(_keyDuration, days);
    }
  }

  Future<void> setBudget(String? level) async {
    _budget = level;
    final prefs = await SharedPreferences.getInstance();
    if (level == null || level.isEmpty) {
      await prefs.remove(_keyBudget);
    } else {
      await prefs.setString(_keyBudget, level);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDuration);
    await prefs.remove(_keyBudget);
    await prefs.remove(_keyNotes);
    await prefs.remove(_keyTitle);
    await prefs.remove(_keyOrigin);
    await prefs.remove(_keyDestinations);
    await prefs.remove(_keyStartDate);
    await prefs.remove(_keyEndDate);
    await prefs.remove(_keyTravelParty);
    await prefs.remove(_keyPace);
    await prefs.remove(_keyStayType);
    await prefs.remove(_keyInterests);
    await prefs.remove(_keyPreferSurface);

    _durationDays = null;
    _budget = null;
    _notes = null;
    _title = null;
    _origin = null;
    _destinations = null;
    _startDate = null;
    _endDate = null;
    _travelParty = null;
    _pace = null;
    _stayType = null;
    _interests = null;
    _preferSurface = null;
  }

  Future<void> setNotes(String? value) async {
    _notes = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyNotes);
    } else {
      await prefs.setString(_keyNotes, value);
    }
  }

  Future<void> setTitle(String? value) async {
    _title = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyTitle);
    } else {
      await prefs.setString(_keyTitle, value);
    }
  }

  Future<void> setOrigin(String? value) async {
    _origin = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyOrigin);
    } else {
      await prefs.setString(_keyOrigin, value);
    }
  }

  Future<void> setDestinations(List<String>? value) async {
    _destinations = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyDestinations);
    } else {
      await prefs.setString(_keyDestinations, jsonEncode(value));
    }
  }

  Future<void> setDates(DateTime? start, DateTime? end) async {
    _startDate = start;
    _endDate = end;
    final prefs = await SharedPreferences.getInstance();
    if (start == null) {
      await prefs.remove(_keyStartDate);
    } else {
      await prefs.setString(_keyStartDate, start.toIso8601String());
    }
    if (end == null) {
      await prefs.remove(_keyEndDate);
    } else {
      await prefs.setString(_keyEndDate, end.toIso8601String());
    }
  }

  Future<void> setTravelParty(String? value) async {
    _travelParty = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyTravelParty);
    } else {
      await prefs.setString(_keyTravelParty, value);
    }
  }

  Future<void> setPace(String? value) async {
    _pace = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyPace);
    } else {
      await prefs.setString(_keyPace, value);
    }
  }

  Future<void> setStayType(String? value) async {
    _stayType = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyStayType);
    } else {
      await prefs.setString(_keyStayType, value);
    }
  }

  Future<void> setInterests(List<String>? value) async {
    _interests = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyInterests);
    } else {
      await prefs.setString(_keyInterests, jsonEncode(value));
    }
  }

  Future<void> setPreferSurface(bool? value) async {
    _preferSurface = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_keyPreferSurface);
    } else {
      await prefs.setBool(_keyPreferSurface, value);
    }
  }
}
