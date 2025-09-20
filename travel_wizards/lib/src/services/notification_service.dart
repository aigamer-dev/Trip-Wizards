import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive notification service for real-time updates and notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _backgroundSubscription;

  // Notification streams
  final StreamController<TripNotification> _notificationStreamController =
      StreamController<TripNotification>.broadcast();
  final StreamController<List<TripNotification>> _notificationListController =
      StreamController<List<TripNotification>>.broadcast();

  // Notification settings
  final StreamController<NotificationSettings> _settingsController =
      StreamController<NotificationSettings>.broadcast();

  // Internal state
  bool _isInitialized = false;
  String? _fcmToken;
  NotificationSettings _settings = NotificationSettings.defaultSettings();
  final List<TripNotification> _notifications = [];
  Timer? _periodicUpdateTimer;

  // Getters
  Stream<TripNotification> get notificationStream =>
      _notificationStreamController.stream;
  Stream<List<TripNotification>> get notificationListStream =>
      _notificationListController.stream;
  Stream<NotificationSettings> get settingsStream => _settingsController.stream;
  List<TripNotification> get notifications => List.unmodifiable(_notifications);
  NotificationSettings get settings => _settings;
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 Initializing NotificationService...');

      // Request permissions
      await _requestPermissions();

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('🔔 FCM Token: $_fcmToken');

      // Load settings
      await _loadSettings();

      // Configure message handlers
      await _configureMessageHandlers();

      // Load existing notifications
      await _loadNotifications();

      // Setup periodic updates
      _setupPeriodicUpdates();

      _isInitialized = true;
      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize NotificationService: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      '🔔 Notification permission status: ${settings.authorizationStatus}',
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Configure message handlers for foreground and background
  Future<void> _configureMessageHandlers() async {
    // Foreground message handler
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      debugPrint(
        '🔔 Received foreground message: ${message.notification?.title}',
      );
      _handleMessage(message, isBackground: false);
    });

    // Background message opened handler
    _backgroundSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) {
      debugPrint(
        '🔔 Background message opened: ${message.notification?.title}',
      );
      _handleMessage(message, isBackground: true);
    });

    // Initial message (app opened from terminated state)
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 Initial message: ${initialMessage.notification?.title}');
      _handleMessage(initialMessage, isBackground: true);
    }
  }

  /// Handle incoming messages and convert to notifications
  void _handleMessage(RemoteMessage message, {required bool isBackground}) {
    try {
      final notification = TripNotification.fromRemoteMessage(message);
      _addNotification(notification);

      // Show in-app notification if foreground
      if (!isBackground && _settings.showInAppNotifications) {
        _showInAppNotification(notification);
      }
    } catch (e) {
      debugPrint('❌ Failed to handle message: $e');
    }
  }

  /// Add notification to list and stream
  void _addNotification(TripNotification notification) {
    _notifications.insert(0, notification);

    // Limit to 100 notifications
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }

    // Emit to streams
    _notificationStreamController.add(notification);
    _notificationListController.add(List.unmodifiable(_notifications));

    // Save to storage
    _saveNotifications();
  }

  /// Show in-app notification overlay
  void _showInAppNotification(TripNotification notification) {
    // This would typically show a custom overlay or snackbar
    // Implementation depends on having access to the current context
    debugPrint('🔔 Would show in-app notification: ${notification.title}');
  }

  /// Subscribe to trip notifications
  Future<void> subscribeToTrip(String tripId) async {
    try {
      await _messaging.subscribeToTopic('trip_$tripId');
      debugPrint('🔔 Subscribed to trip notifications: $tripId');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to trip notifications: $e');
    }
  }

  /// Unsubscribe from trip notifications
  Future<void> unsubscribeFromTrip(String tripId) async {
    try {
      await _messaging.unsubscribeFromTopic('trip_$tripId');
      debugPrint('🔔 Unsubscribed from trip notifications: $tripId');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from trip notifications: $e');
    }
  }

  /// Create custom trip notification
  Future<TripNotificationResult> createTripNotification({
    required String tripId,
    required String title,
    required String message,
    required TripNotificationType type,
    Map<String, dynamic>? data,
    DateTime? scheduledTime,
  }) async {
    try {
      final notification = TripNotification(
        id: _generateNotificationId(),
        tripId: tripId,
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        data: data ?? {},
        isRead: false,
        priority: _getNotificationPriority(type),
      );

      if (scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
        // Schedule notification
        await _scheduleNotification(notification, scheduledTime);
      } else {
        // Send immediately
        _addNotification(notification);
      }

      return TripNotificationResult.success(notification);
    } catch (e) {
      debugPrint('❌ Failed to create trip notification: $e');
      return TripNotificationResult.failure(
        'Failed to create notification: $e',
      );
    }
  }

  /// Schedule notification for future delivery
  Future<void> _scheduleNotification(
    TripNotification notification,
    DateTime scheduledTime,
  ) async {
    // Store scheduled notification in Firestore
    await _firestore
        .collection('scheduled_notifications')
        .doc(notification.id)
        .set({
          'notification': notification.toJson(),
          'scheduledTime': Timestamp.fromDate(scheduledTime),
          'status': 'scheduled',
        });

    debugPrint(
      '🔔 Scheduled notification for ${scheduledTime.toIso8601String()}',
    );
  }

  /// Send real-time itinerary update
  Future<void> sendItineraryUpdate({
    required String tripId,
    required String updateType,
    required String message,
    Map<String, dynamic>? details,
  }) async {
    await createTripNotification(
      tripId: tripId,
      title: 'Itinerary Update',
      message: message,
      type: TripNotificationType.itineraryUpdate,
      data: {'updateType': updateType, 'details': details ?? {}},
    );
  }

  /// Send trip reminder
  Future<void> sendTripReminder({
    required String tripId,
    required String title,
    required String message,
    required DateTime reminderTime,
  }) async {
    await createTripNotification(
      tripId: tripId,
      title: title,
      message: message,
      type: TripNotificationType.reminder,
      scheduledTime: reminderTime,
    );
  }

  /// Send weather alert
  Future<void> sendWeatherAlert({
    required String tripId,
    required String location,
    required String weatherCondition,
    required String recommendation,
  }) async {
    await createTripNotification(
      tripId: tripId,
      title: 'Weather Alert - $location',
      message: '$weatherCondition - $recommendation',
      type: TripNotificationType.weatherAlert,
      data: {
        'location': location,
        'weatherCondition': weatherCondition,
        'recommendation': recommendation,
      },
    );
  }

  /// Send delay notification
  Future<void> sendDelayNotification({
    required String tripId,
    required String activityName,
    required Duration delay,
    required String reason,
  }) async {
    final delayText = _formatDuration(delay);
    await createTripNotification(
      tripId: tripId,
      title: 'Delay Alert',
      message: '$activityName is delayed by $delayText. Reason: $reason',
      type: TripNotificationType.delay,
      data: {
        'activityName': activityName,
        'delayMinutes': delay.inMinutes,
        'reason': reason,
      },
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationListController.add(List.unmodifiable(_notifications));
      await _saveNotifications();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _notificationListController.add(List.unmodifiable(_notifications));
    await _saveNotifications();
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _notificationListController.add([]);
    await _saveNotifications();
  }

  /// Update notification settings
  Future<void> updateSettings(NotificationSettings newSettings) async {
    _settings = newSettings;
    _settingsController.add(_settings);
    await _saveSettings();

    // Update topic subscriptions based on settings
    await _updateTopicSubscriptions();
  }

  /// Update topic subscriptions based on current settings
  Future<void> _updateTopicSubscriptions() async {
    if (_settings.tripUpdates) {
      await _messaging.subscribeToTopic('trip_updates');
    } else {
      await _messaging.unsubscribeFromTopic('trip_updates');
    }

    if (_settings.weatherAlerts) {
      await _messaging.subscribeToTopic('weather_alerts');
    } else {
      await _messaging.unsubscribeFromTopic('weather_alerts');
    }

    if (_settings.bookingUpdates) {
      await _messaging.subscribeToTopic('booking_updates');
    } else {
      await _messaging.unsubscribeFromTopic('booking_updates');
    }
  }

  /// Setup periodic updates for trip monitoring
  void _setupPeriodicUpdates() {
    _periodicUpdateTimer?.cancel();

    if (_settings.realTimeUpdates) {
      _periodicUpdateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        _checkForScheduledNotifications();
      });
    }
  }

  /// Check for scheduled notifications that should be delivered
  Future<void> _checkForScheduledNotifications() async {
    try {
      final now = Timestamp.now();
      final query = await _firestore
          .collection('scheduled_notifications')
          .where('scheduledTime', isLessThanOrEqualTo: now)
          .where('status', isEqualTo: 'scheduled')
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        final notification = TripNotification.fromJson(data['notification']);

        _addNotification(notification);

        // Mark as delivered
        await doc.reference.update({'status': 'delivered'});
      }
    } catch (e) {
      debugPrint('❌ Error checking scheduled notifications: $e');
    }
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('notification_settings');

      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        _settings = NotificationSettings.fromJson(settingsMap);
      }

      _settingsController.add(_settings);
    } catch (e) {
      debugPrint('❌ Failed to load notification settings: $e');
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_settings',
        json.encode(_settings.toJson()),
      );
    } catch (e) {
      debugPrint('❌ Failed to save notification settings: $e');
    }
  }

  /// Load notifications from storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');

      if (notificationsJson != null) {
        final notificationsList = json.decode(notificationsJson) as List;
        _notifications.clear();
        _notifications.addAll(
          notificationsList.map((json) => TripNotification.fromJson(json)),
        );

        _notificationListController.add(List.unmodifiable(_notifications));
      }
    } catch (e) {
      debugPrint('❌ Failed to load notifications: $e');
    }
  }

  /// Save notifications to storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = json.encode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString('notifications', notificationsJson);
    } catch (e) {
      debugPrint('❌ Failed to save notifications: $e');
    }
  }

  /// Helper methods
  String _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  NotificationPriority _getNotificationPriority(TripNotificationType type) {
    switch (type) {
      case TripNotificationType.emergency:
        return NotificationPriority.high;
      case TripNotificationType.delay:
      case TripNotificationType.weatherAlert:
        return NotificationPriority.high;
      case TripNotificationType.reminder:
      case TripNotificationType.checkIn:
        return NotificationPriority.normal;
      case TripNotificationType.itineraryUpdate:
      case TripNotificationType.bookingUpdate:
        return NotificationPriority.normal;
      case TripNotificationType.general:
        return NotificationPriority.low;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Dispose resources
  void dispose() {
    _foregroundSubscription?.cancel();
    _backgroundSubscription?.cancel();
    _periodicUpdateTimer?.cancel();
    _notificationStreamController.close();
    _notificationListController.close();
    _settingsController.close();
  }
}

/// Trip notification model
class TripNotification {
  final String id;
  final String tripId;
  final String title;
  final String message;
  final TripNotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool isRead;
  final NotificationPriority priority;

  const TripNotification({
    required this.id,
    required this.tripId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.data,
    required this.isRead,
    required this.priority,
  });

  factory TripNotification.fromRemoteMessage(RemoteMessage message) {
    return TripNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: message.data['tripId'] ?? '',
      title: message.notification?.title ?? 'Travel Update',
      message: message.notification?.body ?? '',
      type: TripNotificationType.fromString(message.data['type'] ?? 'general'),
      timestamp: DateTime.now(),
      data: message.data,
      isRead: false,
      priority: NotificationPriority.fromString(
        message.data['priority'] ?? 'normal',
      ),
    );
  }

  factory TripNotification.fromJson(Map<String, dynamic> json) {
    return TripNotification(
      id: json['id'],
      tripId: json['tripId'],
      title: json['title'],
      message: json['message'],
      type: TripNotificationType.fromString(json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      isRead: json['isRead'] ?? false,
      priority: NotificationPriority.fromString(json['priority'] ?? 'normal'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'message': message,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'isRead': isRead,
      'priority': priority.toString(),
    };
  }

  TripNotification copyWith({
    String? id,
    String? tripId,
    String? title,
    String? message,
    TripNotificationType? type,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
    NotificationPriority? priority,
  }) {
    return TripNotification(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
    );
  }
}

/// Notification types
enum TripNotificationType {
  general,
  itineraryUpdate,
  reminder,
  weatherAlert,
  delay,
  checkIn,
  bookingUpdate,
  emergency;

  static TripNotificationType fromString(String value) {
    return TripNotificationType.values.firstWhere(
      (type) => type.toString().split('.').last == value,
      orElse: () => TripNotificationType.general,
    );
  }
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high;

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.toString().split('.').last == value,
      orElse: () => NotificationPriority.normal,
    );
  }
}

/// Notification settings
class NotificationSettings {
  final bool enabled;
  final bool tripUpdates;
  final bool weatherAlerts;
  final bool reminders;
  final bool bookingUpdates;
  final bool emergencyAlerts;
  final bool showInAppNotifications;
  final bool realTimeUpdates;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationSettings({
    required this.enabled,
    required this.tripUpdates,
    required this.weatherAlerts,
    required this.reminders,
    required this.bookingUpdates,
    required this.emergencyAlerts,
    required this.showInAppNotifications,
    required this.realTimeUpdates,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  factory NotificationSettings.defaultSettings() {
    return const NotificationSettings(
      enabled: true,
      tripUpdates: true,
      weatherAlerts: true,
      reminders: true,
      bookingUpdates: true,
      emergencyAlerts: true,
      showInAppNotifications: true,
      realTimeUpdates: true,
      soundEnabled: true,
      vibrationEnabled: true,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      tripUpdates: json['tripUpdates'] ?? true,
      weatherAlerts: json['weatherAlerts'] ?? true,
      reminders: json['reminders'] ?? true,
      bookingUpdates: json['bookingUpdates'] ?? true,
      emergencyAlerts: json['emergencyAlerts'] ?? true,
      showInAppNotifications: json['showInAppNotifications'] ?? true,
      realTimeUpdates: json['realTimeUpdates'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'tripUpdates': tripUpdates,
      'weatherAlerts': weatherAlerts,
      'reminders': reminders,
      'bookingUpdates': bookingUpdates,
      'emergencyAlerts': emergencyAlerts,
      'showInAppNotifications': showInAppNotifications,
      'realTimeUpdates': realTimeUpdates,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? tripUpdates,
    bool? weatherAlerts,
    bool? reminders,
    bool? bookingUpdates,
    bool? emergencyAlerts,
    bool? showInAppNotifications,
    bool? realTimeUpdates,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      tripUpdates: tripUpdates ?? this.tripUpdates,
      weatherAlerts: weatherAlerts ?? this.weatherAlerts,
      reminders: reminders ?? this.reminders,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      emergencyAlerts: emergencyAlerts ?? this.emergencyAlerts,
      showInAppNotifications:
          showInAppNotifications ?? this.showInAppNotifications,
      realTimeUpdates: realTimeUpdates ?? this.realTimeUpdates,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

/// Notification operation result
class TripNotificationResult {
  final bool isSuccess;
  final String? error;
  final TripNotification? notification;

  const TripNotificationResult._({
    required this.isSuccess,
    this.error,
    this.notification,
  });

  factory TripNotificationResult.success(TripNotification notification) {
    return TripNotificationResult._(
      isSuccess: true,
      notification: notification,
    );
  }

  factory TripNotificationResult.failure(String error) {
    return TripNotificationResult._(isSuccess: false, error: error);
  }
}
