/// Simple Service Factory for Travel Wizards
/// Provides basic dependency injection and lifecycle management

import 'dart:async';
import '../services/error_handling_service.dart';

/// Interface for disposable services
abstract class Disposable {
  Future<void> dispose();
}

/// Enhanced dependency container
class DependencyContainer implements Disposable {
  final Map<Type, dynamic> _singletons = {};
  bool _initialized = false;

  /// Register a singleton instance
  void registerSingleton<T>(T instance) {
    _singletons[T] = instance;
  }

  /// Get an instance of the specified type
  T get<T>() {
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }
    throw StateError('No registration found for type $T');
  }

  /// Check if a type is registered
  bool isRegistered<T>() {
    return _singletons.containsKey(T);
  }

  /// Initialize the container
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    // Dispose all disposable services
    for (final instance in _singletons.values) {
      if (instance is Disposable) {
        try {
          await instance.dispose();
        } catch (e) {
          // Log error but continue cleanup
        }
      }
    }
    _singletons.clear();
    _initialized = false;
  }

  /// Get diagnostics information
  Map<String, dynamic> getDiagnostics() {
    return {
      'initialized': _initialized,
      'services': _singletons.keys.map((k) => k.toString()).toList(),
    };
  }
}

/// Service locator for dependency injection
class ServiceLocator {
  static ServiceLocator? _instance;
  static DependencyContainer? _container;
  static bool _initialized = false;

  ServiceLocator._();

  static ServiceLocator get instance {
    _instance ??= ServiceLocator._();
    return _instance!;
  }

  static DependencyContainer get container {
    _container ??= DependencyContainer();
    return _container!;
  }

  /// Initialize the service locator
  static Future<void> initialize() async {
    // Register core services
    container.registerSingleton(ErrorHandlingService.instance);

    await container.initialize();
    _initialized = true;
  }

  /// Get service instance
  static T get<T>() => container.get<T>();

  /// Check if service is registered
  static bool isRegistered<T>() => container.isRegistered<T>();

  /// Dispose all services
  static Future<void> disposeAll() async {
    await container.dispose();
    _initialized = false;
  }

  static bool get initialized => _initialized;

  /// Get diagnostics
  static Map<String, dynamic> getDiagnostics() {
    return container.getDiagnostics();
  }
}
