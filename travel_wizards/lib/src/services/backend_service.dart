import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

@immutable
class BackendConfig {
  final Uri baseUrl;
  final Duration timeout;

  const BackendConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 8),
  });
}

class BackendService {
  BackendService._(this._config);
  static BackendService? _instance;
  final BackendConfig _config;

  static BackendService init(BackendConfig config) {
    _instance = BackendService._(config);
    return _instance!;
  }

  static BackendService get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('BackendService not initialized');
    }
    return i;
  }

  Future<List<Map<String, dynamic>>> fetchIdeas({String? query}) async {
    final uri = _config.baseUrl.replace(
      path: '/ideas',
      queryParameters: query != null && query.isNotEmpty ? {'q': query} : null,
    );
    final resp = await http.get(uri).timeout(_config.timeout);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final jsonList = json.decode(resp.body);
      if (jsonList is List) {
        return jsonList.cast<Map<String, dynamic>>();
      }
      throw const FormatException('Invalid ideas JSON');
    }
    throw http.ClientException('HTTP ${resp.statusCode}', uri);
  }
}
