import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

/// Service for communicating with the Travel Agent ADK API
class TravelAgentService {
  static final TravelAgentService _instance = TravelAgentService._();

  factory TravelAgentService() {
    return _instance;
  }

  TravelAgentService._();

  // Configuration
  static String _apiBaseUrl = 'http://localhost:8080';
  static const String _appName = 'travel-concierge';
  static const Duration _timeout = Duration(seconds: 30);

  String? _userId;
  String? _sessionId;
  StreamController<String>? _messageStream;

  /// Set the API base URL (for cloud deployment or different backends)
  /// Call this before any other operations
  /// Example: TravelAgentService.setApiBaseUrl('https://your-adk-server.com')
  static void setApiBaseUrl(String url) {
    _apiBaseUrl = url.replaceAll(
      RegExp(r'/$'),
      '',
    ); // Remove trailing slash if present
    print('🔧 API Base URL updated to: $_apiBaseUrl');
  }

  /// Set the user ID for this service
  void setUserId(String userId) {
    _userId = userId;
  }

  /// Get the current session ID
  String? get sessionId => _sessionId;

  /// Get the current user ID
  String? get userId => _userId;

  /// Check if API is available
  Future<bool> isAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_apiBaseUrl/list-apps'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get the app name (hardcoded as 'travel-concierge' is the only available app)
  String get appName => _appName;

  /// Create a new session with the agent
  Future<Map<String, dynamic>> createSession({String? sessionId}) async {
    if (_userId == null) {
      throw Exception('User ID not set. Call setUserId() first.');
    }

    try {
      final newSessionId =
          sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

      final response = await http
          .post(
            Uri.parse(
              '$_apiBaseUrl/apps/$_appName/users/$_userId/sessions/$newSessionId',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'state': {}, 'events': []}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionId = data['id'];
        return data;
      } else {
        throw Exception(
          'Failed to create session: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error creating session: $e');
    }
  }

  /// Send a message to the agent and get response
  Future<Map<String, dynamic>> sendMessage(String message) async {
    if (_userId == null) {
      throw Exception('User ID not set. Call setUserId() first.');
    }
    if (_sessionId == null) {
      throw Exception('No active session. Call createSession() first.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/run'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'app_name': _appName,
              'user_id': _userId,
              'session_id': _sessionId,
              'new_message': {
                'parts': [
                  {'text': message},
                ],
              },
              'streaming': false,
              'state_delta': {},
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final events = jsonDecode(response.body) as List;
        if (events.isNotEmpty) {
          // Return the last event which contains the agent's response
          return events.last;
        }
        return {'error': 'No response from agent'};
      } else {
        throw Exception(
          'Failed to send message: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  /// Get a session (retrieve session data from server)
  Future<Map<String, dynamic>> getSession() async {
    if (_userId == null || _sessionId == null) {
      throw Exception('User ID or Session ID not set.');
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_apiBaseUrl/apps/$_appName/users/$_userId/sessions/$_sessionId',
            ),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting session: $e');
    }
  }

  /// List all sessions for a user
  Future<List<Map<String, dynamic>>> listSessions() async {
    if (_userId == null) {
      throw Exception('User ID not set. Call setUserId() first.');
    }

    try {
      final response = await http
          .get(Uri.parse('$_apiBaseUrl/apps/$_appName/users/$_userId/sessions'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final sessions = jsonDecode(response.body) as List;
        return sessions.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to list sessions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error listing sessions: $e');
    }
  }

  /// Load an artifact from session
  Future<Map<String, dynamic>> loadArtifact(
    String artifactName, {
    int? version,
  }) async {
    if (_userId == null || _sessionId == null) {
      throw Exception('User ID or Session ID not set.');
    }

    try {
      var url =
          '$_apiBaseUrl/apps/$_appName/users/$_userId/sessions/$_sessionId/artifacts/$artifactName';
      if (version != null) {
        url =
            '$_apiBaseUrl/apps/$_appName/users/$_userId/sessions/$_sessionId/artifacts/$artifactName/versions/$version';
      }

      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load artifact: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading artifact: $e');
    }
  }

  /// List artifacts in session
  Future<List<String>> listArtifacts() async {
    if (_userId == null || _sessionId == null) {
      throw Exception('User ID or Session ID not set.');
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_apiBaseUrl/apps/$_appName/users/$_userId/sessions/$_sessionId/artifacts',
            ),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final artifacts = jsonDecode(response.body) as List;
        return artifacts.cast<String>();
      } else {
        throw Exception('Failed to list artifacts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error listing artifacts: $e');
    }
  }

  /// Get session history (retrieve events from session)
  Future<List<Map<String, dynamic>>> getSessionHistory() async {
    if (_userId == null || _sessionId == null) {
      throw Exception('User ID or Session ID not set.');
    }

    try {
      final sessionData = await getSession();
      final events = sessionData['events'] as List? ?? [];
      return events.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error getting session history: $e');
    }
  }

  /// Delete the current session
  Future<void> deleteSession() async {
    if (_userId == null || _sessionId == null) {
      return;
    }

    try {
      final response = await http
          .delete(
            Uri.parse(
              '$_apiBaseUrl/apps/$_appName/users/$_userId/sessions/$_sessionId',
            ),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete session: ${response.statusCode}');
      }

      _sessionId = null;
    } catch (e) {
      throw Exception('Error deleting session: $e');
    }
  }

  /// Close the session and cleanup
  Future<void> closeSession() async {
    try {
      if (_sessionId != null) {
        await deleteSession();
      }

      await _messageStream?.close();
      _messageStream = null;
    } catch (e) {
      print('Error closing session: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _messageStream?.close();
    _messageStream = null;
    _sessionId = null;
    _userId = null;
  }
}
