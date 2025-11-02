import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'enhanced_api_client.dart';
import 'api_client_models.dart';

/// Service health monitoring with real-time status tracking
class ServiceHealthMonitor {
  static ServiceHealthMonitor? _instance;
  static ServiceHealthMonitor get instance {
    _instance ??= ServiceHealthMonitor._();
    return _instance!;
  }

  ServiceHealthMonitor._();

  final Map<String, ServiceHealthEntry> _services = {};
  final StreamController<ServiceHealthEvent> _healthEventController =
      StreamController<ServiceHealthEvent>.broadcast();

  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  /// Stream of health events for all monitored services
  Stream<ServiceHealthEvent> get healthEvents => _healthEventController.stream;

  /// Get current health status for all services
  Map<String, ServiceHealth> get allServicesHealth {
    return Map.fromEntries(
      _services.entries.map(
        (entry) => MapEntry(entry.key, entry.value.currentHealth),
      ),
    );
  }

  /// Register a service for health monitoring
  void registerService({
    required String serviceName,
    required EnhancedApiClient apiClient,
    Duration checkInterval = const Duration(minutes: 2),
    int failureThreshold = 3,
    Duration recoveryTimeout = const Duration(minutes: 10),
  }) {
    final entry = ServiceHealthEntry(
      serviceName: serviceName,
      apiClient: apiClient,
      checkInterval: checkInterval,
      failureThreshold: failureThreshold,
      recoveryTimeout: recoveryTimeout,
    );

    _services[serviceName] = entry;

    // Listen to health changes from the API client
    entry.healthSubscription = apiClient.healthStream.listen(
      (health) => _handleHealthUpdate(serviceName, health),
    );

    developer.log(
      'Registered service for health monitoring: $serviceName',
      name: 'ServiceHealthMonitor',
    );

    // Start monitoring if this is the first service
    if (!_isMonitoring) {
      startMonitoring();
    }
  }

  /// Unregister a service from health monitoring
  void unregisterService(String serviceName) {
    final entry = _services.remove(serviceName);
    entry?.dispose();

    developer.log(
      'Unregistered service from health monitoring: $serviceName',
      name: 'ServiceHealthMonitor',
    );

    // Stop monitoring if no services remain
    if (_services.isEmpty && _isMonitoring) {
      stopMonitoring();
    }
  }

  /// Start health monitoring for all registered services
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Perform initial health checks
    for (final entry in _services.values) {
      _performHealthCheck(entry);
    }

    // Start periodic monitoring
    _monitoringTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _performPeriodicChecks(),
    );

    developer.log(
      'Started health monitoring for ${_services.length} services',
      name: 'ServiceHealthMonitor',
    );
  }

  /// Stop health monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;

    developer.log('Stopped health monitoring', name: 'ServiceHealthMonitor');
  }

  /// Get health status for a specific service
  ServiceHealth? getServiceHealth(String serviceName) {
    return _services[serviceName]?.currentHealth;
  }

  /// Get overall system health status
  ServiceHealthStatus getOverallHealth() {
    if (_services.isEmpty) return ServiceHealthStatus.unknown;

    final healths = _services.values.map((e) => e.currentHealth.status);

    if (healths.any((status) => status == ServiceHealthStatus.unhealthy)) {
      return ServiceHealthStatus.unhealthy;
    }

    if (healths.any((status) => status == ServiceHealthStatus.degraded)) {
      return ServiceHealthStatus.degraded;
    }

    if (healths.every((status) => status == ServiceHealthStatus.healthy)) {
      return ServiceHealthStatus.healthy;
    }

    return ServiceHealthStatus.unknown;
  }

  /// Force health check for a specific service
  Future<ServiceHealth> forceHealthCheck(String serviceName) async {
    final entry = _services[serviceName];
    if (entry == null) {
      throw ArgumentError('Service not registered: $serviceName');
    }

    return await _performHealthCheck(entry);
  }

  /// Force health check for all services
  Future<Map<String, ServiceHealth>> forceHealthCheckAll() async {
    final results = <String, ServiceHealth>{};

    for (final entry in _services.entries) {
      try {
        results[entry.key] = await _performHealthCheck(entry.value);
      } catch (e) {
        developer.log(
          'Failed to check health for ${entry.key}: $e',
          name: 'ServiceHealthMonitor',
        );
      }
    }

    return results;
  }

  /// Handle health update from API client
  void _handleHealthUpdate(String serviceName, ServiceHealth health) {
    final entry = _services[serviceName];
    if (entry == null) return;

    final previousHealth = entry.currentHealth;
    entry.updateHealth(health);

    // Emit health event if status changed
    if (previousHealth.status != health.status) {
      final event = ServiceHealthEvent(
        serviceName: serviceName,
        previousHealth: previousHealth,
        currentHealth: health,
        timestamp: DateTime.now(),
      );

      _healthEventController.add(event);

      developer.log(
        'Health status changed for $serviceName: ${previousHealth.status} -> ${health.status}',
        name: 'ServiceHealthMonitor',
      );
    }
  }

  /// Perform periodic health checks
  void _performPeriodicChecks() {
    for (final entry in _services.values) {
      final timeSinceLastCheck = DateTime.now().difference(entry.lastCheckTime);

      if (timeSinceLastCheck >= entry.checkInterval) {
        _performHealthCheck(entry);
      }
    }
  }

  /// Perform health check for a specific service
  Future<ServiceHealth> _performHealthCheck(ServiceHealthEntry entry) async {
    entry.lastCheckTime = DateTime.now();

    try {
      final health = await entry.apiClient.checkHealth();
      _handleHealthUpdate(entry.serviceName, health);

      // Reset consecutive failures on success
      if (health.isHealthy) {
        entry.consecutiveFailures = 0;
      }

      return health;
    } catch (e) {
      // Increment failure count
      entry.consecutiveFailures++;

      // Determine health status based on failure count
      final status = entry.consecutiveFailures >= entry.failureThreshold
          ? ServiceHealthStatus.unhealthy
          : ServiceHealthStatus.degraded;

      final health = ServiceHealth(
        status: status,
        message: 'Health check failed: $e',
        responseTime: Duration.zero,
        timestamp: DateTime.now(),
        metadata: {
          'consecutiveFailures': entry.consecutiveFailures,
          'error': e.toString(),
        },
      );

      _handleHealthUpdate(entry.serviceName, health);
      return health;
    }
  }

  /// Get health summary for UI display
  HealthSummary getHealthSummary() {
    final services = <String, ServiceHealth>{};
    var healthyCount = 0;
    var degradedCount = 0;
    var unhealthyCount = 0;

    for (final entry in _services.entries) {
      final health = entry.value.currentHealth;
      services[entry.key] = health;

      switch (health.status) {
        case ServiceHealthStatus.healthy:
          healthyCount++;
          break;
        case ServiceHealthStatus.degraded:
          degradedCount++;
          break;
        case ServiceHealthStatus.unhealthy:
          unhealthyCount++;
          break;
        case ServiceHealthStatus.unknown:
          break;
      }
    }

    return HealthSummary(
      services: services,
      totalServices: _services.length,
      healthyCount: healthyCount,
      degradedCount: degradedCount,
      unhealthyCount: unhealthyCount,
      overallStatus: getOverallHealth(),
      isMonitoring: _isMonitoring,
    );
  }

  /// Dispose all resources
  void dispose() {
    stopMonitoring();

    for (final entry in _services.values) {
      entry.dispose();
    }

    _services.clear();
    _healthEventController.close();
  }
}

/// Service health entry for tracking individual services
class ServiceHealthEntry {
  final String serviceName;
  final EnhancedApiClient apiClient;
  final Duration checkInterval;
  final int failureThreshold;
  final Duration recoveryTimeout;

  ServiceHealth currentHealth;
  DateTime lastCheckTime;
  int consecutiveFailures;
  StreamSubscription<ServiceHealth>? healthSubscription;

  ServiceHealthEntry({
    required this.serviceName,
    required this.apiClient,
    required this.checkInterval,
    required this.failureThreshold,
    required this.recoveryTimeout,
  }) : currentHealth = ServiceHealth(
         status: ServiceHealthStatus.unknown,
         message: 'Not checked yet',
         responseTime: Duration.zero,
         timestamp: DateTime.now(),
       ),
       lastCheckTime = DateTime.now(),
       consecutiveFailures = 0;

  void updateHealth(ServiceHealth health) {
    currentHealth = health;
  }

  void dispose() {
    healthSubscription?.cancel();
  }
}

/// Health event for status changes
@immutable
class ServiceHealthEvent {
  final String serviceName;
  final ServiceHealth previousHealth;
  final ServiceHealth currentHealth;
  final DateTime timestamp;

  const ServiceHealthEvent({
    required this.serviceName,
    required this.previousHealth,
    required this.currentHealth,
    required this.timestamp,
  });

  bool get isStatusChange => previousHealth.status != currentHealth.status;

  bool get isImprovement =>
      _getStatusPriority(currentHealth.status) >
      _getStatusPriority(previousHealth.status);

  bool get isDegradation =>
      _getStatusPriority(currentHealth.status) <
      _getStatusPriority(previousHealth.status);

  int _getStatusPriority(ServiceHealthStatus status) {
    switch (status) {
      case ServiceHealthStatus.healthy:
        return 3;
      case ServiceHealthStatus.degraded:
        return 2;
      case ServiceHealthStatus.unhealthy:
        return 1;
      case ServiceHealthStatus.unknown:
        return 0;
    }
  }
}

/// Health summary for UI display
@immutable
class HealthSummary {
  final Map<String, ServiceHealth> services;
  final int totalServices;
  final int healthyCount;
  final int degradedCount;
  final int unhealthyCount;
  final ServiceHealthStatus overallStatus;
  final bool isMonitoring;

  const HealthSummary({
    required this.services,
    required this.totalServices,
    required this.healthyCount,
    required this.degradedCount,
    required this.unhealthyCount,
    required this.overallStatus,
    required this.isMonitoring,
  });

  double get healthyPercentage =>
      totalServices > 0 ? (healthyCount / totalServices) * 100 : 0;

  double get degradedPercentage =>
      totalServices > 0 ? (degradedCount / totalServices) * 100 : 0;

  double get unhealthyPercentage =>
      totalServices > 0 ? (unhealthyCount / totalServices) * 100 : 0;

  bool get hasIssues => degradedCount > 0 || unhealthyCount > 0;

  String get statusMessage {
    if (totalServices == 0) return 'No services registered';
    if (unhealthyCount > 0) return '$unhealthyCount service(s) down';
    if (degradedCount > 0) return '$degradedCount service(s) degraded';
    return 'All services healthy';
  }
}
