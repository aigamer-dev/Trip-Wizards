import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Service to handle navigation enhancements including deep linking,
/// back button behavior, and breadcrumb navigation
class NavigationService {
  static NavigationService? _instance;
  static NavigationService get instance {
    _instance ??= NavigationService._();
    return _instance!;
  }

  NavigationService._();

  // Root navigator key wired into GoRouter
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Attached router instance for imperative navigation helpers
  GoRouter? _router;
  VoidCallback? _routerListener;
  String? _lastTrackedLocation;

  // Navigation history stack for better back navigation
  final List<String> _navigationHistory = [];
  final Map<String, Map<String, String>> _routeParameters = {};

  // Track current navigation context
  String? _currentRoute;
  Map<String, String>? _currentParams;

  /// Attach router instance once it is constructed
  void attachRouter(GoRouter router) {
    if (_routerListener != null && _router != null) {
      _router!.routerDelegate.removeListener(_routerListener!);
    }

    _router = router;

    _routerListener = () {
      final routeInformation = router.routeInformationProvider.value;
      final Uri uri = routeInformation.uri;
      final locationKey = uri.toString();

      if (locationKey == _lastTrackedLocation) {
        return;
      }

      _lastTrackedLocation = locationKey;
      final params = uri.queryParameters.isEmpty
          ? null
          : Map<String, String>.from(uri.queryParameters);

      final path = uri.path.isEmpty ? '/' : uri.path;
      trackNavigation(path, params: params);
    };

    router.routerDelegate.addListener(_routerListener!);

    final initialUri = router.routeInformationProvider.value.uri;
    final initialLocationKey = initialUri.toString();
    if (initialLocationKey.isNotEmpty) {
      _lastTrackedLocation = initialLocationKey;
      final params = initialUri.queryParameters.isEmpty
          ? null
          : Map<String, String>.from(initialUri.queryParameters);
      final path = initialUri.path.isEmpty ? '/' : initialUri.path;
      trackNavigation(path, params: params);
    }
  }

  GoRouter? get router => _router;

  /// Initialize navigation tracking
  void initialize() {
    _navigationHistory.clear();
    _routeParameters.clear();
    _lastTrackedLocation = null;
  }

  /// Track navigation to a route
  void trackNavigation(String route, {Map<String, String>? params}) {
    if (route.isEmpty) {
      route = '/';
    }

    if (route == '/home') {
      route = '/';
    }

    _currentRoute = route;
    _currentParams = params;

    if (route == '/') {
      _navigationHistory.clear();
      _navigationHistory.add(route);
      _routeParameters.clear();

      if (params != null && params.isNotEmpty) {
        _routeParameters[route] = params;
      }

      debugPrint(
        '📍 Navigation tracked: $route (History: ${_navigationHistory.length})',
      );
      return;
    }

    // Add to history if not already the last entry
    if (_navigationHistory.isEmpty || _navigationHistory.last != route) {
      if (_navigationHistory.isEmpty) {
        _navigationHistory.add('/');
      }
      _navigationHistory.add(route);

      // Keep history manageable (max 20 entries)
      if (_navigationHistory.length > 20) {
        _navigationHistory.removeAt(0);
      }
    }

    // Store route parameters for deep linking
    if (params != null) {
      _routeParameters[route] = params;
    }

    debugPrint(
      '📍 Navigation tracked: $route (History: ${_navigationHistory.length})',
    );
  }

  /// Get navigation history
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);

  /// Get current route
  String? get currentRoute => _currentRoute;

  /// Get parameters for a route
  Map<String, String>? getRouteParameters(String route) {
    return _routeParameters[route];
  }

  /// Enhanced back navigation with context awareness
  bool handleBackNavigation(BuildContext context) {
    final GoRouter? router =
        _router ??
        (navigatorKey.currentContext != null
            ? GoRouter.of(navigatorKey.currentContext!)
            : GoRouter.maybeOf(context));

    if (router == null) {
      return false;
    }

    if (_navigationHistory.length <= 1) {
      if (_currentRoute == '/' || _currentRoute == null) {
        return false;
      }
      goHome();
      return true;
    }

    // Remove current route
    _navigationHistory.removeLast();

    // Get previous route
    final previousRoute = _navigationHistory.last;
    final previousParams = _routeParameters[previousRoute];

    debugPrint('⬅️ Smart back navigation to: $previousRoute');

    final String targetLocation;
    if (previousParams != null && previousParams.isNotEmpty) {
      targetLocation = Uri(
        path: previousRoute,
        queryParameters: previousParams,
      ).toString();
    } else {
      targetLocation = previousRoute;
    }

    if (previousRoute == '/' || previousRoute == '/home') {
      goHome();
      return true;
    }

    router.go(targetLocation);
    return true;
  }

  /// Pop current route if possible; otherwise navigate home.
  Future<void> popOrGoHome(BuildContext context) async {
    final navigator = Navigator.of(context);
    final didPop = await navigator.maybePop();
    if (!didPop) {
      goHome();
    }
  }

  /// Navigate directly to the home route and optionally reset history.
  void goHome({Map<String, String>? params, bool resetHistory = true}) {
    final GoRouter? effectiveRouter =
        _router ??
        (navigatorKey.currentContext != null
            ? GoRouter.of(navigatorKey.currentContext!)
            : null);

    final String targetLocation = params != null && params.isNotEmpty
        ? Uri(path: '/', queryParameters: params).toString()
        : '/';

    if (effectiveRouter != null) {
      effectiveRouter.go(targetLocation);
    } else {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }

    if (resetHistory) {
      _navigationHistory.clear();
      _navigationHistory.add('/');
      _routeParameters.clear();
      if (params != null && params.isNotEmpty) {
        _routeParameters['/'] = params;
      }
      _currentRoute = '/';
      _currentParams = params;
      _lastTrackedLocation = targetLocation;
    }
  }

  /// Generate breadcrumb navigation data
  List<BreadcrumbItem> generateBreadcrumbs() {
    final breadcrumbs = <BreadcrumbItem>[];

    for (int i = 0; i < _navigationHistory.length; i++) {
      final route = _navigationHistory[i];
      final isLast = i == _navigationHistory.length - 1;

      breadcrumbs.add(
        BreadcrumbItem(
          title: _getRouteTitleFromPath(route),
          route: route,
          isActive: isLast,
          onTap: isLast ? null : () => _navigateToBreadcrumb(route),
        ),
      );
    }

    return breadcrumbs;
  }

  void _navigateToBreadcrumb(String route) {
    // Remove all routes after the selected breadcrumb
    final targetIndex = _navigationHistory.indexOf(route);
    if (targetIndex != -1) {
      _navigationHistory.removeRange(
        targetIndex + 1,
        _navigationHistory.length,
      );

      // Navigate to the selected route
      // final params = _routeParameters[route];
      // Implementation would depend on your router setup; params can be used when wiring router navigation here.
      debugPrint('🍞 Breadcrumb navigation to: $route');
    }
  }

  /// Generate deep link for current state
  String generateDeepLink() {
    if (_currentRoute == null) return '/';

    String deepLink = _currentRoute!;
    final params = _currentParams;

    if (params != null && params.isNotEmpty) {
      final queryParams = params.entries
          .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
          .join('&');

      if (queryParams.isNotEmpty) {
        deepLink += '?$queryParams';
      }
    }

    return deepLink;
  }

  /// Parse and handle deep link
  bool handleDeepLink(String deepLink) {
    try {
      final uri = Uri.parse(deepLink);
      final path = uri.path;
      final params = uri.queryParameters;

      // Validate deep link
      if (!_isValidRoute(path)) {
        debugPrint('❌ Invalid deep link route: $path');
        return false;
      }

      // Store parameters for the route
      if (params.isNotEmpty) {
        _routeParameters[path] = params.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      }

      debugPrint('🔗 Deep link handled: $path');
      return true;
    } catch (e) {
      debugPrint('❌ Deep link parsing error: $e');
      return false;
    }
  }

  /// Check if a route is valid
  bool _isValidRoute(String route) {
    const validRoutes = [
      '/',
      '/home',
      '/explore',
      '/plan',
      '/brainstorm',
      '/settings',
      '/profile',
      '/bookings',
      '/tickets',
      '/budget',
      '/trips',
      '/concierge',
      '/about',
      '/help',
      '/faq',
    ];

    return validRoutes.any(
      (validRoute) => route == validRoute || route.startsWith('$validRoute/'),
    );
  }

  String _getRouteTitleFromPath(String path) {
    if (path == '/' || path == '/home') return 'Home';
    if (path == '/explore') return 'Explore';
    if (path == '/plan') return 'Plan Trip';
    if (path == '/brainstorm') return 'Brainstorm';
    if (path == '/settings') return 'Settings';
    if (path == '/profile') return 'Profile';
    if (path == '/bookings') return 'Bookings';
    if (path == '/tickets') return 'Tickets';
    if (path == '/budget') return 'Budget';
    if (path.startsWith('/trips/')) return 'Trip Details';
    if (path == '/concierge') return 'AI Concierge';

    // Capitalize and format path
    return path
        .substring(1)
        .split('/')
        .map(
          (segment) => segment.isEmpty
              ? ''
              : '${segment[0].toUpperCase()}${segment.substring(1)}',
        )
        .join(' > ');
  }

  /// Clear navigation history
  void clearHistory() {
    _navigationHistory.clear();
    _routeParameters.clear();
    _lastTrackedLocation = null;
    debugPrint('🗑️ Navigation history cleared');
  }

  /// Get navigation statistics
  Map<String, dynamic> getNavigationStats() {
    return {
      'historyLength': _navigationHistory.length,
      'currentRoute': _currentRoute,
      'trackedRoutes': _routeParameters.keys.length,
      'deepLink': generateDeepLink(),
    };
  }
}

/// Data class for breadcrumb navigation items
class BreadcrumbItem {
  final String title;
  final String route;
  final bool isActive;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    required this.title,
    required this.route,
    this.isActive = false,
    this.onTap,
  });

  @override
  String toString() =>
      'BreadcrumbItem(title: $title, route: $route, isActive: $isActive)';
}

/// Mixin for screens that want to track navigation
mixin NavigationAware<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = GoRouterState.of(context).uri.path;
      final queryParams = GoRouterState.of(context).uri.queryParameters;
      NavigationService.instance.trackNavigation(route, params: queryParams);
    });
  }
}

/// Widget that displays breadcrumb navigation
class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> breadcrumbs;
  final Color? activeColor;
  final Color? inactiveColor;
  final TextStyle? textStyle;
  final Widget? separator;

  const BreadcrumbNavigation({
    super.key,
    required this.breadcrumbs,
    this.activeColor,
    this.inactiveColor,
    this.textStyle,
    this.separator,
  });

  @override
  Widget build(BuildContext context) {
    if (breadcrumbs.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final defaultActiveColor = activeColor ?? theme.colorScheme.primary;
    final defaultInactiveColor =
        inactiveColor ??
        theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt());
    final defaultSeparator =
        separator ??
        Icon(Icons.chevron_right, size: 16, color: defaultInactiveColor);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < breadcrumbs.length; i++) ...[
            _BreadcrumbItemWidget(
              item: breadcrumbs[i],
              activeColor: defaultActiveColor,
              inactiveColor: defaultInactiveColor,
              textStyle: textStyle,
            ),
            if (i < breadcrumbs.length - 1) defaultSeparator,
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbItemWidget extends StatelessWidget {
  final BreadcrumbItem item;
  final Color activeColor;
  final Color inactiveColor;
  final TextStyle? textStyle;

  const _BreadcrumbItemWidget({
    required this.item,
    required this.activeColor,
    required this.inactiveColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle =
        textStyle ?? Theme.of(context).textTheme.bodyMedium;
    final color = item.isActive ? activeColor : inactiveColor;

    if (item.onTap != null) {
      return InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            item.title,
            style: effectiveTextStyle?.copyWith(
              color: color,
              fontWeight: item.isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        item.title,
        style: effectiveTextStyle?.copyWith(
          color: color,
          fontWeight: item.isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

/// Consistent back button that falls back to the home screen when no
/// Navigator stack is available. Use this instead of the default [BackButton]
/// on screens that should ultimately return to home.
class NavigationBackButton extends StatelessWidget {
  const NavigationBackButton({super.key, this.tooltip, this.color});

  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_rounded, color: color),
      tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => NavigationService.instance.popOrGoHome(context),
    );
  }
}
