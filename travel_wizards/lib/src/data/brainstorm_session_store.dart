import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrainstormSessionStore extends ChangeNotifier {
  BrainstormSessionStore._();
  static final BrainstormSessionStore instance = BrainstormSessionStore._();

  static const _keyActive = 'brainstorm_session_active';
  static const _keyStartedAt = 'brainstorm_session_started_at';

  bool _active = false;
  DateTime? _startedAt;

  bool get isActive => _active;
  DateTime? get startedAt => _startedAt;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _active = prefs.getBool(_keyActive) ?? false;
    final ts = prefs.getString(_keyStartedAt);
    if (ts != null) {
      _startedAt = DateTime.tryParse(ts);
    }
    notifyListeners();
  }

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    _active = true;
    _startedAt = DateTime.now();
    await prefs.setBool(_keyActive, true);
    await prefs.setString(_keyStartedAt, _startedAt!.toIso8601String());
    notifyListeners();
  }

  Future<void> end() async {
    final prefs = await SharedPreferences.getInstance();
    _active = false;
    _startedAt = null;
    await prefs.remove(_keyActive);
    await prefs.remove(_keyStartedAt);
    notifyListeners();
  }
}
