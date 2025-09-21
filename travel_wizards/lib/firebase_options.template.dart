import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase configuration options template
///
/// This file should be configured with your actual Firebase project credentials.
/// Follow the setup instructions in README.md to configure your Firebase project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return android;
    }
  }

  // Web Firebase Configuration
  static FirebaseOptions get web => FirebaseOptions(
    apiKey:
        dotenv.env['FIREBASE_WEB_API_KEY'] ??
        _throwMissingKey('FIREBASE_WEB_API_KEY'),
    authDomain:
        dotenv.env['FIREBASE_AUTH_DOMAIN'] ??
        _throwMissingKey('FIREBASE_AUTH_DOMAIN'),
    projectId:
        dotenv.env['FIREBASE_PROJECT_ID'] ??
        _throwMissingKey('FIREBASE_PROJECT_ID'),
    storageBucket:
        dotenv.env['FIREBASE_STORAGE_BUCKET'] ??
        _throwMissingKey('FIREBASE_STORAGE_BUCKET'),
    messagingSenderId:
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ??
        _throwMissingKey('FIREBASE_MESSAGING_SENDER_ID'),
    appId:
        dotenv.env['FIREBASE_WEB_APP_ID'] ??
        _throwMissingKey('FIREBASE_WEB_APP_ID'),
    measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
  );

  // Android Firebase Configuration
  static FirebaseOptions get android => FirebaseOptions(
    apiKey:
        dotenv.env['FIREBASE_ANDROID_API_KEY'] ??
        _throwMissingKey('FIREBASE_ANDROID_API_KEY'),
    appId:
        dotenv.env['FIREBASE_ANDROID_APP_ID'] ??
        _throwMissingKey('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId:
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ??
        _throwMissingKey('FIREBASE_MESSAGING_SENDER_ID'),
    projectId:
        dotenv.env['FIREBASE_PROJECT_ID'] ??
        _throwMissingKey('FIREBASE_PROJECT_ID'),
    storageBucket:
        dotenv.env['FIREBASE_STORAGE_BUCKET'] ??
        _throwMissingKey('FIREBASE_STORAGE_BUCKET'),
  );

  // Windows Firebase Configuration
  static FirebaseOptions get windows => FirebaseOptions(
    apiKey:
        dotenv.env['FIREBASE_WEB_API_KEY'] ??
        _throwMissingKey('FIREBASE_WEB_API_KEY'),
    appId:
        dotenv.env['FIREBASE_WEB_APP_ID'] ??
        _throwMissingKey('FIREBASE_WEB_APP_ID'),
    messagingSenderId:
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ??
        _throwMissingKey('FIREBASE_MESSAGING_SENDER_ID'),
    projectId:
        dotenv.env['FIREBASE_PROJECT_ID'] ??
        _throwMissingKey('FIREBASE_PROJECT_ID'),
    authDomain:
        dotenv.env['FIREBASE_AUTH_DOMAIN'] ??
        _throwMissingKey('FIREBASE_AUTH_DOMAIN'),
    storageBucket:
        dotenv.env['FIREBASE_STORAGE_BUCKET'] ??
        _throwMissingKey('FIREBASE_STORAGE_BUCKET'),
    measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
  );

  // Linux Firebase Configuration
  static FirebaseOptions get linux => FirebaseOptions(
    apiKey:
        dotenv.env['FIREBASE_WEB_API_KEY'] ??
        _throwMissingKey('FIREBASE_WEB_API_KEY'),
    appId:
        dotenv.env['FIREBASE_WEB_APP_ID'] ??
        _throwMissingKey('FIREBASE_WEB_APP_ID'),
    messagingSenderId:
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ??
        _throwMissingKey('FIREBASE_MESSAGING_SENDER_ID'),
    projectId:
        dotenv.env['FIREBASE_PROJECT_ID'] ??
        _throwMissingKey('FIREBASE_PROJECT_ID'),
    authDomain:
        dotenv.env['FIREBASE_AUTH_DOMAIN'] ??
        _throwMissingKey('FIREBASE_AUTH_DOMAIN'),
    storageBucket:
        dotenv.env['FIREBASE_STORAGE_BUCKET'] ??
        _throwMissingKey('FIREBASE_STORAGE_BUCKET'),
  );

  static String _throwMissingKey(String keyName) {
    throw Exception(
      'Missing required Firebase configuration: $keyName\n'
      'Please ensure you have:\n'
      '1. Created a .env file in the project root\n'
      '2. Added all required Firebase environment variables\n'
      '3. Followed the setup instructions in README.md\n'
      'See .env.template for the required variables.',
    );
  }
}
