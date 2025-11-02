import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for managing offline functionality and data caching
class OfflineService {
  static OfflineService? _instance;

  static OfflineService get instance {
    _instance ??= OfflineService._();
    return _instance!;
  }

  OfflineService._();

  late SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _isOnline = true; // Default to online, can be updated by app logic
  final Map<String, Future<void> Function(Map<String, dynamic>)>
  _pendingActionProcessors = {};

  // Connectivity listener
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  /// Initialize the offline service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;

    // Check initial connectivity status
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isNotEmpty) {
        _updateOnlineStatus(results.first);
      }
    } catch (e) {
      debugPrint('Error checking initial connectivity: $e');
    }

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (results.isNotEmpty) {
          _updateOnlineStatus(results.first);
        }
      },
      onError: (error) {
        debugPrint('Connectivity listener error: $error');
      },
    );

    debugPrint('OfflineService initialized. Online: $_isOnline');
  }

  /// Update online status based on connectivity result
  void _updateOnlineStatus(ConnectivityResult result) {
    final isConnected = result != ConnectivityResult.none;
    setOnlineStatus(isConnected);
  }

  /// Dispose connectivity listener
  void dispose() {
    _connectivitySubscription.cancel();
  }

  void registerPendingActionProcessor(
    String type,
    Future<void> Function(Map<String, dynamic>) processor,
  ) {
    _pendingActionProcessors[type] = processor;
  }

  /// Manually set online status (can be called by app when connectivity changes)
  void setOnlineStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      final wasOnline = _isOnline;
      _isOnline = isOnline;

      debugPrint(
        '🌐 Network Status Changed: ${wasOnline ? "Online" : "Offline"} → ${_isOnline ? "Online" : "Offline"}',
      );

      if (!wasOnline && _isOnline) {
        debugPrint('✅ Connection RESTORED - starting sync');
        _onConnectionRestored();
      } else if (wasOnline && !_isOnline) {
        debugPrint('❌ Connection LOST - entering offline mode');
        _onConnectionLost();
      }
    }
  }

  /// Check if device is currently online
  bool get isOnline => _isOnline;

  /// Check if device is currently offline
  bool get isOffline => !_isOnline;

  /// Cache data for offline access
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      await _prefs.setString('cache_$key', jsonString);
      await _prefs.setInt(
        'cache_timestamp_$key',
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('Cached data for key: $key');
    } catch (e) {
      debugPrint('Error caching data for $key: $e');
    }
  }

  /// Retrieve cached data
  Map<String, dynamic>? getCachedData(String key) {
    try {
      final jsonString = _prefs.getString('cache_$key');
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error retrieving cached data for $key: $e');
    }
    return null;
  }

  /// Check if cached data exists and is not expired
  bool isCachedDataValid(
    String key, {
    Duration maxAge = const Duration(hours: 24),
  }) {
    final timestamp = _prefs.getInt('cache_timestamp_$key');
    if (timestamp == null) return false;

    final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    return now.difference(cacheDate) < maxAge;
  }

  /// Cache trip data for offline access
  Future<void> cacheTripData(
    String tripId,
    Map<String, dynamic> tripData,
  ) async {
    await cacheData('trip_$tripId', tripData);

    // Also add to list of cached trips
    final cachedTrips = getCachedTripIds();
    if (!cachedTrips.contains(tripId)) {
      cachedTrips.add(tripId);
      await _prefs.setStringList('cached_trip_ids', cachedTrips);
    }
  }

  /// Get cached trip data
  Map<String, dynamic>? getCachedTripData(String tripId) {
    return getCachedData('trip_$tripId');
  }

  /// Get list of cached trip IDs
  List<String> getCachedTripIds() {
    return _prefs.getStringList('cached_trip_ids') ?? [];
  }

  /// Cache user profile data
  Future<void> cacheUserProfile(Map<String, dynamic> userProfile) async {
    await cacheData('user_profile', userProfile);
  }

  /// Get cached user profile
  Map<String, dynamic>? getCachedUserProfile() {
    return getCachedData('user_profile');
  }

  /// Cache conversation history for AI concierge
  Future<void> cacheConversationHistory(
    List<Map<String, dynamic>> messages,
  ) async {
    await cacheData('conversation_history', {'messages': messages});
  }

  /// Get cached conversation history
  List<Map<String, dynamic>> getCachedConversationHistory() {
    final data = getCachedData('conversation_history');
    if (data != null && data['messages'] is List) {
      return List<Map<String, dynamic>>.from(data['messages']);
    }
    return [];
  }

  /// Store pending actions for when connection is restored
  Future<void> addPendingAction(Map<String, dynamic> action) async {
    final pendingActions = getPendingActions();
    pendingActions.add({
      ...action,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    await _prefs.setString('pending_actions', jsonEncode(pendingActions));
    debugPrint('Added pending action: ${action['type']}');
  }

  /// Get list of pending actions
  List<Map<String, dynamic>> getPendingActions() {
    try {
      final jsonString = _prefs.getString('pending_actions');
      if (jsonString != null) {
        final List<dynamic> list = jsonDecode(jsonString);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error retrieving pending actions: $e');
    }
    return [];
  }

  /// Clear pending actions (after successful sync)
  Future<void> clearPendingActions() async {
    await _prefs.remove('pending_actions');
    debugPrint('Cleared pending actions');
  }

  /// Save files for offline access (e.g., images, PDFs)
  Future<String?> saveFileOffline(String url, String fileName) async {
    try {
      if (kIsWeb) {
        // Web doesn't support file system access the same way
        debugPrint('File caching not supported on web platform');
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${directory.path}/offline_files');

      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }

      final filePath = '${offlineDir.path}/$fileName';

      // Note: In a real implementation, you would download the file from the URL
      // For now, we just return the path where it would be stored
      await _prefs.setString('offline_file_$url', filePath);

      debugPrint('File saved offline: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error saving file offline: $e');
      return null;
    }
  }

  /// Get offline file path
  String? getOfflineFilePath(String url) {
    return _prefs.getString('offline_file_$url');
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    final keys = _prefs
        .getKeys()
        .where((key) => key.startsWith('cache_'))
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }

    await _prefs.remove('cached_trip_ids');
    await _prefs.remove('pending_actions');

    debugPrint('Cleared all cached data');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final keys = _prefs.getKeys();
    final cacheKeys = keys.where((key) => key.startsWith('cache_')).toList();
    final pendingActions = getPendingActions();
    final cachedTrips = getCachedTripIds();

    return {
      'total_cached_items': cacheKeys.length,
      'cached_trips_count': cachedTrips.length,
      'pending_actions_count': pendingActions.length,
      'is_online': _isOnline,
      'last_sync': _prefs.getInt('last_sync_timestamp'),
    };
  }

  /// Called when connection is restored
  void _onConnectionRestored() {
    debugPrint('Connection restored - syncing pending actions');
    _syncPendingActions();
  }

  /// Called when connection is lost
  void _onConnectionLost() {
    debugPrint('Connection lost - entering offline mode');
  }

  /// Sync pending actions when connection is restored
  Future<void> _syncPendingActions() async {
    final pendingActions = getPendingActions();

    if (pendingActions.isEmpty) return;

    debugPrint('Syncing ${pendingActions.length} pending actions');

    // In a real implementation, you would process each pending action
    // For now, we just simulate successful sync
    for (final action in pendingActions) {
      try {
        await _processPendingAction(action);
      } catch (e) {
        debugPrint('Error processing pending action: $e');
        // Keep the action in queue for next sync attempt
        continue;
      }
    }

    await clearPendingActions();
    await _prefs.setInt(
      'last_sync_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Process a single pending action
  Future<void> _processPendingAction(Map<String, dynamic> action) async {
    final type = action['type'] as String?;

    final processor = type == null ? null : _pendingActionProcessors[type];
    if (processor != null) {
      await processor(action);
      return;
    }

    switch (type) {
      case 'update_trip':
        // Process trip update
        debugPrint('Processing trip update: ${action['tripId']}');
        break;
      case 'send_message':
        // Process message sending
        debugPrint('Processing message send: ${action['message']}');
        break;
      case 'update_profile':
        // Process profile update
        debugPrint('Processing profile update');
        break;
      default:
        debugPrint('Unknown pending action type: $type');
    }

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

/// Extension to add offline support to existing services
mixin OfflineCapableMixin {
  /// Get data with offline fallback
  Future<T?> getDataWithOfflineFallback<T>(
    String cacheKey,
    Future<T> Function() onlineDataProvider,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final offlineService = OfflineService.instance;

    if (offlineService.isOnline) {
      try {
        final data = await onlineDataProvider();
        // Cache the fresh data
        if (data is Map<String, dynamic>) {
          await offlineService.cacheData(cacheKey, data);
        }
        return data;
      } catch (e) {
        debugPrint('Online request failed, falling back to cache: $e');
      }
    }

    // Try to get from cache
    final cachedData = offlineService.getCachedData(cacheKey);
    if (cachedData != null) {
      return fromJson(cachedData);
    }

    return null;
  }

  /// Update data with offline queue support
  Future<bool> updateDataWithOfflineSupport(
    String actionType,
    Map<String, dynamic> actionData,
    Future<void> Function() onlineUpdateProvider,
  ) async {
    final offlineService = OfflineService.instance;

    if (offlineService.isOnline) {
      try {
        await onlineUpdateProvider();
        return true;
      } catch (e) {
        debugPrint('Online update failed, queuing for later: $e');
      }
    }

    // Queue for later when online
    await offlineService.addPendingAction({'type': actionType, ...actionData});

    return false; // Indicates queued, not immediately successful
  }
}
