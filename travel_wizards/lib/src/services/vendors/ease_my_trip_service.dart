import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_wizards/src/config/env.dart';

/// Minimal scaffold for EaseMyTrip vendor integration.
///
/// In production, replace the simulated methods with real HTTP calls using
/// authenticated credentials. Each method returns a confirmation code string
/// on success. Errors should throw exceptions with user-friendly messages.
class EaseMyTripService {
  EaseMyTripService._();
  static final EaseMyTripService instance = EaseMyTripService._();

  final Random _rnd = Random();

  /// Simulate booking a flight and return a confirmation code.
  Future<String> bookFlight({required String tripId}) async {
    // Try backend first; fallback to local simulation
    final code = await _tryBackend('/book/flight', {'tripId': tripId});
    return code ?? _simulate('FLT');
  }

  /// Simulate booking a hotel and return a confirmation code.
  Future<String> bookHotel({
    required String tripId,
    required int nights,
  }) async {
    final code = await _tryBackend('/book/hotel', {
      'tripId': tripId,
      'nights': nights,
    });
    return code ?? _simulate('HTL');
  }

  /// Simulate reserving local transport and return a confirmation code.
  Future<String> bookTransport({required String tripId}) async {
    final code = await _tryBackend('/book/transport', {'tripId': tripId});
    return code ?? _simulate('CAB');
  }

  Future<String?> _tryBackend(String path, Map<String, Object?> body) async {
    try {
      final base = Uri.parse(kBackendBaseUrl);
      final uri = base.replace(
        path: base.path.endsWith('/')
            ? '${base.path}api$path'
            : '${base.path}/api$path',
      );
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final code = json['confirmationCode'] as String?;
        if (code != null && code.isNotEmpty) return code;
      }
    } catch (_) {
      // swallow; fallback to simulation
    }
    return null;
  }

  String _simulate(String prefix) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(
      6,
      (_) => chars[_rnd.nextInt(chars.length)],
    ).join();
    return '$prefix-$code';
  }
}
