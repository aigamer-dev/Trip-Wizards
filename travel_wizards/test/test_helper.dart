import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFirebaseOptions implements FirebaseOptions {
  @override
  String get apiKey => 'test-api-key';

  @override
  String get appId => 'test-app-id';

  @override
  String get messagingSenderId => 'test-sender-id';

  @override
  String get projectId => 'test-project-id';

  @override
  String? get authDomain => 'test-auth-domain';

  @override
  String? get databaseURL => null;

  @override
  String? get storageBucket => 'test-storage-bucket';

  @override
  String? get measurementId => null;

  @override
  String? get trackingId => null;

  @override
  String? get deepLinkURLScheme => null;

  @override
  String? get androidClientId => null;

  @override
  String? get iosClientId => null;

  @override
  String? get iosBundleId => null;

  @override
  String? get appGroupId => null;

  @override
  FirebaseOptions copyWith({
    String? apiKey,
    String? appId,
    String? messagingSenderId,
    String? projectId,
    String? authDomain,
    String? databaseURL,
    String? storageBucket,
    String? measurementId,
    String? trackingId,
    String? deepLinkURLScheme,
    String? androidClientId,
    String? iosClientId,
    String? iosBundleId,
    String? appGroupId,
  }) {
    return MockFirebaseOptions();
  }

  @override
  Map<String, String?> get asMap => {
    'apiKey': apiKey,
    'appId': appId,
    'messagingSenderId': messagingSenderId,
    'projectId': projectId,
    'authDomain': authDomain,
    'databaseURL': databaseURL,
    'storageBucket': storageBucket,
    'measurementId': measurementId,
    'trackingId': trackingId,
    'deepLinkURLScheme': deepLinkURLScheme,
    'androidClientId': androidClientId,
    'iosClientId': iosClientId,
    'iosBundleId': iosBundleId,
    'appGroupId': appGroupId,
  };
}

/// Initialize Firebase for testing
Future<void> initializeFirebaseForTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase if not already initialized
  try {
    await Firebase.initializeApp(options: MockFirebaseOptions());
  } catch (e) {
    // Firebase might already be initialized, which is fine
    if (!e.toString().contains('already exists')) {
      rethrow;
    }
  }
}
