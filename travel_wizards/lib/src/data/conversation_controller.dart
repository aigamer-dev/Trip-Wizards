import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/models/trip.dart';
import 'package:travel_wizards/src/services/trips_repository.dart';
import 'package:travel_wizards/src/services/error_handling_service.dart';
import 'package:travel_wizards/src/services/offline_service.dart';

/// Message status for delivery tracking
enum MessageStatus { sending, sent, delivered, failed }

/// Message type for different conversation participants
enum MessageRole { user, assistant, system }

/// Represents a single conversation message with rich metadata
class ConversationMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;
  final String? sessionId;

  ConversationMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.metadata,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'role': role.name,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'metadata': metadata,
    'sessionId': sessionId,
  };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      ConversationMessage(
        id: json['id'] as String,
        content: json['content'] as String,
        role: MessageRole.values.firstWhere((e) => e.name == json['role']),
        timestamp: DateTime.parse(json['timestamp'] as String),
        status: MessageStatus.values.firstWhere(
          (e) => e.name == json['status'],
        ),
        metadata: json['metadata'] as Map<String, dynamic>?,
        sessionId: json['sessionId'] as String?,
      );

  ConversationMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
    String? sessionId,
  }) => ConversationMessage(
    id: id ?? this.id,
    content: content ?? this.content,
    role: role ?? this.role,
    timestamp: timestamp ?? this.timestamp,
    status: status ?? this.status,
    metadata: metadata ?? this.metadata,
    sessionId: sessionId ?? this.sessionId,
  );
}

/// Enhanced conversation controller with persistence, typing indicators, and trip context
class ConversationController extends ChangeNotifier {
  static const String _storageKey = 'conversation_history';
  static const String _sessionKey = 'active_session_id';
  static const int _maxStoredMessages = 1000;

  // Core conversation state
  List<ConversationMessage> _messages = [];
  String? _sessionId;
  bool _isTyping = false;
  bool _isConnected = true;
  String? _lastError;

  // Trip context integration
  List<Trip> _userTrips = [];
  Trip? _activeTrip;

  // Message processing state
  Timer? _typingTimer;

  // Getters
  List<ConversationMessage> get messages => List.unmodifiable(_messages);
  String? get sessionId => _sessionId;
  bool get isTyping => _isTyping;
  bool get isConnected => _isConnected;
  String? get lastError => _lastError;
  List<Trip> get userTrips => List.unmodifiable(_userTrips);
  Trip? get activeTrip => _activeTrip;
  bool get hasUnreadMessages => _messages.any(
    (m) =>
        m.role == MessageRole.assistant && m.status != MessageStatus.delivered,
  );

  ConversationController() {
    _initializeController();
  }

  /// Initialize controller with persisted data and trip context
  Future<void> _initializeController() async {
    await ErrorHandlingService.instance.handleAsync(
      () async {
        await _loadPersistedData();
        await _loadTripContext();
        await _validateSession();
      },
      context: 'ConversationController initialization',
      userErrorMessage:
          'Failed to initialize conversation. Some features may not work properly.',
      showUserError: false,
    );
  }

  /// Load persisted conversation history and session
  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load session ID
      _sessionId = prefs.getString(_sessionKey);

      // Load conversation history
      final messagesJson = prefs.getString(_storageKey);
      if (messagesJson != null) {
        final List<dynamic> messagesList = jsonDecode(messagesJson);
        _messages = messagesList
            .map((json) => ConversationMessage.fromJson(json))
            .toList();

        // Mark all assistant messages as delivered (they were previously received)
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].role == MessageRole.assistant &&
              _messages[i].status == MessageStatus.sent) {
            _messages[i] = _messages[i].copyWith(
              status: MessageStatus.delivered,
            );
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load persisted conversation data: $e');
    }
  }

  /// Load user's trip context for better AI recommendations
  Future<void> _loadTripContext() async {
    try {
      _userTrips = await TripsRepository.instance.listTrips();

      // Set active trip (most recent by start date)
      if (_userTrips.isNotEmpty) {
        final now = DateTime.now();
        // Try to find currently active trip (started but not ended)
        _activeTrip = _userTrips.firstWhere(
          (trip) => trip.startDate.isBefore(now) && trip.endDate.isAfter(now),
          orElse: () => _userTrips.first, // Fallback to first trip
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load trip context: $e');
    }
  }

  /// Validate current session or create new one
  Future<void> _validateSession() async {
    if (_sessionId == null || _sessionId!.isEmpty) {
      await _createNewSession();
    }
  }

  /// Create a new conversation session
  Future<void> _createNewSession() async {
    try {
      _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, _sessionId!);

      // Add system message with trip context if available
      if (_activeTrip != null) {
        await _addSystemMessage(
          'Active trip context: ${_activeTrip!.title} (${_activeTrip!.destinations.join(", ")})',
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to create new session: $e');
    }
  }

  /// Add a user message to the conversation
  Future<String> addUserMessage(String content) async {
    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_user';
    final isOffline = OfflineService.instance.isOffline;

    final message = ConversationMessage(
      id: messageId,
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
      status: isOffline ? MessageStatus.sending : MessageStatus.sent,
      sessionId: _sessionId,
      metadata: _buildUserMessageMetadata(),
    );

    _messages.add(message);
    await _persistMessages();

    // Cache conversation history for offline access
    await OfflineService.instance.cacheConversationHistory(
      _messages.map((m) => m.toJson()).toList(),
    );

    // If offline, queue the message for later sending
    if (isOffline) {
      await OfflineService.instance.addPendingAction({
        'type': 'send_message',
        'messageId': messageId,
        'content': content,
        'sessionId': _sessionId,
        'tripContext':
            _activeTrip?.title, // Use a simple field instead of toJson
      });
    }

    notifyListeners();

    return messageId;
  }

  /// Add an assistant message (streaming or complete)
  Future<String> addAssistantMessage(
    String content, {
    bool isStreaming = false,
  }) async {
    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant';
    final message = ConversationMessage(
      id: messageId,
      content: content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      status: isStreaming ? MessageStatus.sending : MessageStatus.sent,
      sessionId: _sessionId,
    );

    _messages.add(message);
    await _persistMessages();
    notifyListeners();

    return messageId;
  }

  /// Update an existing message (for streaming responses)
  Future<void> updateMessage(
    String messageId,
    String content, {
    MessageStatus? status,
  }) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(
        content: content,
        status: status ?? _messages[index].status,
      );

      await _persistMessages();
      notifyListeners();
    }
  }

  /// Mark message as delivered (for read receipts)
  Future<void> markMessageAsDelivered(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1 && _messages[index].status != MessageStatus.delivered) {
      _messages[index] = _messages[index].copyWith(
        status: MessageStatus.delivered,
      );
      await _persistMessages();
      notifyListeners();
    }
  }

  /// Add system message for internal communication
  Future<void> _addSystemMessage(String content) async {
    final message = ConversationMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      role: MessageRole.system,
      timestamp: DateTime.now(),
      status: MessageStatus.delivered,
      sessionId: _sessionId,
    );

    _messages.add(message);
    await _persistMessages();
    notifyListeners();
  }

  /// Show typing indicator
  void showTypingIndicator() {
    if (!_isTyping) {
      _isTyping = true;
      notifyListeners();

      // Auto-hide typing indicator after timeout
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 30), hideTypingIndicator);
    }
  }

  /// Hide typing indicator
  void hideTypingIndicator() {
    if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      notifyListeners();
    }
  }

  /// Update connection status
  void updateConnectionStatus(bool isConnected, {String? error}) {
    if (_isConnected != isConnected || _lastError != error) {
      _isConnected = isConnected;
      _lastError = error;
      notifyListeners();
    }
  }

  /// Set active trip for better context
  Future<void> setActiveTrip(Trip? trip) async {
    if (_activeTrip?.id != trip?.id) {
      _activeTrip = trip;

      if (trip != null) {
        await _addSystemMessage(
          'Switched to trip context: ${trip.title} (${trip.destinations.join(", ")})',
        );
      }

      notifyListeners();
    }
  }

  /// Build metadata for user messages including trip context
  Map<String, dynamic> _buildUserMessageMetadata() {
    final metadata = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'hasTrips': _userTrips.isNotEmpty,
      'tripCount': _userTrips.length,
    };

    if (_activeTrip != null) {
      metadata['activeTrip'] = {
        'id': _activeTrip!.id,
        'title': _activeTrip!.title,
        'destinations': _activeTrip!.destinations,
        'startDate': _activeTrip!.startDate.toIso8601String(),
        'endDate': _activeTrip!.endDate.toIso8601String(),
      };
    }

    return metadata;
  }

  /// Persist messages to local storage
  Future<void> _persistMessages() async {
    try {
      // Limit stored messages to prevent storage overflow
      final messagesToStore = _messages.length > _maxStoredMessages
          ? _messages.skip(_messages.length - _maxStoredMessages).toList()
          : _messages;

      final messagesJson = jsonEncode(
        messagesToStore.map((m) => m.toJson()).toList(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, messagesJson);
    } catch (e) {
      debugPrint('Failed to persist messages: $e');
    }
  }

  /// Clear all conversation history
  Future<void> clearHistory() async {
    try {
      _messages.clear();
      _sessionId = null;
      _lastError = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_sessionKey);

      await _createNewSession();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear conversation history: $e');
    }
  }

  /// Get conversation summary for context
  String getConversationSummary({int maxMessages = 5}) {
    if (_messages.isEmpty) return 'No conversation history';

    final recentMessages = _messages
        .where((m) => m.role != MessageRole.system)
        .toList()
        .reversed
        .take(maxMessages)
        .toList()
        .reversed;

    return recentMessages
        .map(
          (m) =>
              '${m.role.name}: ${m.content.substring(0, m.content.length.clamp(0, 100))}',
        )
        .join('\n');
  }

  /// Refresh trip context
  Future<void> refreshTripContext() async {
    await _loadTripContext();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }
}
