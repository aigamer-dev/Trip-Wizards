import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/app/app.dart';
import 'src/app/theme.dart';
import 'src/app/settings_controller.dart';
import 'src/config/env.dart';
import 'src/services/backend_service.dart';
import 'package:provider/provider.dart';
import 'src/data/explore_store.dart';
import 'src/data/plan_trip_store.dart';
import 'src/di/service_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'src/services/settings_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/services/local_sync_repository.dart';
import 'src/data/onboarding_state.dart';
import 'src/services/iap_service.dart';
import 'src/services/push_notifications_service.dart';
import 'src/services/error_handling_service.dart';
import 'src/services/offline_service.dart';
import 'src/services/performance_optimization_manager.dart';
import 'src/services/navigation_service.dart';
import 'src/services/notification_service.dart';
import 'src/services/emergency_service.dart';

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
    showUserError: false,
  );

  // Initialize Hive for lightweight local persistence
  await ErrorHandlingService.instance.handleAsync(
    () => Hive.initFlutter(),
    context: 'Hive Initialization',
    showUserError: false,
  );

  await ErrorHandlingService.instance.handleAsync(
    () => LocalSyncRepository.instance.init(),
    context: 'Local Sync Repository Initialization',
    showUserError: false,
  );

  // Initialize offline service for caching and offline functionality
  await ErrorHandlingService.instance.handleAsync(
    () => OfflineService.instance.initialize(),
    context: 'Offline Service Initialization',
    showUserError: false,
  );

  // Initialize navigation service for enhanced navigation
  NavigationService.instance.initialize();

  // Initialize performance optimization system
  await ErrorHandlingService.instance.handleAsync(
    () => PerformanceOptimizationManager.instance.initialize(),
    context: 'Performance Optimization Initialization',
    showUserError: false,
  );

  // Initialize Firebase (requires valid firebase_options.dart)
  await ErrorHandlingService.instance.handleAsync(
    () =>
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    context: 'Firebase Initialization',
    showUserError: false,
  );

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
  setupServiceLocator();

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
        final light = lightDynamic ?? kFallbackLightScheme;
        final dark = darkDynamic ?? kFallbackDarkScheme;
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
          ],
          child: PerformanceOptimizedApp(
            criticalAssets: const [
              'assets/images/app_icon.png',
              'assets/images/default_avatar.png',
              'assets/images/loading.gif',
            ],
            child: TravelWizardsApp(lightScheme: light, darkScheme: dark),
          ),
        );
      },
    );
  }
}
