import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../common/ui/spacing.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/offline_status_widget.dart';
import 'app_bar_title_controller.dart';
// symbols import not needed currently

/// NavShell wraps child routes with a shared Scaffold and bottom NavigationBar.
class NavShell extends StatefulWidget {
  const NavShell({super.key, required this.child});

  final Widget child;

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> with NavigationAware {
  static bool showFabButton = true;
  static int selectedIndex = 0;
  static String pageName = '';
  static bool showBackButton = true;
  static bool showBreadcrumbs = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final path = GoRouterState.of(context).uri.path;
    final width = MediaQuery.of(context).size.width;
    final isMobile = Breakpoints.isMobile(width);

    // Track navigation for enhanced navigation service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queryParams = GoRouterState.of(context).uri.queryParameters;
      NavigationService.instance.trackNavigation(path, params: queryParams);
    });
    // M3 guidance: 24px icons for navigation components.
    String pageTitleForPath(String p) {
      // Map known non-root routes to human-readable titles for the AppBar
      if (p.startsWith('/settings')) return t.settings;
      if (p.startsWith('/profile')) return 'Profile';
      if (p.startsWith('/plan')) return t.addTrip;
      if (p.startsWith('/brainstorm')) return 'Brainstorm';
      if (p.startsWith('/bookings')) return 'Bookings';
      if (p.startsWith('/tickets')) return 'Tickets';
      if (p.startsWith('/budget')) return 'Budget Tracker';
      if (p.startsWith('/trip_history') || p.startsWith('/history')) {
        return 'Full Trip History';
      }
      if (p.startsWith('/drafts')) return 'Drafts';
      if (p.startsWith('/settings/payments')) return 'Payment options';
      if (p.startsWith('/payment_history') || p.startsWith('/payments')) {
        return 'Payment History';
      }
      if (p.startsWith('/about')) return 'About';
      if (p.startsWith('/legal')) return 'Legal';
      if (p.startsWith('/help')) return 'Help';
      if (p.startsWith('/faq')) return 'FAQ';
      if (p.startsWith('/tutorials')) return 'Tutorials';
      if (p.startsWith('/feedback')) return 'Feedback';
      if (p.startsWith('/permissions')) return 'Permissions';
      if (p.startsWith('/settings/appearance')) return 'Appearance';
      if (p.startsWith('/settings/privacy')) return 'Privacy & notifications';
      if (p.startsWith('/settings/language')) return 'Language';
      if (p.startsWith('/settings/subscriptions')) return 'Manage subscription';
      if (p.startsWith('/add-to-trip')) return 'Add to Trip';
      if (p.startsWith('/map-demo')) return 'Map Demo';
      if (p.startsWith('/trips/')) return 'Trip';
      return t.appTitle;
    }

    // Bottom navigation root destinations (phones)
    final List<_NavItem> destinations = [
      _NavItem(
        icon: const Icon(Icons.home_outlined),
        label: t.home,
        onTap: () => context.goNamed('home'),
        selectedIcon: const Icon(Icons.home_filled, fill: 1.0),
        path: path == '/' || path.startsWith('/home') ? '/' : '/home',
        pageName: t.home,
        showFab: true,
        showBackButton: false,
      ),
      _NavItem(
        icon: const Icon(Icons.add),
        label: t.addTrip,
        onTap: () => {context.pushNamed('plan')},
        selectedIcon: const Icon(Icons.add_circle_rounded, fill: 1.0),
        path: '/plan',
        pageName: t.addTrip,
        showFab: false,
        showBackButton: true,
      ),
      _NavItem(
        icon: const Icon(Icons.explore_outlined),
        label: t.explore,
        onTap: () => context.goNamed('explore'),
        selectedIcon: const Icon(Icons.explore_rounded, fill: 1.0),
        path: '/explore',
        pageName: t.explore,
        showFab: true,
        showBackButton: false,
      ),
    ];

    // Determine if current route is part of bottom navigation roots.
    final isRootRoute = destinations.any((d) => path.startsWith(d.path));
    selectedIndex = destinations.indexWhere((d) => path.startsWith(d.path));
    if (!isRootRoute) {
      // For non-root routes, keep a reasonable page title and controls.
      // Default to showing back button and hiding FAB on details/settings pages.
      pageName = pageTitleForPath(path);
      showFabButton = false;
      showBackButton = true;
    } else {
      if (selectedIndex < 0) selectedIndex = 0;
      pageName = destinations[selectedIndex].pageName;
      showFabButton = destinations[selectedIndex].showFab;
      showBackButton = destinations[selectedIndex].showBackButton;
    }

    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: AppBarTitleController.instance,
          builder: (context, _) {
            String effectiveTitle;
            if (path.startsWith('/trips/')) {
              effectiveTitle =
                  AppBarTitleController.instance.override ?? 'Trip';
            } else {
              // Clear override when not on a trip route.
              if (AppBarTitleController.instance.override != null) {
                AppBarTitleController.instance.setOverride(null);
              }
              effectiveTitle = pageName.isEmpty ? t.appTitle : pageName;
            }
            return Semantics(
              label: t.searchPlaceholder,
              textField: true,
              excludeSemantics: true,
              child: Text(effectiveTitle),
            );
          },
        ),
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Try enhanced navigation first, fallback to default
                  if (!NavigationService.instance.handleBackNavigation(
                    context,
                  )) {
                    // Use maybePop so that route-level PopScope can intercept
                    // and show unsaved draft dialog instead of force popping.
                    Navigator.of(context).maybePop();
                  }
                },
              )
            : null,
        actions: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFF4285F4), // Blue
                    Color(0xFF34A853), // Green
                    Color(0xFFFBBC05), // Yellow
                    Color(0xFFEA4335), // Red
                  ],
                ),
              ),
              child: IconButton(
                tooltip: 'Account',
                padding: EdgeInsets.zero,
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    useSafeArea: true,
                    builder: (ctx) => _ProfileQuickSheet(),
                  );
                },
                icon: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  child: FutureBuilder<String?>(
                    future: AuthService.instance.getPreferredAvatarUrl(),
                    builder: (context, snapshot) {
                      final url = snapshot.data;
                      if (url != null && url.isNotEmpty) {
                        return CircleAvatar(backgroundImage: NetworkImage(url));
                      }
                      return const CircleAvatar(
                        child: Icon(Icons.person_rounded),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: isMobile
          ? Column(
              children: [
                const OfflineStatusWidget(),
                Expanded(child: widget.child),
              ],
            )
          : Row(
              children: [
                _ExpandedRail(currentPath: path),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      const OfflineStatusWidget(),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),

      // Navigation Drawer for phones (excludes bottom nav duplicates)
      drawer: isMobile ? _MobileDrawer() : null,
      // Show bottom bar only on root routes; otherwise, hide it to avoid a forced selection.
      bottomNavigationBar: isMobile && isRootRoute
          ? BottomNavigationBar(
              items: [
                for (final d in destinations)
                  BottomNavigationBarItem(
                    icon: d.icon,
                    label: d.label,
                    activeIcon: d.selectedIcon,
                  ),
              ],
              currentIndex: selectedIndex,
              onTap: (i) => destinations[i].onTap(),
            )
          : null,

      floatingActionButton: !isMobile
          ? showFabButton
                ? FloatingActionButton(
                    tooltip: t.addTrip,
                    onPressed: () => context.pushNamed('plan'),
                    child: const Icon(Icons.add),
                  )
                : null
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }
}

class _ProfileQuickSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.instance.getPreferredAvatarUrl(),
      builder: (context, snap) {
        final avatarUrl = snap.data;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person_rounded)
                      : null,
                ),
                title: const Text('Your profile'),
                subtitle: const Text('View or edit account details'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.of(context).pop();
                  GoRouter.of(context).pushNamed('profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  GoRouter.of(context).pushNamed('settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium_rounded),
                title: const Text('Subscription'),
                onTap: () {
                  Navigator.of(context).pop();
                  GoRouter.of(context).pushNamed('subscription_settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_rounded),
                title: const Text('Help'),
                onTap: () {
                  Navigator.of(context).pop();
                  GoRouter.of(context).pushNamed('help');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out (dummy)')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.pageName,
    required this.path,
    this.selectedIcon,
    this.showFab = true,
    this.showBackButton = false,
  });
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final String pageName;
  final String path;
  final Widget? selectedIcon;
  final bool showFab;
  final bool showBackButton;
}

class _MobileDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: Insets.h(16),
              child: Text(
                'Plan & AI',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bolt_rounded),
              title: const Text('Brainstorm'),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed('brainstorm');
              },
            ),
            const Divider(height: 8),
            Padding(
              padding: Insets.h(16),
              child: Text(
                'Trips',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.book_rounded),
              title: const Text('Bookings'),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed('bookings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_number_rounded),
              title: const Text('Tickets'),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed('tickets');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded),
              title: const Text('Budget Tracker'),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed('budget');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Full Trip History'),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed('trip_history');
              },
            ),
            ListTile(
              leading: const Icon(Icons.drafts_rounded),
              title: const Text('Drafts'),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed('drafts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: const Text('Payment History'),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed('payment_history');
              },
            ),
            const Divider(height: 8),
            Padding(
              padding: Insets.h(16),
              child: Text(
                t.settings,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: Text(t.settings),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed('settings');
              },
            ),
            const Divider(height: 8),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out (dummy)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedRail extends StatelessWidget {
  const _ExpandedRail({required this.currentPath});
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Determine selected index for rail (include more destinations on wide screens)
    final railItems = <_RailItem>[
      _RailItem(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_filled, fill: 1.0),
        label: t.home,
        matches: (p) => p == '/' || p.startsWith('/home'),
        onTap: () => context.goNamed('home'),
      ),
      _RailItem(
        icon: const Icon(Icons.explore_outlined),
        selectedIcon: const Icon(Icons.explore_rounded, fill: 1.0),
        label: t.explore,
        matches: (p) => p.startsWith('/explore'),
        onTap: () => context.goNamed('explore'),
      ),
      _RailItem(
        icon: const Icon(Icons.bolt_rounded),
        selectedIcon: const Icon(Icons.bolt_rounded),
        label: 'Brainstorm',
        matches: (p) => p.startsWith('/brainstorm'),
        onTap: () => context.goNamed('brainstorm'),
      ),
      _RailItem(
        icon: const Icon(Icons.book_rounded),
        selectedIcon: const Icon(Icons.book_rounded),
        label: 'Bookings',
        matches: (p) => p.startsWith('/bookings'),
        onTap: () => context.goNamed('bookings'),
      ),
      _RailItem(
        icon: const Icon(Icons.confirmation_number_rounded),
        selectedIcon: const Icon(Icons.confirmation_number_rounded),
        label: 'Tickets',
        matches: (p) => p.startsWith('/tickets'),
        onTap: () => context.goNamed('tickets'),
      ),
      _RailItem(
        icon: const Icon(Icons.account_balance_wallet_rounded),
        selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
        label: 'Budget',
        matches: (p) => p.startsWith('/budget'),
        onTap: () => context.goNamed('budget'),
      ),
      _RailItem(
        icon: const Icon(Icons.history_rounded),
        selectedIcon: const Icon(Icons.history_rounded),
        label: 'History',
        matches: (p) => p.startsWith('/trip_history'),
        onTap: () => context.goNamed('trip_history'),
      ),
      _RailItem(
        icon: const Icon(Icons.drafts_rounded),
        selectedIcon: const Icon(Icons.drafts_rounded),
        label: 'Drafts',
        matches: (p) => p.startsWith('/drafts'),
        onTap: () => context.goNamed('drafts'),
      ),
      _RailItem(
        icon: const Icon(Icons.receipt_long_rounded),
        selectedIcon: const Icon(Icons.receipt_long_rounded),
        label: 'Payments',
        matches: (p) => p.startsWith('/payment_history'),
        onTap: () => context.goNamed('payment_history'),
      ),
      _RailItem(
        icon: const Icon(Icons.settings_rounded),
        selectedIcon: const Icon(Icons.settings_rounded),
        label: t.settings,
        matches: (p) => p.startsWith('/settings') || p.startsWith('/profile'),
        onTap: () => context.goNamed('settings'),
      ),
    ];

    int sel = railItems.indexWhere((it) => it.matches(currentPath));
    if (sel < 0) sel = 0; // default highlight Home only when unknown

    return NavigationRail(
      extended: true,
      selectedIndex: sel,
      onDestinationSelected: (i) => railItems[i].onTap(),
      labelType: NavigationRailLabelType.none,
      destinations: [
        for (final it in railItems)
          NavigationRailDestination(
            icon: it.icon,
            label: Text(it.label),
            selectedIcon: it.selectedIcon,
          ),
      ],
    );
  }
}

class _RailItem {
  const _RailItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.matches,
    required this.onTap,
  });
  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final bool Function(String path) matches;
  final VoidCallback onTap;
}
