import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'enhanced_service_locator.dart';

/// Travel Wizards specific service registration
class TravelWizardsServiceRegistry {
  static bool _isInitialized = false;
  static final Completer<void> _initializationCompleter = Completer<void>();

  /// Initialize all Travel Wizards services
  static Future<void> initialize() async {
    if (_isInitialized) {
      return _initializationCompleter.future;
    }

    try {
      final locator = EnhancedServiceLocator.instance;

      // Register Firebase services first (no dependencies)
      await _registerFirebaseServices(locator);

      // Register authentication services
      await _registerAuthServices(locator);

      // Register repository services
      await _registerRepositoryServices(locator);

      // Register store services
      await _registerStoreServices(locator);

      // Register application services
      await _registerApplicationServices(locator);

      // Initialize all services
      await locator.initializeAll();

      _isInitialized = true;
      _initializationCompleter.complete();
    } catch (e) {
      _initializationCompleter.completeError(e);
      rethrow;
    }
  }

  /// Register Firebase services
  static Future<void> _registerFirebaseServices(
    EnhancedServiceLocator locator,
  ) async {
    // Firebase Auth
    locator.registerService<FirebaseAuth>(
      metadata: ServiceMetadata(
        name: 'FirebaseAuth',
        type: FirebaseAuth,
        isLazy: false,
        isHealthCheckable: true,
        healthCheckInterval: const Duration(minutes: 10),
      ),
      instance: FirebaseAuth.instance,
    );

    // Firebase Firestore
    locator.registerService<FirebaseFirestore>(
      metadata: ServiceMetadata(
        name: 'FirebaseFirestore',
        type: FirebaseFirestore,
        isLazy: false,
        isHealthCheckable: true,
        healthCheckInterval: const Duration(minutes: 10),
      ),
      instance: FirebaseFirestore.instance,
    );

    // Firebase Storage
    locator.registerService<FirebaseStorage>(
      metadata: ServiceMetadata(
        name: 'FirebaseStorage',
        type: FirebaseStorage,
        isLazy: false,
        isHealthCheckable: true,
        healthCheckInterval: const Duration(minutes: 10),
      ),
      instance: FirebaseStorage.instance,
    );
  }

  /// Register authentication services
  static Future<void> _registerAuthServices(
    EnhancedServiceLocator locator,
  ) async {
    // Note: These would need to be implemented based on actual service classes
    // This is a template showing the registration pattern

    /*
    locator.registerLazy<AuthenticationService>(
      metadata: ServiceMetadata(
        name: 'AuthenticationService',
        type: AuthenticationService,
        isLazy: true,
        isHealthCheckable: true,
        isLifecycleAware: true,
        dependencies: [FirebaseAuth],
        healthCheckInterval: const Duration(minutes: 5),
      ),
      factory: () => AuthenticationService(
        firebaseAuth: locator.get<FirebaseAuth>(),
      ),
    );
    */
  }

  /// Register repository services
  static Future<void> _registerRepositoryServices(
    EnhancedServiceLocator locator,
  ) async {
    /*
    // Ideas Repository
    locator.registerLazy<IdeasRepository>(
      metadata: ServiceMetadata(
        name: 'IdeasRepository',
        type: IdeasRepository,
        isLazy: true,
        isHealthCheckable: true,
        dependencies: [FirebaseFirestore],
        healthCheckInterval: const Duration(minutes: 15),
      ),
      factory: () => IdeasRepository(
        firestore: locator.get<FirebaseFirestore>(),
      ),
    );

    // Local Sync Repository
    locator.registerLazy<LocalSyncRepository>(
      metadata: ServiceMetadata(
        name: 'LocalSyncRepository',
        type: LocalSyncRepository,
        isLazy: true,
        isLifecycleAware: true,
        dependencies: [IdeasRepository],
      ),
      factory: () => LocalSyncRepository(
        ideasRepository: locator.get<IdeasRepository>(),
      ),
    );
    */
  }

  /// Register store services
  static Future<void> _registerStoreServices(
    EnhancedServiceLocator locator,
  ) async {
    /*
    // Explore Store
    locator.registerLazy<ExploreStore>(
      metadata: ServiceMetadata(
        name: 'ExploreStore',
        type: ExploreStore,
        isLazy: true,
        isLifecycleAware: true,
        dependencies: [IdeasRepository],
      ),
      factory: () => ExploreStore(
        ideasRepository: locator.get<IdeasRepository>(),
      ),
    );

    // Plan Trip Store
    locator.registerLazy<PlanTripStore>(
      metadata: ServiceMetadata(
        name: 'PlanTripStore',
        type: PlanTripStore,
        isLazy: true,
        isLifecycleAware: true,
        dependencies: [IdeasRepository, LocalSyncRepository],
      ),
      factory: () => PlanTripStore(
        ideasRepository: locator.get<IdeasRepository>(),
        localSyncRepository: locator.get<LocalSyncRepository>(),
      ),
    );
    */
  }

  /// Register application services
  static Future<void> _registerApplicationServices(
    EnhancedServiceLocator locator,
  ) async {
    /*
    // Navigation Service
    locator.registerSingleton<NavigationService>(
      metadata: ServiceMetadata(
        name: 'NavigationService',
        type: NavigationService,
        isLazy: false,
        isLifecycleAware: true,
      ),
      instance: NavigationService(),
    );

    // Notification Service
    locator.registerLazy<NotificationService>(
      metadata: ServiceMetadata(
        name: 'NotificationService',
        type: NotificationService,
        isLazy: true,
        isHealthCheckable: true,
        isLifecycleAware: true,
        dependencies: [FirebaseAuth],
        healthCheckInterval: const Duration(minutes: 30),
      ),
      factory: () => NotificationService(
        firebaseAuth: locator.get<FirebaseAuth>(),
      ),
    );
    */
  }

  /// Get service instance
  static T get<T>() {
    if (!_isInitialized) {
      throw ServiceLocatorException(
        'Service registry not initialized. Call initialize() first.',
      );
    }
    return EnhancedServiceLocator.instance.get<T>();
  }

  /// Check if service is registered
  static bool isRegistered<T>() {
    return EnhancedServiceLocator.instance.isRegistered<T>();
  }

  /// Get service health status
  static ServiceState? getServiceHealth<T>() {
    return EnhancedServiceLocator.instance.getServiceState<T>();
  }

  /// Get all service health statuses
  static Map<String, ServiceState> getAllServiceHealth() {
    return EnhancedServiceLocator.instance.getAllServiceStates();
  }

  /// Dispose all services
  static Future<void> dispose() async {
    if (_isInitialized) {
      await EnhancedServiceLocator.instance.disposeAll();
      _isInitialized = false;
    }
  }

  /// Reset for testing
  static Future<void> reset() async {
    await dispose();
    EnhancedServiceLocator.instance.reset();
  }
}

/// Service initialization exception
class ServiceInitializationException implements Exception {
  final String message;
  final Exception? cause;

  const ServiceInitializationException(this.message, [this.cause]);

  @override
  String toString() => 'ServiceInitializationException: $message';
}

/// Extension for easy service access
extension ServiceLocatorExtension on Object {
  /// Get service instance
  T getService<T>() => TravelWizardsServiceRegistry.get<T>();

  /// Check if service is registered
  bool hasService<T>() => TravelWizardsServiceRegistry.isRegistered<T>();
}
