import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Avoid importing dart:io on web; use foundation platform checks instead.
import 'src/core/app/app.dart';
import 'src/core/app/theme.dart';
import 'src/ui/design_tokens.dart';
import 'src/core/app/settings_controller.dart';
import 'src/core/config/env.dart';
import 'src/shared/services/backend_service.dart';
import 'package:provider/provider.dart';
import 'src/features/explore/data/explore_store.dart';
import 'src/features/trip_planning/data/plan_trip_store.dart';
import 'src/core/architecture/travel_wizards_service_registry.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'src/shared/services/settings_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/shared/services/local_sync_repository.dart';
import 'src/features/onboarding/data/onboarding_state.dart';
import 'src/shared/services/iap_service.dart';
import 'src/shared/services/push_notifications_service.dart';
import 'src/shared/services/error_handling_service.dart';
import 'src/shared/services/offline_service.dart';
import 'src/shared/services/performance_optimization_manager.dart';
import 'src/shared/services/navigation_service.dart';
import 'src/shared/services/notification_service.dart';
import 'src/shared/services/emergency_service.dart';
import 'src/shared/services/android_optimization_service.dart';
import 'src/shared/services/web_optimization_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling service first
  ErrorHandlingService.instance.init();

  // Load environment file based on ENV define; fallback to .env.
  const fileName = ".env";
  bool envLoaded =
      await ErrorHandlingService.instance.handleAsync(
        () async {
          await dotenv.load(fileName: fileName);
          return true;
        },
        context: 'Environment Loading',
        fallbackValue: false,
        showUserError: false,
      ) ??
      false;

  if (!envLoaded) {
    await ErrorHandlingService.instance.handleAsync(
      () => dotenv.load(fileName: '.env'),
      context: 'Fallback Environment Loading',
      fallbackValue: null,
      showUserError: false,
    );
  }

  await ErrorHandlingService.instance.handleAsync(
    () => AppSettings.instance.load(),
    context: 'App Settings Loading',
    showUserError: true,
  );

  // Initialize Hive for lightweight local persistence
  await ErrorHandlingService.instance.handleAsync(
    () => Hive.initFlutter(),
    context: 'Hive Initialization',
    showUserError: true,
  );

  await ErrorHandlingService.instance.handleAsync(
    () => LocalSyncRepository.instance.init(),
    context: 'Local Sync Repository Initialization',
    showUserError: true,
  );

  // Initialize offline service for caching and offline functionality
  await ErrorHandlingService.instance.handleAsync(
    () => OfflineService.instance.initialize(),
    context: 'Offline Service Initialization',
    showUserError: true,
  );

  // Initialize navigation service for enhanced navigation
  NavigationService.instance.initialize();

  // Initialize performance optimization system
  await ErrorHandlingService.instance.handleAsync(
    () => PerformanceOptimizationManager.instance.initialize(),
    context: 'Performance Optimization Initialization',
    showUserError: true,
  );

  // Initialize platform-specific optimizations
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await ErrorHandlingService.instance.handleAsync(
      () => AndroidOptimizationService.instance.initialize(),
      context: 'Android Optimization Initialization',
      showUserError: true,
    );
  }

  if (kIsWeb) {
    await ErrorHandlingService.instance.handleAsync(
      () => WebOptimizationService.instance.initialize(),
      context: 'Web Optimization Initialization',
      showUserError: true,
    );
  }

  // Initialize Firebase (requires valid firebase_options.dart)
  await ErrorHandlingService.instance.handleAsync(
    () =>
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    context: 'Firebase Initialization',
    showUserError: false,
  );

  // Connect to Firebase emulators if enabled (for integration tests)
  const bool useEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  if (useEmulators) {
    const String emulatorHost = String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: '10.0.2.2',
    );
    await ErrorHandlingService.instance.handleAsync(
      () async {
        FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 9098);
        debugPrint(
          '✅ Connected to Firebase emulators at $emulatorHost (Auth:9099, Firestore:9098)',
        );
      },
      context: 'Firebase Emulator Connection',
      showUserError: false,
    );
  }

  // Web: Ensure auth persistence and finalize any pending redirect sign-in
  if (kIsWeb) {
    await ErrorHandlingService.instance.handleAsync(
      () async {
        try {
          await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
          debugPrint('✅ [main] Web auth persistence set to LOCAL');
        } catch (e1) {
          debugPrint(
            '⚠️ [main] LOCAL persistence failed: $e1 (trying SESSION)',
          );
          try {
            await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
            debugPrint('✅ [main] Web auth persistence set to SESSION');
          } catch (e2) {
            debugPrint(
              '⚠️ [main] SESSION persistence failed: $e2 (falling back to NONE)',
            );
            try {
              await FirebaseAuth.instance.setPersistence(Persistence.NONE);
              debugPrint('✅ [main] Web auth persistence set to NONE');
            } catch (e3) {
              debugPrint('🚨 [main] All persistence modes failed: $e3');
            }
          }
        }
        // Calling getRedirectResult completes pending redirect flows and
        // ensures authStateChanges will emit the signed-in user on reload.
        try {
          final result = await FirebaseAuth.instance.getRedirectResult();
          if (result.user != null) {
            debugPrint(
              '🔁 [main] Redirect sign-in completed for uid=${result.user!.uid}',
            );
          } else {
            debugPrint('ℹ️ [main] No pending redirect result');
          }
        } catch (e) {
          // If there was no redirect or it failed, ignore here; errors are handled in UI.
          debugPrint('⚠️ [main] getRedirectResult error: $e');
        }
      },
      context: 'Web Auth Persistence & Redirect Finalization',
      showUserError: false,
    );
  }

  // Initialize notification service after Firebase
  await ErrorHandlingService.instance.handleAsync(
    () => NotificationService.instance.initialize(),
    context: 'Notification Service Initialization',
    showUserError: false,
  );

  // Initialize emergency service after Firebase
  await ErrorHandlingService.instance.handleAsync(
    () => EmergencyService.instance.initialize(),
    context: 'Emergency Service Initialization',
    showUserError: false,
  );

  // Start onboarding state listener once Firebase is available
  ErrorHandlingService.instance.handleSync(
    () => OnboardingState.instance.start(),
    context: 'Onboarding State Initialization',
    showUserError: false,
  );

  // Initialize backend only when remote ideas are enabled.
  if (kUseRemoteIdeas) {
    ErrorHandlingService.instance.handleSync(
      () => BackendService.init(
        BackendConfig(baseUrl: Uri.parse(kBackendBaseUrl)),
      ),
      context: 'Backend Service Initialization',
      showUserError: false,
    );
  }

  // Set up service locator after core singletons and optional backend are ready.
  await ErrorHandlingService.instance.handleAsync(
    () => TravelWizardsServiceRegistry.initialize(),
    context: 'Service Registry Initialization',
    showUserError: false,
  );

  // Initialize Google Play Billing (Android only). Ignore failures silently.
  await ErrorHandlingService.instance.handleAsync(
    () => IAPService.instance.init(),
    context: 'IAP Service Initialization',
    showUserError: false,
  );

  // Initialize FCM push notifications (web/android)
  await ErrorHandlingService.instance.handleAsync(
    () => PushNotificationsService.instance.init(),
    context: 'Push Notifications Initialization',
    showUserError: false,
  );

  // When the user logs in, pull settings from Firestore and then push to ensure defaults are stored
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      await ErrorHandlingService.instance.handleAsync(
        () => SettingsRepository.instance.pullInto(AppSettings.instance),
        context: 'Settings Pull from Firestore',
        showUserError: false,
      );

      await ErrorHandlingService.instance.handleAsync(
        () => SettingsRepository.instance.pushSettings(AppSettings.instance),
        context: 'Settings Push to Firestore',
        showUserError: false,
      );

      unawaited(
        ErrorHandlingService.instance.handleAsync(
          () => NotificationService.instance.ensurePermissionsRequested(),
          context: 'Notification Permission Request',
          showUserError: false,
        ),
      );

      unawaited(
        ErrorHandlingService.instance.handleAsync(
          () => PushNotificationsService.instance.requestPermissionsIfNeeded(),
          context: 'Push Notification Permission Request',
          showUserError: false,
        ),
      );

      unawaited(
        ErrorHandlingService.instance.handleAsync(
          () => EmergencyService.instance.ensurePermissionsRequested(),
          context: 'Emergency Permission Request',
          showUserError: false,
        ),
      );

      if (kIsWeb) {
        unawaited(
          ErrorHandlingService.instance.handleAsync(
            () =>
                WebOptimizationService.instance.requestNotificationPermission(),
            context: 'Web Notification Permission Request',
            showUserError: false,
          ),
        );
      }
    }
  });

  runApp(const TravelWizardsBootstrap());
}

class TravelWizardsBootstrap extends StatelessWidget {
  const TravelWizardsBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme = lightDynamic ?? DesignTokens.fallbackLightScheme;
        final darkScheme = darkDynamic ?? DesignTokens.fallbackDarkScheme;
        final lightTheme = AppTheme.light.copyWith(colorScheme: lightScheme);
        final darkTheme = AppTheme.dark.copyWith(colorScheme: darkScheme);
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AppSettings>.value(
              value: AppSettings.instance,
            ),
            ChangeNotifierProvider<ExploreStore>.value(
              value: ExploreStore.instance,
            ),
            Provider<PlanTripStore>.value(value: PlanTripStore.instance),
            ChangeNotifierProvider<OnboardingState>.value(
              value: OnboardingState.instance,
            ),
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
          ],
          child: PerformanceOptimizedApp(
            criticalAssets: const [],
            child: TravelWizardsApp(
              lightTheme: lightTheme,
              darkTheme: darkTheme,
            ),
          ),
        );
      },
    );
  }
}
