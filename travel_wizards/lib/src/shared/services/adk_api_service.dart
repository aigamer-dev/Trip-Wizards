import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

/// Service for communicating with the Travel-agent-ADK API
///
/// This service interfaces with the Google ADK Travel Concierge agent
/// running as a separate FastAPI service. The agent provides AI-powered
/// travel assistance including destination suggestions, itinerary planning,
/// and in-trip support.
class AdkApiService {
  static final AdkApiService _instance = AdkApiService._internal();
  factory AdkApiService() => _instance;
  AdkApiService._internal();

  static const String _appName = 'travel_concierge';
  static const _uuid = Uuid();

  // Base URL for the ADK API service
  // Default to localhost:8080, override with environment variable
  String get _baseUrl {
    try {
      return dotenv.env['ADK_API_URL'] ?? 'http://localhost:8080';
    } catch (e) {
      return 'http://localhost:8080';
    }
  }

  // Store active sessions per user
  final Map<String, String> _userSessions = {};

  /// Set the API base URL dynamically (for cloud deployment)
  static String? _overrideBaseUrl;

  static void setApiBaseUrl(String url) {
    _overrideBaseUrl = url.replaceAll(RegExp(r'/$'), '');
    print('🔧 ADK API Base URL updated to: $_overrideBaseUrl');
  }

  String get _effectiveBaseUrl => _overrideBaseUrl ?? _baseUrl;

  /// Create a new session for a user
  ///
  /// [userId] - The ID of the user
  /// [sessionId] - Optional session ID (generates UUID if not provided)
  ///
  /// Returns the session ID
  Future<String> createSession({
    required String userId,
    String? sessionId,
  }) async {
    final newSessionId = sessionId ?? _uuid.v4();

    try {
      final response = await http
          .post(
            Uri.parse(
              '$_effectiveBaseUrl/apps/$_appName/users/$userId/sessions/$newSessionId',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'state': {}, 'events': []}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _userSessions[userId] = newSessionId;
        return newSessionId;
      } else {
        throw Exception('Failed to create session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating session: $e');
    }
  }

  /// Get or create a session for a user
  ///
  /// [userId] - The ID of the user
  /// [tripId] - Optional trip ID to associate with session
  ///
  /// Returns the session ID
  Future<String> getOrCreateSession({
    required String userId,
    String? tripId,
  }) async {
    // Check if user already has an active session
    if (_userSessions.containsKey(userId)) {
      return _userSessions[userId]!;
    }

    // Create new session
    return await createSession(userId: userId);
  }

  /// Generate AI response for a user message in a trip context
  ///
  /// [tripId] - The ID of the trip for context
  /// [message] - The user's message
  /// [userId] - The ID of the user sending the message
  /// [sessionId] - Optional session ID for conversation continuity
  ///
  /// Returns the AI-generated response text
  Future<String> generateResponse({
    required String tripId,
    required String message,
    required String userId,
    String? sessionId,
  }) async {
    try {
      // Get or create session
      final effectiveSessionId =
          sessionId ?? await getOrCreateSession(userId: userId, tripId: tripId);

      final response = await http
          .post(
            Uri.parse('$_effectiveBaseUrl/run_sse'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'appName': _appName,
              'userId': userId,
              'sessionId': effectiveSessionId,
              'newMessage': {
                'role': 'user',
                'parts': [
                  {'text': message},
                ],
              },
              'streaming': false,
              'stateDelta': null,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        // Parse SSE response - get the last complete message
        final responseText = response.body;

        // For SSE, we need to parse the stream
        // For now, try to extract the text from the response
        try {
          final data = jsonDecode(responseText);

          // Handle array response (events)
          if (data is List && data.isNotEmpty) {
            final lastEvent = data.last;
            final content = lastEvent['content'];
            if (content != null && content['parts'] != null) {
              final parts = content['parts'] as List;
              if (parts.isNotEmpty) {
                return parts.first['text'] ?? 'No response text available.';
              }
            }
          }

          // Handle single event response
          if (data is Map) {
            final content = data['content'];
            if (content != null && content['parts'] != null) {
              final parts = content['parts'] as List;
              if (parts.isNotEmpty) {
                debugPrint("Testing ${parts.first['text']}");
                return parts.first['text'] ?? 'No response text available.';
              }
            }
          }

          return 'I received your message but had trouble parsing the response.';
        } catch (e) {
          // If JSON parsing fails, return raw response (might be SSE format)
          return responseText.isNotEmpty
              ? responseText
              : 'I received your message but had trouble generating a response.';
        }
      } else if (response.statusCode == 503) {
        return _getFallbackResponse(message);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      return _getFallbackResponse(message);
    }
  }

  /// Get session details including message history
  ///
  /// [userId] - The ID of the user
  /// [sessionId] - The session ID
  ///
  /// Returns the session data
  Future<Map<String, dynamic>?> getSession({
    required String userId,
    required String sessionId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_effectiveBaseUrl/apps/$_appName/users/$userId/sessions/$sessionId',
            ),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get session: ${response.statusCode}');
      }
    } catch (e) {
      return null;
    }
  }

  /// Get all sessions for a user
  ///
  /// [userId] - The ID of the user
  ///
  /// Returns list of sessions
  Future<List<Map<String, dynamic>>> getUserSessions({
    required String userId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_effectiveBaseUrl/apps/$_appName/users/$userId/sessions',
            ),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        throw Exception('Failed to get user sessions: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Clear cached session for a user
  void clearUserSession(String userId) {
    _userSessions.remove(userId);
  }

  /// Get destination suggestions from the inspiration agent
  ///
  /// Uses the ADK chat interface with a specialized prompt
  ///
  /// [preferences] - User preferences (budget, activities, climate, etc.)
  /// [userId] - The ID of the user
  ///
  /// Returns destination suggestions
  Future<String> getDestinationSuggestions({
    required Map<String, dynamic> preferences,
    required String userId,
  }) async {
    final preferencesText = preferences.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');

    final prompt =
        'I\'m looking for travel destination suggestions. My preferences are: $preferencesText. Can you suggest some destinations that match these preferences?';

    return await generateResponse(
      tripId: 'inspiration-${DateTime.now().millisecondsSinceEpoch}',
      message: prompt,
      userId: userId,
    );
  }

  /// Get itinerary planning assistance
  ///
  /// Uses the ADK chat interface with planning-focused prompts
  ///
  /// [destination] - The destination
  /// [startDate] - Trip start date
  /// [duration] - Duration in days
  /// [userId] - The ID of the user
  ///
  /// Returns itinerary planning suggestions
  Future<String> getItineraryAssistance({
    required String destination,
    required DateTime startDate,
    required int duration,
    required String userId,
  }) async {
    final prompt =
        'I\'m planning a trip to $destination starting on ${startDate.toLocal().toString().split(' ')[0]} for $duration days. Can you help me create an itinerary?';

    return await generateResponse(
      tripId: 'planning-${DateTime.now().millisecondsSinceEpoch}',
      message: prompt,
      userId: userId,
    );
  }

  /// Check API service health
  ///
  /// Returns true if the ADK API service is reachable and healthy
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_effectiveBaseUrl/list-apps'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get fallback response when ADK service is unavailable
  ///
  /// Provides helpful responses based on message content
  String _getFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('destination') ||
        lowerMessage.contains('where')) {
      return 'I can help you find amazing destinations! Unfortunately, the AI service is temporarily unavailable. Please try again in a moment, or feel free to browse destinations manually.';
    } else if (lowerMessage.contains('itinerary') ||
        lowerMessage.contains('plan')) {
      return 'I\'d love to help you plan your itinerary! The AI planning service is currently unavailable, but you can manually add activities using the itinerary section.';
    } else if (lowerMessage.contains('hotel') ||
        lowerMessage.contains('flight')) {
      return 'I can assist with travel bookings! The AI service is temporarily offline. You can explore options manually or try again shortly.';
    } else if (lowerMessage.contains('weather') ||
        lowerMessage.contains('climate')) {
      return 'I can provide weather information! Unfortunately, I\'m currently unable to fetch real-time data. Please check back soon.';
    } else {
      return 'Hi! I\'m your AI travel assistant. The AI service is temporarily unavailable, but I\'ll be back soon to help with destinations, planning, bookings, and more!';
    }
  }
}
