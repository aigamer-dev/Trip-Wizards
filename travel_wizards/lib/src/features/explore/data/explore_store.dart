import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/shared/services/error_handling_service.dart';

/// Stores Explore page UI state such as selected filters and saved ideas.
class ExploreStore extends ChangeNotifier {
  ExploreStore._internal();
  static final ExploreStore instance = ExploreStore._internal();

  static const _keySelectedTags = 'explore_selected_tags';
  static const _keySavedIdeaIds = 'explore_saved_ideas';
  static const _keyFilterBudget = 'explore_filter_budget'; // low|medium|high
  static const _keyFilterDuration = 'explore_filter_duration'; // 2-3|4-5|6+

  final Set<String> _selectedTags = <String>{};
  final Set<String> _savedIdeaIds = <String>{};
  String? _filterBudget;
  String? _filterDuration;

  Set<String> get selectedTags => Set.unmodifiable(_selectedTags);
  Set<String> get savedIdeaIds => Set.unmodifiable(_savedIdeaIds);
  String? get filterBudget => _filterBudget;
  String? get filterDuration => _filterDuration;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final tagsJson = prefs.getString(_keySelectedTags);
    final savedJson = prefs.getString(_keySavedIdeaIds);
    _filterBudget = prefs.getString(_keyFilterBudget);
    _filterDuration = prefs.getString(_keyFilterDuration);
    _selectedTags
      ..clear()
      ..addAll(_decodeStringSet(tagsJson));
    _savedIdeaIds
      ..clear()
      ..addAll(_decodeStringSet(savedJson));
    notifyListeners();
  }

  Future<void> toggleTag(String tag) async {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedTags, jsonEncode(_selectedTags.toList()));
  }

  Future<void> setTags(Set<String> tags) async {
    _selectedTags
      ..clear()
      ..addAll(tags);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedTags, jsonEncode(_selectedTags.toList()));
  }

  Future<void> toggleSaved(String id) async {
    if (_savedIdeaIds.contains(id)) {
      _savedIdeaIds.remove(id);
    } else {
      _savedIdeaIds.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedIdeaIds, jsonEncode(_savedIdeaIds.toList()));
  }

  bool isSaved(String id) => _savedIdeaIds.contains(id);

  Future<void> setFilterBudget(String? value) async {
    _filterBudget = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyFilterBudget);
    } else {
      await prefs.setString(_keyFilterBudget, value);
    }
  }

  Future<void> setFilterDuration(String? value) async {
    _filterDuration = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyFilterDuration);
    } else {
      await prefs.setString(_keyFilterDuration, value);
    }
  }

  static List<String> _decodeStringSet(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return const <String>[];
    try {
      final list = jsonDecode(jsonStr);
      if (list is List) {
        return list.whereType<String>().toList(growable: false);
      }
    } catch (error) {
      // Log parse errors but continue with empty list
      ErrorHandlingService.instance.handleError(
        error,
        context: 'ExploreStore String Set Decode',
        showToUser: false,
      );
    }
    return const <String>[];
  }
}
