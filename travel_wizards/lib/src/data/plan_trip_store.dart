import 'package:shared_preferences/shared_preferences.dart';

class PlanTripStore {
  PlanTripStore._internal();
  static final PlanTripStore instance = PlanTripStore._internal();

  static const _keyDuration = 'plan_trip_duration_days';
  static const _keyBudget = 'plan_trip_budget'; // 'low' | 'medium' | 'high'
  static const _keyNotes = 'plan_trip_notes';

  int? _durationDays;
  String? _budget;
  String? _notes;

  int? get durationDays => _durationDays;
  String? get budget => _budget;
  String? get notes => _notes;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _durationDays = prefs.getInt(_keyDuration);
    _budget = prefs.getString(_keyBudget);
    _notes = prefs.getString(_keyNotes);
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
    _durationDays = null;
    _budget = null;
    _notes = null;
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
}
