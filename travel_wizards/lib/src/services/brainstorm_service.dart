import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class BrainstormService {
  BrainstormService._();
  static final BrainstormService instance = BrainstormService._();
  User? user = FirebaseAuth.instance.currentUser;
  var uuid = Uuid();
  String host = 'http://192.168.29.143:9000';

  String sessionId = '';
  bool _initialized = false;

  Future<void> initialize() async {
    // Simulate initialization delay

    if (user == null) {
      return Future.error('User not authenticated');
    }

    final sessionId = uuid.v4();
    final url = Uri.parse(
      '$host/apps/travel_concierge/users/${user?.uid}/sessions/$sessionId',
    );
    final response = await http.post(url);

    if (response.statusCode != 200) {
      return Future.error(
        'Failed to initialize BrainstormService: ${response.statusCode}',
      );
    }

    this.sessionId = sessionId;
    _initialized = true;

    return;
  }

  Future<List<String>> getActiveSessions() async {
    if (user == null) {
      return Future.error('User not authenticated');
    }

    final url = Uri.parse(
      '$host/apps/travel_concierge/users/${user!.uid}/sessions',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      return Future.error(
        'Failed to get active sessions: ${response.statusCode} - ${response.body}',
      );
    }

    final responseBody = response.body;
    return [responseBody];
  }

  Future<List<String>> getMessages() async {
    if (user == null) {
      return Future.error('User not authenticated');
    }

    final url = Uri.parse(
      '$host/apps/travel_concierge/users/${user!.uid}/sessions/$sessionId',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      return Future.error(
        'Failed to get messages: ${response.statusCode} - ${response.body}',
      );
    }

    final responseBody = response.body;
    return [responseBody];
  }

  Future<String> send(String prompt) async {
    if (!_initialized) {
      return Future.error('BrainstormService not initialized');
    }

    if (user == null) {
      return Future.error('User not authenticated');
    }

    final url = Uri.parse('$host/run_sse');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'crossDomain': 'true'},
      body:
          '''{
        "appName": "travel_concierge",
        "userId": "${user!.uid}",
        "sessionId": "$sessionId",
        "newMessage": {
            "role": "user",
            "parts": [
                {
                    "text": "$prompt"
                } 
              ]
        },
        "streaming": false,
        "stateDelta": null
      }''',
    );

    if (response.statusCode != 200) {
      return Future.error(
        'Failed to send message: ${response.statusCode} - ${response.body}',
      );
    }

    // Parse response body to extract the AI response text
    final responseBody = response.body.trim();

    debugPrint('\n\n\nResponse Body: $responseBody\n---\n\n');
    final lastEvent = responseBody.split('\n').last;
    debugPrint('\n\n\nLast event: $lastEvent\n\n\n');

    final jsonResponse = jsonDecode(lastEvent.split('data: ').last);
    final agentResponseText = jsonResponse['content']['parts'][0]['text'];

    return agentResponseText;
  }
}
