import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:travel_wizards/src/shared/services/stripe_service.dart';

class AdkService {
  AdkService._();
  static final AdkService instance = AdkService._();

  String? get backendBaseUrl => StripeService.instance.backendBaseUrl;

  Future<Map<String, dynamic>> createSession({
    required String userId,
    String? sessionId,
  }) async {
    final base = backendBaseUrl;
    if (base == null) throw Exception('No backend configured');
    final uri = Uri.parse('$base/adk/session');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        if (sessionId != null) 'sessionId': sessionId,
      }),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('ADK session failed: ${resp.statusCode} ${resp.body}');
  }

  /// Streams text chunks from /adk/run_sse. Yields decoded 'data:' lines.
  Stream<String> runSse({
    required String userId,
    required String sessionId,
    required String text,
  }) async* {
    final base = backendBaseUrl;
    if (base == null) throw Exception('No backend configured');
    final uri = Uri.parse('$base/adk/run_sse');
    final req = http.Request('POST', uri)
      ..headers['Accept'] = 'text/event-stream'
      ..headers['Cache-Control'] = 'no-cache'
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'userId': userId,
        'sessionId': sessionId,
        'text': text,
      });

    final client = http.Client();
    http.StreamedResponse? res;
    try {
      res = await client.send(req);
      if (res.statusCode != 200) {
        throw Exception('ADK SSE failed: ${res.statusCode}');
      }
      // Parse SSE: lines starting with 'data:'; events separated by blank lines
      final decoder = const Utf8Decoder();
      final buffer = StringBuffer();
      await for (final chunk in res.stream) {
        final data = decoder.convert(chunk);
        buffer.write(data);
        // Process full events
        String content = buffer.toString();
        int sep;
        while ((sep = content.indexOf('\n\n')) != -1) {
          final event = content.substring(0, sep);
          content = content.substring(sep + 2);
          for (final line in event.split('\n')) {
            if (line.startsWith('data:')) {
              yield line.substring(5).trim();
            }
          }
        }
        // Keep remaining partial content in buffer
        buffer
          ..clear()
          ..write(content);
      }
    } catch (e, st) {
      debugPrint('[AdkService] runSse error: $e\n$st');
      rethrow;
    } finally {
      res?.stream.drain();
      client.close();
    }
  }
}
