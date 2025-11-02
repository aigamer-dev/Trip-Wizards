// Environment/configuration flags for the app.
//
// Configure at runtime via `.env*` files (loaded by flutter_dotenv) and/or
// build/run time `--dart-define` flags.
// Example:
// flutter run -d chrome \
//   --dart-define=ENV=dev \
//   --dart-define=USE_REMOTE_IDEAS=true \
//   --dart-define=BACKEND_BASE_URL=http://localhost:3000
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// When true, Explore will fetch ideas from the backend service.
/// Priority: dotenv -> dart-define -> default
bool get kUseRemoteIdeas {
  final v = dotenv.env['USE_REMOTE_IDEAS'];
  if (v != null) return v.toLowerCase() == 'true';
  const def = bool.fromEnvironment('USE_REMOTE_IDEAS', defaultValue: false);
  return def;
}

/// The base URL for the backend service (scheme+host+optional port).
String get kBackendBaseUrl {
  final v = dotenv.env['BACKEND_BASE_URL'];
  if (v != null && v.isNotEmpty) return v;
  const def = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://192.168.29.143:8080',
  );
  return def;
}
