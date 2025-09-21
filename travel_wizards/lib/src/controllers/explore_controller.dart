import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:travel_wizards/src/data/explore_store.dart';
import 'package:travel_wizards/src/data/ideas_remote_repository.dart';
import 'package:travel_wizards/src/data/ideas_repository.dart';
import 'package:travel_wizards/src/services/error_handling_service.dart';

/// Enhanced explore controller with performance optimizations including:
/// - Search result caching with TTL
/// - Query debouncing to prevent excessive API calls
/// - Pagination support for large datasets
/// - Optimized filter state management
/// - Loading state management
class ExploreController extends ChangeNotifier {
  ExploreController({
    required ExploreStore store,
    required IdeasRepository localRepo,
    required IdeasRemoteRepository remoteRepo,
  }) : _store = store,
       _localRepo = localRepo,
       _remoteRepo = remoteRepo {
    _store.addListener(_onStoreChanged);
  }

  final ExploreStore _store;
  final IdeasRepository _localRepo;
  final IdeasRemoteRepository _remoteRepo;

  // Search and pagination state
  List<TravelIdea> _currentResults = [];
  bool _isLoading = false;
  String? _lastQuery;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  // Debouncing
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // Caching
  final Map<String, _CachedResult> _cache = {};
  static const Duration _cacheTTL = Duration(minutes: 5);

  // Getters
  List<TravelIdea> get currentResults => List.unmodifiable(_currentResults);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isEmpty => _currentResults.isEmpty && !_isLoading;
  int get totalResults => _currentResults.length;

  // Filter getters (delegated to store)
  Set<String> get selectedTags => _store.selectedTags;
  String? get filterBudget => _store.filterBudget;
  String? get filterDuration => _store.filterDuration;

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Performs a search with debouncing and caching
  Future<void> search({
    String? query,
    bool useRemote = false,
    bool clearResults = true,
  }) async {
    // Cancel any pending debounced search
    _debounceTimer?.cancel();

    if (clearResults) {
      _currentPage = 1;
      _hasMore = true;
    }

    // Use debouncing for text queries
    if (query != null && query.isNotEmpty) {
      _debounceTimer = Timer(_debounceDuration, () {
        _performSearch(
          query: query,
          useRemote: useRemote,
          clearResults: clearResults,
        );
      });
    } else {
      // No debouncing for filter-only searches
      await _performSearch(
        query: query,
        useRemote: useRemote,
        clearResults: clearResults,
      );
    }
  }

  /// Loads the next page of results (pagination)
  Future<void> loadNextPage({bool useRemote = false}) async {
    if (_isLoading || !_hasMore) return;

    _currentPage++;
    await _performSearch(
      query: _lastQuery,
      useRemote: useRemote,
      clearResults: false,
    );
  }

  /// Refreshes current search results
  Future<void> refresh({bool useRemote = false}) async {
    _clearCache();
    await search(query: _lastQuery, useRemote: useRemote);
  }

  /// Clears all results and resets state
  void clearResults() {
    _currentResults.clear();
    _error = null;
    _hasMore = true;
    _currentPage = 1;
    _lastQuery = null;
    notifyListeners();
  }

  /// Immediate filter-based search (no debouncing)
  Future<void> applyFilters({bool useRemote = false}) async {
    await _performSearch(
      query: _lastQuery,
      useRemote: useRemote,
      clearResults: true,
    );
  }

  Future<void> _performSearch({
    String? query,
    required bool useRemote,
    required bool clearResults,
  }) async {
    if (clearResults) {
      _currentResults.clear();
      _error = null;
      _currentPage = 1;
      _hasMore = true;
    }

    _lastQuery = query;
    _isLoading = true;
    notifyListeners();

    try {
      // Create cache key based on search parameters
      final cacheKey = _createCacheKey(query, _currentPage);

      // Check cache first
      final cachedResult = _getCachedResult(cacheKey);
      if (cachedResult != null) {
        _handleSearchResult(cachedResult.ideas, clearResults);
        return;
      }

      List<TravelIdea> results;

      if (useRemote) {
        results = await _remoteRepo.search(
          query: query,
          tags: _store.selectedTags,
          budget: _store.filterBudget,
          durationBucket: _store.filterDuration,
        );
      } else {
        results = _localRepo.search(
          query: query,
          tags: _store.selectedTags,
          budget: _store.filterBudget,
          durationBucket: _store.filterDuration,
        );

        // Simulate pagination for local results
        final startIndex = (_currentPage - 1) * _pageSize;
        final endIndex = min(startIndex + _pageSize, results.length);

        if (startIndex >= results.length) {
          results = [];
          _hasMore = false;
        } else {
          results = results.sublist(startIndex, endIndex);
          _hasMore = endIndex < results.length;
        }
      }

      // Cache the result
      _cacheResult(cacheKey, results);

      _handleSearchResult(results, clearResults);
    } catch (error, stackTrace) {
      _error = ErrorHandlingService.instance.getUserFriendlyMessage(error);
      ErrorHandlingService.instance.handleError(
        error,
        stackTrace: stackTrace,
        context: 'ExploreController.search',
        showToUser: false,
      );

      // Fallback to local search on remote error
      if (useRemote) {
        try {
          final fallbackResults = _localRepo.search(
            query: query,
            tags: _store.selectedTags,
            budget: _store.filterBudget,
            durationBucket: _store.filterDuration,
          );
          _handleSearchResult(fallbackResults, clearResults);
          _error = null; // Clear error since fallback succeeded
        } catch (fallbackError) {
          // Keep the original error
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleSearchResult(List<TravelIdea> results, bool clearResults) {
    if (clearResults) {
      _currentResults = results;
    } else {
      _currentResults.addAll(results);
    }

    // Update pagination state
    if (results.length < _pageSize) {
      _hasMore = false;
    }

    _error = null;
  }

  void _onStoreChanged() {
    // Store changed (filters), trigger immediate search without debouncing
    if (_lastQuery != null ||
        _store.selectedTags.isNotEmpty ||
        _store.filterBudget != null ||
        _store.filterDuration != null) {
      applyFilters();
    }
  }

  String _createCacheKey(String? query, int page) {
    final filters = [
      query ?? '',
      _store.selectedTags.join(','),
      _store.filterBudget ?? '',
      _store.filterDuration ?? '',
      page.toString(),
    ];
    return filters.join('|');
  }

  void _cacheResult(String key, List<TravelIdea> ideas) {
    _cache[key] = _CachedResult(ideas: ideas, timestamp: DateTime.now());

    // Clean up expired cache entries
    _cleanExpiredCache();
  }

  _CachedResult? _getCachedResult(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    if (DateTime.now().difference(cached.timestamp) > _cacheTTL) {
      _cache.remove(key);
      return null;
    }

    return cached;
  }

  void _cleanExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) {
      return now.difference(value.timestamp) > _cacheTTL;
    });
  }

  void _clearCache() {
    _cache.clear();
  }

  // Filter management methods
  Future<void> toggleTag(String tag) => _store.toggleTag(tag);
  Future<void> setTags(Set<String> tags) => _store.setTags(tags);
  Future<void> setFilterBudget(String? budget) =>
      _store.setFilterBudget(budget);
  Future<void> setFilterDuration(String? duration) =>
      _store.setFilterDuration(duration);
  Future<void> toggleSaved(String id) => _store.toggleSaved(id);
  bool isSaved(String id) => _store.isSaved(id);

  /// Clears all filters and refreshes results
  Future<void> clearFilters({bool useRemote = false}) async {
    await _store.setTags({});
    await _store.setFilterBudget(null);
    await _store.setFilterDuration(null);
    // The store change listener will trigger a new search
  }

  /// Gets performance metrics for debugging
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'cacheSize': _cache.length,
      'currentPage': _currentPage,
      'totalResults': _currentResults.length,
      'hasMore': _hasMore,
      'isLoading': _isLoading,
      'lastQuery': _lastQuery,
    };
  }
}

class _CachedResult {
  final List<TravelIdea> ideas;
  final DateTime timestamp;

  _CachedResult({required this.ideas, required this.timestamp});
}
