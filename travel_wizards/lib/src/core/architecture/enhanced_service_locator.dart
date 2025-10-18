import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Service lifecycle states
enum ServiceState {
  uninitialized,
  initializing,
  initialized,
  healthy,
  degraded,
  failed,
  disposing,
  disposed,
}

/// Interface for services that can be health-checked
abstract class HealthCheckable {
  Future<ServiceHealthStatus> checkHealth();
}

/// Service health status
class ServiceHealthStatus {
  final bool isHealthy;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ServiceHealthStatus({
    required this.isHealthy,
    required this.message,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  ServiceHealthStatus.healthy({String? message, Map<String, dynamic>? metadata})
    : this(
        isHealthy: true,
        message: message ?? 'Service is healthy',
        metadata: metadata,
      );

  ServiceHealthStatus.unhealthy({
    required String message,
    Map<String, dynamic>? metadata,
  }) : this(isHealthy: false, message: message, metadata: metadata);
}

/// Interface for services with lifecycle management
abstract class LifecycleAware {
  Future<void> initialize();
  Future<void> dispose();
}

/// Service metadata for registration
class ServiceMetadata {
  final String name;
  final Type type;
  final bool isLazy;
  final bool isHealthCheckable;
  final bool isLifecycleAware;
  final List<Type> dependencies;
  final Duration healthCheckInterval;

  const ServiceMetadata({
    required this.name,
    required this.type,
    this.isLazy = false,
    this.isHealthCheckable = false,
    this.isLifecycleAware = false,
    this.dependencies = const [],
    this.healthCheckInterval = const Duration(minutes: 5),
  });
}

/// Service registration entry
class ServiceEntry {
  final ServiceMetadata metadata;
  final dynamic instance;
  ServiceState state;
  ServiceHealthStatus? lastHealthCheck;
  DateTime? lastHealthCheckTime;
  Timer? healthCheckTimer;
  final List<String> dependents;

  ServiceEntry({
    required this.metadata,
    required this.instance,
    this.state = ServiceState.uninitialized,
    this.lastHealthCheck,
    this.lastHealthCheckTime,
  }) : dependents = [];

  bool get isHealthy => lastHealthCheck?.isHealthy ?? false;
  bool get needsHealthCheck {
    if (!metadata.isHealthCheckable || lastHealthCheckTime == null) {
      return false;
    }
    return DateTime.now().difference(lastHealthCheckTime!) >=
        metadata.healthCheckInterval;
  }
}

/// Enhanced service locator with lifecycle management and health monitoring
class EnhancedServiceLocator {
  static EnhancedServiceLocator? _instance;
  static EnhancedServiceLocator get instance {
    _instance ??= EnhancedServiceLocator._();
    return _instance!;
  }

  EnhancedServiceLocator._();

  final Map<Type, ServiceEntry> _services = {};
  final Map<String, Type> _nameToType = {};
  final StreamController<ServiceHealthEvent> _healthEventController =
      StreamController<ServiceHealthEvent>.broadcast();

  bool _isInitialized = false;
  Timer? _globalHealthTimer;

  /// Stream of service health events
  Stream<ServiceHealthEvent> get healthEvents => _healthEventController.stream;

  /// Check if service locator is initialized
  bool get isInitialized => _isInitialized;

  /// Get all registered service names
  List<String> get registeredServices => _nameToType.keys.toList();

  /// Register a service with metadata
  void registerService<T>({
    required ServiceMetadata metadata,
    required T instance,
  }) {
    _registerServiceInternal(type: T, metadata: metadata, instance: instance);
  }

  void registerServiceByType({
    required Type type,
    required ServiceMetadata metadata,
    required Object? instance,
  }) {
    _registerServiceInternal(
      type: type,
      metadata: metadata,
      instance: instance,
    );
  }

  void _registerServiceInternal({
    required Type type,
    required ServiceMetadata metadata,
    required Object? instance,
  }) {
    if (_services.containsKey(type)) {
      throw ServiceLocatorException(
        'Service ${metadata.name} is already registered',
      );
    }

    for (final depType in metadata.dependencies) {
      if (!_services.containsKey(depType) && kDebugMode) {
        developer.log(
          'Warning: Dependency $depType for ${metadata.name} is not yet registered',
          name: 'EnhancedServiceLocator',
        );
      }
    }

    final entry = ServiceEntry(metadata: metadata, instance: instance);

    _services[type] = entry;
    _nameToType[metadata.name] = type;

    for (final depType in metadata.dependencies) {
      final depEntry = _services[depType];
      if (depEntry != null) {
        depEntry.dependents.add(metadata.name);
      }
    }

    developer.log(
      'Registered service: ${metadata.name} (${metadata.type})',
      name: 'EnhancedServiceLocator',
    );

    if (!metadata.isLazy && metadata.isLifecycleAware) {
      _initializeService(entry);
    }

    if (metadata.isHealthCheckable) {
      _startHealthMonitoring(entry);
    }
  }

  /// Get a service instance
  T get<T>() {
    final entry = _services[T];
    if (entry == null) {
      throw ServiceLocatorException('Service of type $T is not registered');
    }

    // Initialize lazy service if needed
    if (entry.metadata.isLazy && entry.state == ServiceState.uninitialized) {
      _initializeService(entry);
    }

    return entry.instance as T;
  }

  /// Get a service by name
  T getByName<T>(String name) {
    final type = _nameToType[name];
    if (type == null) {
      throw ServiceLocatorException(
        'Service with name "$name" is not registered',
      );
    }
    return get<T>();
  }

  /// Check if a service is registered
  bool isRegistered<T>() => _services.containsKey(T);

  /// Check if a service is registered by name
  bool isRegisteredByName(String name) => _nameToType.containsKey(name);

  /// Get service metadata
  ServiceMetadata? getMetadata<T>() => _services[T]?.metadata;

  /// Get service state
  ServiceState? getServiceState<T>() => _services[T]?.state;

  /// Get service health status
  ServiceHealthStatus? getServiceHealth<T>() => _services[T]?.lastHealthCheck;

  /// Get all service states
  Map<String, ServiceState> getAllServiceStates() {
    final states = <String, ServiceState>{};
    for (final entry in _services.entries) {
      final metadata = entry.value.metadata;
      states[metadata.name] = entry.value.state;
    }
    return states;
  }

  /// Reset the service locator (for testing)
  void reset() {
    _services.clear();
    _nameToType.clear();
    _healthEventController.close();
  }

  /// Initialize all services
  Future<void> initializeAll() async {
    if (_isInitialized) return;

    developer.log(
      'Initializing all services...',
      name: 'EnhancedServiceLocator',
    );

    // Sort services by dependencies (topological sort)
    final sortedServices = _topologicalSort();

    for (final entry in sortedServices) {
      if (entry.metadata.isLifecycleAware &&
          entry.state == ServiceState.uninitialized) {
        await _initializeService(entry);
      }
    }

    // Start global health monitoring
    _startGlobalHealthMonitoring();

    _isInitialized = true;
    developer.log(
      'All services initialized successfully',
      name: 'EnhancedServiceLocator',
    );
  }

  /// Dispose all services
  Future<void> disposeAll() async {
    developer.log('Disposing all services...', name: 'EnhancedServiceLocator');

    _globalHealthTimer?.cancel();

    // Dispose in reverse dependency order
    final sortedServices = _topologicalSort().reversed.toList();

    for (final entry in sortedServices) {
      if (entry.metadata.isLifecycleAware &&
          entry.state != ServiceState.disposed &&
          entry.state != ServiceState.disposing) {
        await _disposeService(entry);
      }
      entry.healthCheckTimer?.cancel();
    }

    _services.clear();
    _nameToType.clear();
    _healthEventController.close();
    _isInitialized = false;

    developer.log('All services disposed', name: 'EnhancedServiceLocator');
  }

  /// Force health check for all services
  Future<Map<String, ServiceHealthStatus>> checkAllServicesHealth() async {
    final results = <String, ServiceHealthStatus>{};

    for (final entry in _services.values) {
      if (entry.metadata.isHealthCheckable) {
        try {
          final health = await _performHealthCheck(entry);
          results[entry.metadata.name] = health;
        } catch (e) {
          results[entry.metadata.name] = ServiceHealthStatus.unhealthy(
            message: 'Health check failed: $e',
          );
        }
      }
    }

    return results;
  }

  /// Get service dependency graph
  Map<String, List<String>> getDependencyGraph() {
    final graph = <String, List<String>>{};

    for (final entry in _services.values) {
      final dependencies = entry.metadata.dependencies
          .map((type) => _services[type]?.metadata.name)
          .where((name) => name != null)
          .cast<String>()
          .toList();

      graph[entry.metadata.name] = dependencies;
    }

    return graph;
  }

  /// Get service health summary
  ServiceHealthSummary getHealthSummary() {
    var healthy = 0;
    var unhealthy = 0;
    var unknown = 0;

    for (final entry in _services.values) {
      if (entry.metadata.isHealthCheckable) {
        if (entry.lastHealthCheck?.isHealthy == true) {
          healthy++;
        } else if (entry.lastHealthCheck?.isHealthy == false) {
          unhealthy++;
        } else {
          unknown++;
        }
      }
    }

    return ServiceHealthSummary(
      totalServices: _services.length,
      healthyServices: healthy,
      unhealthyServices: unhealthy,
      unknownServices: unknown,
      lastCheckTime: DateTime.now(),
    );
  }

  /// Initialize a single service
  Future<void> _initializeService(ServiceEntry entry) async {
    if (entry.state != ServiceState.uninitialized) return;

    try {
      entry.state = ServiceState.initializing;

      if (entry.metadata.isLifecycleAware) {
        await (entry.instance as LifecycleAware).initialize();
      }

      entry.state = ServiceState.initialized;

      developer.log(
        'Initialized service: ${entry.metadata.name}',
        name: 'EnhancedServiceLocator',
      );
    } catch (e, stackTrace) {
      entry.state = ServiceState.failed;

      developer.log(
        'Failed to initialize service: ${entry.metadata.name} - $e',
        name: 'EnhancedServiceLocator',
        error: e,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  /// Dispose a single service
  Future<void> _disposeService(ServiceEntry entry) async {
    if (entry.state == ServiceState.disposed ||
        entry.state == ServiceState.disposing) {
      return;
    }

    try {
      entry.state = ServiceState.disposing;

      if (entry.metadata.isLifecycleAware) {
        await (entry.instance as LifecycleAware).dispose();
      }

      entry.state = ServiceState.disposed;

      developer.log(
        'Disposed service: ${entry.metadata.name}',
        name: 'EnhancedServiceLocator',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to dispose service: ${entry.metadata.name} - $e',
        name: 'EnhancedServiceLocator',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Start health monitoring for a service
  void _startHealthMonitoring(ServiceEntry entry) {
    if (!entry.metadata.isHealthCheckable) return;

    entry.healthCheckTimer = Timer.periodic(
      entry.metadata.healthCheckInterval,
      (_) => _performHealthCheck(entry),
    );

    // Perform initial health check
    _performHealthCheck(entry);
  }

  /// Perform health check for a service
  Future<ServiceHealthStatus> _performHealthCheck(ServiceEntry entry) async {
    if (!entry.metadata.isHealthCheckable) {
      return ServiceHealthStatus.healthy(
        message: 'Service does not support health checks',
      );
    }

    try {
      final health = await (entry.instance as HealthCheckable).checkHealth();
      final previousHealth = entry.lastHealthCheck;

      entry.lastHealthCheck = health;
      entry.lastHealthCheckTime = DateTime.now();

      // Update service state based on health
      if (health.isHealthy) {
        if (entry.state == ServiceState.initialized ||
            entry.state == ServiceState.degraded) {
          entry.state = ServiceState.healthy;
        }
      } else {
        entry.state = ServiceState.degraded;
      }

      // Emit health event if status changed
      if (previousHealth?.isHealthy != health.isHealthy) {
        _healthEventController.add(
          ServiceHealthEvent(
            serviceName: entry.metadata.name,
            previousHealth: previousHealth,
            currentHealth: health,
            timestamp: DateTime.now(),
          ),
        );
      }

      return health;
    } catch (e) {
      final health = ServiceHealthStatus.unhealthy(
        message: 'Health check failed: $e',
      );

      entry.lastHealthCheck = health;
      entry.lastHealthCheckTime = DateTime.now();
      entry.state = ServiceState.failed;

      _healthEventController.add(
        ServiceHealthEvent(
          serviceName: entry.metadata.name,
          previousHealth: entry.lastHealthCheck,
          currentHealth: health,
          timestamp: DateTime.now(),
        ),
      );

      return health;
    }
  }

  /// Start global health monitoring
  void _startGlobalHealthMonitoring() {
    _globalHealthTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _performGlobalHealthCheck(),
    );
  }

  /// Perform global health check
  void _performGlobalHealthCheck() {
    for (final entry in _services.values) {
      if (entry.metadata.isHealthCheckable && entry.needsHealthCheck) {
        _performHealthCheck(entry);
      }
    }
  }

  /// Topological sort of services based on dependencies
  List<ServiceEntry> _topologicalSort() {
    final result = <ServiceEntry>[];
    final visited = <Type>{};
    final visiting = <Type>{};

    void visit(Type type) {
      if (visiting.contains(type)) {
        throw ServiceLocatorException(
          'Circular dependency detected involving $type',
        );
      }
      if (visited.contains(type)) return;

      visiting.add(type);

      final entry = _services[type];
      if (entry != null) {
        for (final depType in entry.metadata.dependencies) {
          visit(depType);
        }

        visiting.remove(type);
        visited.add(type);
        result.add(entry);
      }
    }

    for (final type in _services.keys) {
      visit(type);
    }

    return result;
  }
}

/// Service health event
class ServiceHealthEvent {
  final String serviceName;
  final ServiceHealthStatus? previousHealth;
  final ServiceHealthStatus currentHealth;
  final DateTime timestamp;

  ServiceHealthEvent({
    required this.serviceName,
    this.previousHealth,
    required this.currentHealth,
    required this.timestamp,
  });

  bool get isStatusChange =>
      previousHealth?.isHealthy != currentHealth.isHealthy;
}

/// Service health summary
class ServiceHealthSummary {
  final int totalServices;
  final int healthyServices;
  final int unhealthyServices;
  final int unknownServices;
  final DateTime lastCheckTime;

  ServiceHealthSummary({
    required this.totalServices,
    required this.healthyServices,
    required this.unhealthyServices,
    required this.unknownServices,
    required this.lastCheckTime,
  });

  double get healthyPercentage =>
      totalServices > 0 ? (healthyServices / totalServices) * 100 : 0;

  bool get isOverallHealthy => unhealthyServices == 0;
}

/// Service locator exception
class ServiceLocatorException implements Exception {
  final String message;
  const ServiceLocatorException(this.message);

  @override
  String toString() => 'ServiceLocatorException: $message';
}
