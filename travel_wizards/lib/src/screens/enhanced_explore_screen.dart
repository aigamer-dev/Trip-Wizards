import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/app/settings_controller.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/config/env.dart';
import 'package:travel_wizards/src/controllers/explore_controller.dart';
import 'package:travel_wizards/src/data/explore_store.dart';
import 'package:travel_wizards/src/data/ideas_remote_repository.dart';
import 'package:travel_wizards/src/data/ideas_repository.dart';
import 'package:travel_wizards/src/l10n/app_localizations.dart';
import 'package:travel_wizards/src/screens/trip/plan_trip_screen.dart';
import 'package:travel_wizards/src/services/performance_optimization_manager.dart';
import 'package:travel_wizards/src/widgets/explore/optimized_explore_widgets.dart';

/// Enhanced explore screen with performance optimizations including:
/// - Debounced search queries
/// - Result caching with TTL
/// - Optimized filter chip rebuilds
/// - Pagination for large datasets
/// - Efficient widget rebuilding
class EnhancedExploreScreen extends StatefulWidget {
  const EnhancedExploreScreen({super.key});

  @override
  State<EnhancedExploreScreen> createState() => _EnhancedExploreScreenState();
}

class _EnhancedExploreScreenState extends State<EnhancedExploreScreen>
    with PerformanceOptimizedScreen {
  @override
  String get screenName => 'enhanced_explore';

  @override
  List<String> get preloadAssets => [
    'assets/images/explore_background.jpg',
    'assets/images/travel_categories.png',
  ];

  late final ExploreController _controller;
  late final TextEditingController _searchController;
  String? _currentQuery;

  @override
  void initState() {
    super.initState();

    // Initialize the enhanced controller
    _controller = ExploreController(
      store: ExploreStore.instance,
      localRepo: IdeasRepository.instance,
      remoteRepo: IdeasRemoteRepository.instance,
    );

    _searchController = TextEditingController();

    // Load initial state
    _initializeScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    final uri = GoRouterState.of(context).uri;
    final q = uri.queryParameters['q'];

    if (q != null && q.isNotEmpty) {
      _searchController.text = q;
      _currentQuery = q;
    }

    // Perform initial search
    await _controller.search(
      query: _currentQuery,
      useRemote: _shouldUseRemote(),
    );
  }

  bool _shouldUseRemote() {
    return kUseRemoteIdeas && AppSettings.instance.remoteIdeasEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            _buildSearchBar(t),
            Gaps.h16,

            // Results header
            if (_currentQuery != null && _currentQuery!.isNotEmpty)
              _buildResultsHeader(t),

            // Filter chips
            OptimizedFilterChips(
              controller: _controller,
              useRemote: _shouldUseRemote(),
              onFilterChanged: _onFiltersChanged,
            ),
            Gaps.h8,

            // Performance metrics (debug only)
            if (kDebugMode) _buildPerformanceMetrics(),

            // Ideas list
            Expanded(
              child: OptimizedIdeasList(
                controller: _controller,
                useRemote: _shouldUseRemote(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildRefreshFAB(t),
    );
  }

  Widget _buildSearchBar(AppLocalizations t) {
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search travel ideas...',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmitted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Text(
              '${t.resultsFor}: "$_currentQuery" (${_controller.totalResults} results)',
              style: Theme.of(context).textTheme.titleMedium,
            );
          },
        ),
        Gaps.h16,
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final metrics = _controller.getPerformanceMetrics();
        return Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: Insets.allSm,
            child: Text(
              'Debug: Cache: ${metrics['cacheSize']}, Page: ${metrics['currentPage']}, '
              'Total: ${metrics['totalResults']}, Loading: ${metrics['isLoading']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRefreshFAB(AppLocalizations t) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return FloatingActionButton(
            onPressed: null,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return FloatingActionButton(
          onPressed: _onRefresh,
          tooltip: 'Refresh results',
          child: const Icon(Icons.refresh),
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    // The controller handles debouncing internally
    _controller.search(
      query: value.isEmpty ? null : value,
      useRemote: _shouldUseRemote(),
    );
  }

  void _onSearchSubmitted(String value) {
    setState(() {
      _currentQuery = value.isEmpty ? null : value;
    });

    // Update URL to reflect search
    _updateUrlWithQuery(value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = null;
    });

    _controller.search(query: null, useRemote: _shouldUseRemote());

    _updateUrlWithQuery('');
  }

  void _onFiltersChanged() {
    // Filters automatically trigger search through the controller
    // No additional action needed
  }

  void _onRefresh() {
    _controller.refresh(useRemote: _shouldUseRemote());
  }

  void _updateUrlWithQuery(String query) {
    final uri = GoRouterState.of(context).uri;
    final newParams = Map<String, String>.from(uri.queryParameters);

    if (query.isEmpty) {
      newParams.remove('q');
    } else {
      newParams['q'] = query;
    }

    final newUri = uri.replace(queryParameters: newParams);
    context.go(newUri.toString());
  }
}

/// Navigation helper for the optimized explore widgets
class ExploreNavigation {
  static void navigateToPlanning(
    BuildContext context,
    String ideaId,
    String title,
    Set<String> tags,
  ) {
    context.pushNamed(
      'plan',
      extra: PlanTripArgs(ideaId: ideaId, title: title, tags: tags),
    );
  }
}
