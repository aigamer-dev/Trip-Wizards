/// Minimal stub to replace corrupted service_factory.dart
/// This keeps the codebase compiling by providing a tiny Disposable interface.
/// For DI, use src/architecture/service_locator.dart or src/di/enhanced_service_locator.dart.

abstract class Disposable {
  Future<void> dispose();
}
