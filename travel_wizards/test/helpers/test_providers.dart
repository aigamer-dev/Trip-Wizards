import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:travel_wizards/src/controllers/base_controller.dart';
import 'package:travel_wizards/src/repositories/base_repository.dart';

/// Utilities for testing widgets that use Provider state management
class TestProviders {
  /// Creates a minimal provider setup for testing
  static Widget wrapWithProviders(
    Widget child, {
    List<Provider> additionalProviders = const [],
  }) {
    return MultiProvider(
      providers: [
        // Mock repositories
        Provider<MockTripsRepository>(create: (_) => MockTripsRepository()),
        Provider<MockUserRepository>(create: (_) => MockUserRepository()),
        Provider<MockSettingsRepository>(
          create: (_) => MockSettingsRepository(),
        ),

        // Mock controllers
        ChangeNotifierProvider<MockAuthController>(
          create: (_) => MockAuthController(),
        ),
        ChangeNotifierProvider<MockTripPlanningController>(
          create: (_) => MockTripPlanningController(),
        ),
        ChangeNotifierProvider<MockExploreController>(
          create: (_) => MockExploreController(),
        ),

        ...additionalProviders,
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  /// Creates a provider setup with specific mock implementations
  static Widget wrapWithMocks(
    Widget child, {
    MockAuthController? authController,
    MockTripPlanningController? tripController,
    MockExploreController? exploreController,
    MockTripsRepository? tripsRepository,
  }) {
    return MultiProvider(
      providers: [
        // Repositories
        Provider<MockTripsRepository>.value(
          value: tripsRepository ?? MockTripsRepository(),
        ),
        Provider<MockUserRepository>(create: (_) => MockUserRepository()),
        Provider<MockSettingsRepository>(
          create: (_) => MockSettingsRepository(),
        ),

        // Controllers
        ChangeNotifierProvider<MockAuthController>.value(
          value: authController ?? MockAuthController(),
        ),
        ChangeNotifierProvider<MockTripPlanningController>.value(
          value: tripController ?? MockTripPlanningController(),
        ),
        ChangeNotifierProvider<MockExploreController>.value(
          value: exploreController ?? MockExploreController(),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  /// Creates a test environment that pumps a widget with providers
  static Future<void> pumpWithProviders(
    WidgetTester tester,
    Widget widget, {
    List<Provider> additionalProviders = const [],
  }) async {
    await tester.pumpWidget(
      wrapWithProviders(widget, additionalProviders: additionalProviders),
    );
  }

  /// Creates a test environment with specific mocks
  static Future<void> pumpWithMocks(
    WidgetTester tester,
    Widget widget, {
    MockAuthController? authController,
    MockTripPlanningController? tripController,
    MockExploreController? exploreController,
    MockTripsRepository? tripsRepository,
  }) async {
    await tester.pumpWidget(
      wrapWithMocks(
        widget,
        authController: authController,
        tripController: tripController,
        exploreController: exploreController,
        tripsRepository: tripsRepository,
      ),
    );
  }
}

/// Test utility for creating mock controllers
abstract class MockController extends BaseController {
  /// Simulates an async operation with loading states
  Future<T?> simulateAsync<T>(
    T result, {
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    setLoading(true);
    await Future.delayed(delay);
    setLoading(false);
    return result;
  }

  /// Simulates an async operation that fails
  Future<T?> simulateAsyncError<T>(
    String error, {
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    setLoading(true);
    await Future.delayed(delay);
    setLoading(false);
    setError(error);
    return null;
  }
}

/// Mock implementations for testing

class MockAuthController extends MockController {
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userId;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userId => _userId;

  void setMockAuthenticated(bool authenticated, {String? email, String? id}) {
    _isAuthenticated = authenticated;
    _userEmail = email;
    _userId = id;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await simulateAsync(null);
    setMockAuthenticated(true, email: email, id: 'mock_user_id');
  }

  Future<void> signOut() async {
    await simulateAsync(null);
    setMockAuthenticated(false);
  }
}

class MockTripPlanningController extends MockController {
  String _title = '';
  List<String> _destinations = [];
  DateTimeRange? _dates;

  String get title => _title;
  List<String> get destinations => _destinations;
  DateTimeRange? get dates => _dates;

  void setMockTitle(String title) {
    _title = title;
    notifyListeners();
  }

  void setMockDestinations(List<String> destinations) {
    _destinations = destinations;
    notifyListeners();
  }

  void setMockDates(DateTimeRange? dates) {
    _dates = dates;
    notifyListeners();
  }

  Future<void> saveDraft() async {
    await simulateAsync(null);
  }

  Future<void> createTrip() async {
    await simulateAsync(null);
  }
}

class MockExploreController extends MockController {
  Set<String> _selectedTags = {};
  List<String> _savedIdeas = [];

  Set<String> get selectedTags => _selectedTags;
  List<String> get savedIdeas => _savedIdeas;

  void setMockSelectedTags(Set<String> tags) {
    _selectedTags = tags;
    notifyListeners();
  }

  void setMockSavedIdeas(List<String> ideas) {
    _savedIdeas = ideas;
    notifyListeners();
  }

  Future<void> toggleTag(String tag) async {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  Future<void> saveIdea(String idea) async {
    await simulateAsync(null);
    _savedIdeas.add(idea);
    notifyListeners();
  }
}

class MockTripsRepository implements BaseRepository {
  final List<Map<String, dynamic>> _trips = [];

  List<Map<String, dynamic>> get trips => _trips;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> isHealthy() async => true;

  Future<List<Map<String, dynamic>>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_trips);
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _trips.firstWhere((trip) => trip['id'] == id);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> trip) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newTrip = {
      ...trip,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    _trips.add(newTrip);
    return newTrip;
  }

  void addMockTrip(Map<String, dynamic> trip) {
    _trips.add(trip);
  }

  void clearMockTrips() {
    _trips.clear();
  }
}

class MockUserRepository implements BaseRepository {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> isHealthy() async => true;

  Future<Map<String, dynamic>?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _user;
  }

  Future<void> updateUser(Map<String, dynamic> updates) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_user != null) {
      _user = {..._user!, ...updates};
    }
  }

  void setMockUser(Map<String, dynamic>? user) {
    _user = user;
  }
}

class MockSettingsRepository implements BaseRepository {
  final Map<String, dynamic> _settings = {};

  Map<String, dynamic> get settings => _settings;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> isHealthy() async => true;

  Future<Map<String, dynamic>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return Map.from(_settings);
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _settings[key] = value;
  }

  void setMockSetting(String key, dynamic value) {
    _settings[key] = value;
  }

  void clearMockSettings() {
    _settings.clear();
  }
}

/// Test utilities for controller testing
class ControllerTestUtils {
  /// Creates a test that verifies controller loading states
  static void testLoadingStates(
    String description,
    Future<void> Function(BaseController controller) testFunction,
    BaseController Function() controllerFactory,
  ) {
    testWidgets(description, (tester) async {
      final controller = controllerFactory();

      // Initially not loading
      expect(controller.isLoading, false);

      // Execute test function
      final future = testFunction(controller);

      // Should be loading during async operation (allow for micro-tasks)
      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.isLoading, true);

      // Wait for completion
      await future;
      await tester.pump();

      // Should not be loading after completion
      expect(controller.isLoading, false);

      controller.dispose();
    });
  }

  /// Creates a test that verifies controller error handling
  static void testErrorHandling(
    String description,
    Future<void> Function(BaseController controller) testFunction,
    BaseController Function() controllerFactory,
    String expectedErrorSubstring,
  ) {
    testWidgets(description, (tester) async {
      final controller = controllerFactory();

      // Initially no error
      expect(controller.hasError, false);

      // Execute test function that should cause an error
      await testFunction(controller);
      await tester.pump();

      // Should have error
      expect(controller.hasError, true);
      expect(controller.error, contains(expectedErrorSubstring));

      controller.dispose();
    });
  }

  /// Verifies that a controller properly disposes
  static void testDisposal(
    String description,
    BaseController Function() controllerFactory,
  ) {
    test(description, () {
      final controller = controllerFactory();

      expect(controller.isDisposed, false);

      controller.dispose();

      expect(controller.isDisposed, true);
    });
  }
}
