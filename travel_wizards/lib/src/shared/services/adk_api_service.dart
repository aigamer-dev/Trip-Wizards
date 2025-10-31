import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  // Base URL for the ADK API service
  // Default to localhost:8000, override with environment variable
  String get _baseUrl {
    try {
      return dotenv.env['ADK_API_URL'] ?? 'http://localhost:8000';
    } catch (e) {
      return 'http://localhost:8000';
    }
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
      final effectiveSessionId = sessionId ?? '$tripId-$userId';

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'trip_id': tripId,
              'user_id': userId,
              'session_id': effectiveSessionId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ??
            'I received your message but had trouble generating a response.';
      } else if (response.statusCode == 503) {
        // Service unavailable - ADK not running
        return _getFallbackResponse(message);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      // Network error or timeout - return fallback
      return _getFallbackResponse(message);
    }
  }

  /// Get destination suggestions from the inspiration agent
  ///
  /// [preferences] - User preferences (budget, activities, climate, etc.)
  /// [userId] - The ID of the user
  ///
  /// Returns destination suggestions
  Future<String> getDestinationSuggestions({
    required Map<String, dynamic> preferences,
    required String userId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/inspiration'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'preferences': preferences, 'user_id': userId}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['suggestions'] ??
            'Unable to get destination suggestions at this time.';
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      return 'I can help you discover amazing destinations! Tell me about your interests and preferences.';
    }
  }

  /// Get itinerary planning assistance
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
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/planning'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'destination': destination,
              'start_date': startDate.toIso8601String(),
              'duration': duration,
              'user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['plan'] ?? 'Unable to generate itinerary at this time.';
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      return 'I can help you plan your itinerary! Let me know what activities interest you.';
    }
  }

  /// Check API service health
  ///
  /// Returns true if the ADK API service is reachable and healthy
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
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
