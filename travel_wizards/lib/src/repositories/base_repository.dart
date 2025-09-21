/// Base interface for all repository classes in the Travel Wizards app.
///
/// Repositories are responsible for data access and should follow these principles:
/// - Single responsibility (one data source per repository)
/// - Abstraction (hide implementation details from controllers)
/// - Consistency (common patterns for CRUD operations)
/// - Error handling (let controllers handle business logic errors)
abstract class BaseRepository {
  /// Called when the repository is initialized
  /// Override to set up connections, load initial data, etc.
  Future<void> init() async {
    // Default implementation does nothing
  }

  /// Called when the repository is being disposed
  /// Override to clean up connections, close streams, etc.
  Future<void> dispose() async {
    // Default implementation does nothing
  }

  /// Health check for the repository's data source
  /// Returns true if the repository is operational
  Future<bool> isHealthy() async {
    return true; // Default implementation assumes healthy
  }
}

/// Base interface for repositories that manage collections of entities
abstract class BaseCollectionRepository<T, ID> extends BaseRepository {
  /// Retrieves all entities
  Future<List<T>> getAll();

  /// Retrieves a specific entity by ID
  Future<T?> getById(ID id);

  /// Creates a new entity
  Future<T> create(T entity);

  /// Updates an existing entity
  Future<T> update(T entity);

  /// Deletes an entity by ID
  Future<bool> delete(ID id);

  /// Checks if an entity exists
  Future<bool> exists(ID id);

  /// Gets a paginated list of entities
  Future<PaginatedResult<T>> getPaginated({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool sortAscending = true,
  });

  /// Searches entities based on query
  Future<List<T>> search(
    String query, {
    int limit = 20,
    Map<String, dynamic>? filters,
  });
}

/// Base interface for repositories with caching capabilities
abstract class BaseCachedRepository<T, ID>
    extends BaseCollectionRepository<T, ID> {
  /// Clears all cached data
  Future<void> clearCache();

  /// Refreshes data from the original source
  Future<void> refresh();

  /// Gets data from cache first, falls back to source if not available
  Future<T?> getCached(ID id);

  /// Preloads data into cache
  Future<void> preload(List<ID> ids);
}

/// Result wrapper for paginated queries
class PaginatedResult<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasMore,
  });

  /// Creates an empty result
  const PaginatedResult.empty()
    : items = const [],
      currentPage = 1,
      totalPages = 0,
      totalItems = 0,
      hasMore = false;

  /// Creates a result from a list (useful for local/in-memory data)
  factory PaginatedResult.fromList(
    List<T> allItems, {
    int page = 1,
    int limit = 20,
  }) {
    final totalItems = allItems.length;
    final totalPages = (totalItems / limit).ceil();
    final startIndex = (page - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, totalItems);

    final items = startIndex < totalItems
        ? allItems.sublist(startIndex, endIndex)
        : <T>[];

    return PaginatedResult(
      items: items,
      currentPage: page,
      totalPages: totalPages,
      totalItems: totalItems,
      hasMore: page < totalPages,
    );
  }
}

/// Repository exception types
class RepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const RepositoryException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'RepositoryException: $message';
}

class EntityNotFoundException extends RepositoryException {
  EntityNotFoundException(String entityType, dynamic id)
    : super('$entityType with id $id not found', code: 'NOT_FOUND');
}

class DuplicateEntityException extends RepositoryException {
  DuplicateEntityException(String entityType, String field, dynamic value)
    : super('$entityType with $field $value already exists', code: 'DUPLICATE');
}

class ValidationException extends RepositoryException {
  final Map<String, List<String>> fieldErrors;

  ValidationException(super.message, this.fieldErrors)
    : super(code: 'VALIDATION');
}

class NetworkException extends RepositoryException {
  NetworkException([super.message = 'Network error occurred'])
    : super(code: 'NETWORK');
}

class UnauthorizedException extends RepositoryException {
  UnauthorizedException([super.message = 'Unauthorized access'])
    : super(code: 'UNAUTHORIZED');
}

/// Utility mixin for repositories that need local storage
mixin LocalStorageMixin on BaseRepository {
  /// Gets a string value from local storage
  Future<String?> getLocalValue(String key);

  /// Sets a string value in local storage
  Future<void> setLocalValue(String key, String value);

  /// Removes a value from local storage
  Future<void> removeLocalValue(String key);

  /// Gets a JSON object from local storage
  Future<Map<String, dynamic>?> getLocalJson(String key);

  /// Sets a JSON object in local storage
  Future<void> setLocalJson(String key, Map<String, dynamic> value);

  /// Clears all local storage for this repository
  Future<void> clearLocalStorage();
}

/// Utility mixin for repositories that need remote API access
mixin RemoteApiMixin on BaseRepository {
  /// Base URL for the API
  String get baseUrl;

  /// Headers to include in all requests
  Map<String, String> get defaultHeaders;

  /// Makes a GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  });

  /// Makes a POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  });

  /// Makes a PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  });

  /// Makes a DELETE request
  Future<bool> delete(String endpoint, {Map<String, String>? headers});

  /// Uploads a file
  Future<Map<String, dynamic>> upload(
    String endpoint,
    String filePath, {
    Map<String, String>? fields,
    Map<String, String>? headers,
  });
}

/// Utility mixin for repositories that manage data synchronization
mixin SyncMixin<T, ID> on BaseCollectionRepository<T, ID> {
  /// Syncs local data with remote source
  Future<SyncResult> sync();

  /// Gets items that need to be synced
  Future<List<T>> getPendingSync();

  /// Marks an item as synced
  Future<void> markSynced(ID id);

  /// Resolves sync conflicts
  Future<T> resolveConflict(T local, T remote);
}

/// Result of a synchronization operation
class SyncResult {
  final int itemsAdded;
  final int itemsUpdated;
  final int itemsDeleted;
  final int conflicts;
  final List<String> errors;

  const SyncResult({
    this.itemsAdded = 0,
    this.itemsUpdated = 0,
    this.itemsDeleted = 0,
    this.conflicts = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasConflicts => conflicts > 0;
  int get totalChanges => itemsAdded + itemsUpdated + itemsDeleted;
}
