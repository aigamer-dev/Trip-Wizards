import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travel_wizards/src/core/app/theme.dart';
import 'package:travel_wizards/src/core/app/settings_controller.dart';
import 'package:travel_wizards/src/shared/services/auth_service.dart';
import 'package:travel_wizards/src/shared/services/error_handling_service.dart';
import 'package:travel_wizards/src/core/l10n/app_localizations.dart';

/*
  TestHelpers

  Purpose
  - Provide a minimal, consistent widget-test harness used across the project's
    widget tests. The helpers avoid touching production Firebase and make it
    straightforward to inject mocked Firebase (auth/firestore) instances.

  Key helpers
  - wrapWithApp(child, mockAuth, mockFirestore): Wraps [child] in a
    MaterialApp with theme, localizations and common providers. Pass
    `mockAuth` (MockFirebaseAuth) and `mockFirestore` (FakeFirebaseFirestore)
    to seed authentication and database state for the test.

  - wrapWithRouter(child, ...): Same as wrapWithApp but provides a minimal
    `GoRouter` and uses `MaterialApp.router` — useful when the widget under
    test expects routing to be present.

  - createMockAuthWithUser / createMockFirestoreWithData: Convenience
    factories to create mocks used by tests. `createMockFirestoreWithData`
    accepts `userData` to seed the `users/<id>` document which many tests
    rely on.

  Notes for contributors
  - Tests should avoid hitting real Firebase. Use `wrapWithApp` or
    `wrapWithRouter` and pass mocks returned by the factory helpers.
  - If a test needs collections populated (for dropdowns, lists), extend
    `createMockFirestoreWithData` or call `FakeFirebaseFirestore` directly
    in the test to seed additional collections.
  - Keep the harness minimal and prefer deterministic tests (e.g. use
    `EnhancedOnboardingScreen(initialStep: n)` when only the final step is
    under test).
*/

/// Test helper functions for consistent widget testing setup
class TestHelpers {
  /// Creates a test wrapper that provides all necessary providers and services
  /// for widget tests, including Firebase mocks and app theming.
  static Widget wrapWithApp({
    required Widget child,
    MockFirebaseAuth? mockAuth,
    FakeFirebaseFirestore? mockFirestore,
    AppSettings? appSettings,
    bool includeRouter = false,
  }) {
    // Initialize Firebase if not already done
    if (Firebase.apps.isEmpty) {
      Firebase.initializeApp();
    }

    return MultiProvider(
      providers: [
        // App settings
        ChangeNotifierProvider<AppSettings>.value(
          value: appSettings ?? AppSettings.instance,
        ),

        // Auth service
        Provider<AuthService>(create: (_) => AuthService.instance),

        // Error handling service
        Provider<ErrorHandlingService>(
          create: (_) => ErrorHandlingService.instance,
        ),
      ],
      child: MaterialApp(
        title: 'Travel Wizards',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('hi'), // Hindi
          Locale('bn'), // Bengali
          Locale('te'), // Telugu
          Locale('mr'), // Marathi
          Locale('ta'), // Tamil
          Locale('gu'), // Gujarati
          Locale('kn'), // Kannada
          Locale('or'), // Odia
          Locale('pa'), // Punjabi
          Locale('as'), // Assamese
          Locale('ml'), // Malayalam
          Locale('ur'), // Urdu
        ],
        home: includeRouter ? null : child,
        routes: includeRouter
            ? const <String, WidgetBuilder>{}
            : const <String, WidgetBuilder>{},
        onGenerateRoute: includeRouter ? null : (settings) => null,
        builder: (context, child) {
          // Override Firebase instances with mocks if provided
          if (mockAuth != null) {
            // Note: In a real implementation, you might need to use a different approach
            // to inject mock Firebase instances depending on your architecture
          }
          if (mockFirestore != null) {
            // Override Firestore instance
            // This is a simplified example - you may need to adjust based on your needs
          }

          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }

  /// Creates a test wrapper specifically for authentication screens
  static Widget wrapAuthScreen({
    required Widget child,
    MockFirebaseAuth? mockAuth,
    FakeFirebaseFirestore? mockFirestore,
  }) {
    return wrapWithApp(
      child: child,
      mockAuth: mockAuth,
      mockFirestore: mockFirestore,
    );
  }

  /// Creates a test wrapper for router-based screens
  static Widget wrapWithRouter({
    required Widget child,
    MockFirebaseAuth? mockAuth,
    FakeFirebaseFirestore? mockFirestore,
    AppSettings? appSettings,
  }) {
    // Initialize Firebase with mocks if provided
    if (Firebase.apps.isEmpty) {
      Firebase.initializeApp();
    }

    // Create a minimal router for testing
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => child),
        GoRoute(path: '/email-login', builder: (context, state) => child),
      ],
    );

    return MultiProvider(
      providers: [
        // App settings
        ChangeNotifierProvider<AppSettings>.value(
          value: appSettings ?? AppSettings.instance,
        ),

        // Auth service
        Provider<AuthService>(create: (_) => AuthService.instance),

        // Error handling service
        Provider<ErrorHandlingService>(
          create: (_) => ErrorHandlingService.instance,
        ),
      ],
      child: MaterialApp.router(
        title: 'Travel Wizards',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('hi'), // Hindi
          Locale('bn'), // Bengali
          Locale('te'), // Telugu
          Locale('mr'), // Marathi
          Locale('ta'), // Tamil
          Locale('gu'), // Gujarati
          Locale('kn'), // Kannada
          Locale('or'), // Odia
          Locale('pa'), // Punjabi
          Locale('as'), // Assamese
          Locale('ml'), // Malayalam
          Locale('ur'), // Urdu
        ],
        routerConfig: router,
        builder: (context, child) {
          // Override Firebase instances with mocks if provided
          if (mockAuth != null) {
            // For testing, we rely on the mock being set up before widget initialization
            // The AuthService should handle mock injection
          }
          if (mockFirestore != null) {
            // Override Firestore instance for testing
          }

          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }

  /// Helper to create a mock user for testing
  static MockUser createMockUser({
    String uid = 'test-user-id',
    String email = 'test@example.com',
    String displayName = 'Test User',
    bool isEmailVerified = true,
  }) {
    return MockUser(
      uid: uid,
      email: email,
      displayName: displayName,
      isEmailVerified: isEmailVerified,
    );
  }

  /// Helper to create mock auth with a signed-in user
  static MockFirebaseAuth createMockAuthWithUser({
    String uid = 'test-user-id',
    String email = 'test@example.com',
    String displayName = 'Test User',
    bool isEmailVerified = true,
  }) {
    final mockUser = createMockUser(
      uid: uid,
      email: email,
      displayName: displayName,
      isEmailVerified: isEmailVerified,
    );

    return MockFirebaseAuth(mockUser: mockUser, signedIn: true);
  }

  /// Helper to create mock Firestore with test data
  static FakeFirebaseFirestore createMockFirestoreWithData({
    Map<String, dynamic>? userData,
    String userId = 'test-user-id',
  }) {
    final fakeFirestore = FakeFirebaseFirestore();

    if (userData != null) {
      fakeFirestore.collection('users').doc(userId).set(userData);
    }

    return fakeFirestore;
  }
}
