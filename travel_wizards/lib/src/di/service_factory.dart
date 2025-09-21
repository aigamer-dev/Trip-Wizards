import 'package:flutter/foundation.dart';
import 'enhanced_service_locator.dart';

/// Factory interface for creating services
abstract class ServiceFactory<T> {
  T create();
  ServiceMetadata get metadata;
}

/// Mock service factory for testing
abstract class MockServiceFactory<T> extends ServiceFactory<T> {
  @override
  ServiceMetadata get metadata => ServiceMetadata(
    name: 'Mock${T.toString()}',
    type: T,
    isLazy: false,
    isHealthCheckable: false,
    isLifecycleAware: false,
  );
}

/// Registry for service factories
class ServiceFactoryRegistry {
  static ServiceFactoryRegistry? _instance;
  static ServiceFactoryRegistry get instance {
    _instance ??= ServiceFactoryRegistry._();
    return _instance!;
  }

  ServiceFactoryRegistry._();

  final Map<Type, ServiceFactory> _factories = {};
  final Map<Type, ServiceFactory> _mockFactories = {};

  /// Register a service factory
  void registerFactory<T>(ServiceFactory<T> factory) {
    _factories[T] = factory;
  }

  /// Register a mock factory for testing
  void registerMockFactory<T>(MockServiceFactory<T> factory) {
    _mockFactories[T] = factory;
  }

  /// Get a factory
  ServiceFactory<T>? getFactory<T>() {
    // Return mock factory in test mode
    if (kDebugMode && _mockFactories.containsKey(T)) {
      return _mockFactories[T] as ServiceFactory<T>?;
    }
    return _factories[T] as ServiceFactory<T>?;
  }

  /// Create and register service using factory
  void createAndRegisterService<T>(EnhancedServiceLocator locator) {
    final factory = getFactory<T>();
    if (factory == null) {
      throw ServiceLocatorException('No factory registered for type $T');
    }

    final service = factory.create();
    locator.registerService<T>(metadata: factory.metadata, instance: service);
  }

  /// Clear all factories (for testing)
  void clear() {
    _factories.clear();
    _mockFactories.clear();
  }

  /// Clear only mock factories
  void clearMocks() {
    _mockFactories.clear();
  }
}

/// Base factory for Travel Wizards services
abstract class TravelWizardsServiceFactory<T> extends ServiceFactory<T> {
  @override
  ServiceMetadata get metadata;

  /// Helper to create metadata with common defaults
  ServiceMetadata createMetadata({
    required String name,
    required Type type,
    bool isLazy = false,
    bool isHealthCheckable = false,
    bool isLifecycleAware = false,
    List<Type> dependencies = const [],
    Duration healthCheckInterval = const Duration(minutes: 5),
  }) {
    return ServiceMetadata(
      name: name,
      type: type,
      isLazy: isLazy,
      isHealthCheckable: isHealthCheckable,
      isLifecycleAware: isLifecycleAware,
      dependencies: dependencies,
      healthCheckInterval: healthCheckInterval,
    );
  }
}

/// Service locator builder for easy setup
class ServiceLocatorBuilder {
  final EnhancedServiceLocator _locator = EnhancedServiceLocator.instance;
  final List<Type> _servicesToCreate = [];

  /// Add a service using factory
  ServiceLocatorBuilder addServiceFromFactory<T>() {
    _servicesToCreate.add(T);
    return this;
  }

  /// Add a service instance directly
  ServiceLocatorBuilder addService<T>({
    required ServiceMetadata metadata,
    required T instance,
  }) {
    _locator.registerService<T>(metadata: metadata, instance: instance);
    return this;
  }

  /// Build and initialize all services
  Future<EnhancedServiceLocator> build() async {
    // Create services from factories
    for (final type in _servicesToCreate) {
      // Use type parameter to create service through reflection or factory registry
      // This would need to be implemented based on the specific type system
      // For now, throwing an error to indicate incomplete implementation
      throw UnimplementedError(
        'Service creation for type $type not implemented yet',
      );
    }

    // Initialize all services
    await _locator.initializeAll();

    return _locator;
  }
}

/// Testing utilities
class ServiceLocatorTestUtils {
  /// Create a test service locator with mocks
  static Future<EnhancedServiceLocator> createTestLocator({
    List<Type> mockServices = const [],
  }) async {
    final locator = EnhancedServiceLocator.instance;

    // Register mock services
    for (final type in mockServices) {
      // Use type parameter to create mock service through registry
      // This would need to be implemented based on the specific type system
      // For now, throwing an error to indicate incomplete implementation
      throw UnimplementedError(
        'Mock service creation for type $type not implemented yet',
      );
    }

    await locator.initializeAll();
    return locator;
  }

  /// Clean up after tests
  static Future<void> cleanup() async {
    await EnhancedServiceLocator.instance.disposeAll();
    ServiceFactoryRegistry.instance.clearMocks();
  }
}
