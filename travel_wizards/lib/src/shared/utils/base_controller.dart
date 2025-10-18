import 'package:flutter/foundation.dart';
import '../services/error_handling_service.dart';

/// Base class for all controllers providing common functionality
///
/// This class provides:
/// - Loading state management
/// - Error handling integration
/// - Async operation handling
/// - Proper disposal patterns
/// - Debugging support
abstract class BaseController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  /// Whether the controller is currently performing an async operation
  bool get isLoading => _isLoading;

  /// Current error message, if any
  String? get error => _error;

  /// Whether there is an active error
  bool get hasError => _error != null;

  /// Whether the controller has been disposed
  bool get isDisposed => _disposed;

  /// Sets the loading state and notifies listeners
  void setLoading(bool loading) {
    if (_disposed) return;

    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Sets an error message and notifies listeners
  void setError(String? error) {
    if (_disposed) return;

    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  /// Clears the current error
  void clearError() => setError(null);

  /// Handles async operations with automatic loading and error management
  ///
  /// This method:
  /// - Sets loading to true before operation
  /// - Clears previous errors (if requested)
  /// - Handles exceptions and converts to user-friendly messages
  /// - Sets loading to false after completion
  /// - Logs errors for debugging
  ///
  /// Returns the result of the operation, or null if an error occurred
  Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
    bool clearPreviousError = true,
    bool showLoadingState = true,
  }) async {
    if (_disposed) return null;

    if (clearPreviousError) clearError();
    if (showLoadingState) setLoading(true);

    try {
      final result = await operation();
      if (showLoadingState) setLoading(false);
      return result;
    } catch (error, stackTrace) {
      if (showLoadingState) setLoading(false);

      final userMessage = ErrorHandlingService.instance.getUserFriendlyMessage(
        error,
      );
      setError(userMessage);

      ErrorHandlingService.instance.handleError(
        error,
        stackTrace: stackTrace,
        context: context ?? runtimeType.toString(),
      );

      return null;
    }
  }

  /// Handles sync operations with error management (no loading state)
  T? handleSync<T>(
    T Function() operation, {
    String? context,
    bool clearPreviousError = true,
  }) {
    if (_disposed) return null;

    if (clearPreviousError) clearError();

    try {
      return operation();
    } catch (error, stackTrace) {
      final userMessage = ErrorHandlingService.instance.getUserFriendlyMessage(
        error,
      );
      setError(userMessage);

      ErrorHandlingService.instance.handleError(
        error,
        stackTrace: stackTrace,
        context: context ?? runtimeType.toString(),
      );

      return null;
    }
  }

  /// Executes multiple async operations concurrently
  Future<List<T?>> handleAsyncBatch<T>(
    List<Future<T> Function()> operations, {
    String? context,
    bool clearPreviousError = true,
  }) async {
    if (_disposed) return [];

    if (clearPreviousError) clearError();
    setLoading(true);

    try {
      final futures = operations.map((op) async {
        try {
          return await op();
        } catch (e) {
          return null;
        }
      });

      final results = await Future.wait(futures);
      setLoading(false);
      return results;
    } catch (error, stackTrace) {
      setLoading(false);

      final userMessage = ErrorHandlingService.instance.getUserFriendlyMessage(
        error,
      );
      setError(userMessage);

      ErrorHandlingService.instance.handleError(
        error,
        stackTrace: stackTrace,
        context: context ?? runtimeType.toString(),
      );

      return [];
    }
  }

  /// Override to provide custom initialization logic
  /// Called after controller is created and added to the widget tree
  @mustCallSuper
  void init() {
    // Subclasses can override to provide initialization logic
  }

  /// Override to provide custom cleanup logic
  /// Always call super.dispose() when overriding
  @override
  @mustCallSuper
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// For debugging purposes - provides controller state information
  @override
  String toString() {
    return '${runtimeType.toString()}{isLoading: $_isLoading, hasError: $hasError, isDisposed: $_disposed}';
  }
}

/// Base class for controllers that manage collections/lists
abstract class BaseListController<T> extends BaseController {
  List<T> _items = [];
  bool _hasMore = true;
  int _currentPage = 0;

  /// The current list of items
  List<T> get items => List.unmodifiable(_items);

  /// Whether there are more items to load
  bool get hasMore => _hasMore;

  /// Current page number (for pagination)
  int get currentPage => _currentPage;

  /// Whether the list is empty
  bool get isEmpty => _items.isEmpty;

  /// Number of items in the list
  int get length => _items.length;

  /// Adds an item to the list and notifies listeners
  void addItem(T item) {
    if (_disposed) return;
    _items.add(item);
    notifyListeners();
  }

  /// Removes an item from the list and notifies listeners
  bool removeItem(T item) {
    if (_disposed) return false;
    final removed = _items.remove(item);
    if (removed) notifyListeners();
    return removed;
  }

  /// Updates an item in the list and notifies listeners
  void updateItem(int index, T item) {
    if (_disposed || index < 0 || index >= _items.length) return;
    _items[index] = item;
    notifyListeners();
  }

  /// Clears all items and resets pagination
  void clear() {
    if (_disposed) return;
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();
  }

  /// Sets the complete list of items (replaces existing)
  void setItems(List<T> items) {
    if (_disposed) return;
    _items = List.from(items);
    notifyListeners();
  }

  /// Adds multiple items to the existing list
  void addItems(List<T> items) {
    if (_disposed || items.isEmpty) return;
    _items.addAll(items);
    notifyListeners();
  }

  /// Sets whether there are more items to load
  void setHasMore(bool hasMore) {
    if (_disposed) return;
    _hasMore = hasMore;
    // Don't notify listeners for this as it's usually set together with items
  }

  /// Increments the current page
  void nextPage() {
    if (_disposed) return;
    _currentPage++;
  }

  /// Resets pagination to first page
  void resetPagination() {
    if (_disposed) return;
    _currentPage = 0;
    _hasMore = true;
  }

  /// Abstract method to load items (must be implemented by subclasses)
  Future<void> loadItems({bool refresh = false});

  /// Loads more items (for pagination)
  Future<void> loadMore() async {
    if (_disposed || !_hasMore || isLoading) return;
    await loadItems(refresh: false);
  }

  /// Refreshes the list (loads from beginning)
  Future<void> refresh() async {
    if (_disposed) return;
    clear();
    await loadItems(refresh: true);
  }
}
