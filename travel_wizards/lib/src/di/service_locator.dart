import 'package:get_it/get_it.dart';
import '../app/settings_controller.dart';
import '../data/explore_store.dart';
import '../data/plan_trip_store.dart';
import '../services/backend_service.dart';
import '../services/generation_service.dart';
import '../data/brainstorm_session_store.dart';
import '../data/profile_store.dart';
import '../services/error_handling_service.dart';
import '../services/social_features_service.dart';
import '../services/booking_integration_service.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // Singletons already exist as instances; register them for DI access.
  if (!sl.isRegistered<AppSettings>()) {
    sl.registerSingleton<AppSettings>(AppSettings.instance);
  }
  if (!sl.isRegistered<ExploreStore>()) {
    sl.registerSingleton<ExploreStore>(ExploreStore.instance);
  }
  if (!sl.isRegistered<PlanTripStore>()) {
    sl.registerSingleton<PlanTripStore>(PlanTripStore.instance);
  }
  // BackendService is optional and initialized conditionally; expose when ready.
  if (!sl.isRegistered<BackendService>() && _backendAvailable) {
    sl.registerSingleton<BackendService>(BackendService.instance);
  }
  if (!sl.isRegistered<GenerationService>()) {
    sl.registerSingleton<GenerationService>(GenerationService.instance);
  }
  if (!sl.isRegistered<BrainstormSessionStore>()) {
    sl.registerSingleton<BrainstormSessionStore>(
      BrainstormSessionStore.instance,
    );
  }
  if (!sl.isRegistered<ProfileStore>()) {
    sl.registerSingleton<ProfileStore>(ProfileStore.instance);
  }
  if (!sl.isRegistered<ErrorHandlingService>()) {
    sl.registerSingleton<ErrorHandlingService>(ErrorHandlingService.instance);
  }
  if (!sl.isRegistered<SocialFeaturesService>()) {
    sl.registerSingleton<SocialFeaturesService>(SocialFeaturesService());
  }
  if (!sl.isRegistered<BookingIntegrationService>()) {
    final bookingService = BookingIntegrationService.instance;
    bookingService.initialize(); // Initialize with enhanced API client
    sl.registerSingleton<BookingIntegrationService>(bookingService);
  }
}

bool get _backendAvailable {
  try {
    // Accessing .instance throws if not initialized.
    // ignore: unnecessary_statements
    BackendService.instance;
    return true;
  } catch (_) {
    return false;
  }
}
