import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:travel_wizards/src/shared/services/travel_agent_service.dart';

/// Service for brainstorm feature using Travel Agent ADK
class BrainstormService {
  BrainstormService._();
  static final BrainstormService instance = BrainstormService._();

  final TravelAgentService _agentService = TravelAgentService();
  bool _initialized = false;
  String? _sessionId;

  /// Get the current session ID
  String? get sessionId => _sessionId;

  /// Get the current user
  User? get user => FirebaseAuth.instance.currentUser;

  /// Initialize the brainstorm session using ADK
  Future<void> initialize() async {
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Set user ID for the agent service
      _agentService.setUserId(user!.uid);

      // Check if ADK service is available
      final available = await _agentService.isAvailable();
      if (!available) {
        throw Exception('Travel Agent ADK service is not available');
      }

      // Create a new session with the ADK agent
      await _agentService.createSession();
      _sessionId = _agentService.sessionId;
      _initialized = true;

      debugPrint('✓ Brainstorm session initialized: $_sessionId');
    } catch (e) {
      debugPrint('❌ Failed to initialize brainstorm: $e');
      rethrow;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Send a message and get a response from the ADK agent
  Future<String> send(String prompt) async {
    if (!_initialized || _sessionId == null) {
      throw Exception(
        'Brainstorm service not initialized. Call initialize() first.',
      );
    }

    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('📤 Sending brainstorm prompt: $prompt');

      // Send message via HTTP to ADK API
      final eventResponse = await _agentService.sendMessage(prompt);

      // Extract text content from the event response
      final content = eventResponse['content'] as Map?;
      final parts = content?['parts'] as List? ?? [];

      String responseText = '';
      if (parts.isNotEmpty) {
        final firstPart = parts.first as Map?;
        responseText = (firstPart?['text'] ?? '') as String;
      }

      if (responseText.isNotEmpty) {
        final preview = responseText.length > 100
            ? responseText.substring(0, 100)
            : responseText;
        debugPrint('📥 Brainstorm response received: $preview...');
      }
      return responseText;
    } catch (e) {
      debugPrint('❌ Failed to send brainstorm message: $e');
      rethrow;
    }
  }

  /// Get session history
  Future<List<Map<String, dynamic>>> getSessionHistory() async {
    try {
      final response = await _agentService.getSessionHistory();
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get session history: $e');
      return [];
    }
  }

  /// End the current session
  Future<void> endSession() async {
    if (_sessionId != null) {
      try {
        await _agentService.closeSession();
        _sessionId = null;
        _initialized = false;
        debugPrint('✓ Brainstorm session ended');
      } catch (e) {
        debugPrint('❌ Failed to end session: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _sessionId = null;
    _initialized = false;
  }
}
