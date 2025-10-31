import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/shared/services/auth_service.dart';
import 'package:travel_wizards/src/shared/services/navigation_service.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';
import 'package:travel_wizards/src/shared/widgets/offline_status_widget.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import '../l10n/app_localizations.dart';
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
  // Breadcrumbs are currently unused; keep scaffold simple for hackathon build.
  late final SearchController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final path = GoRouterState.of(context).uri.path;
    final width = MediaQuery.of(context).size.width;
    final isMobile = Breakpoints.isMobile(width);
    final safeTop = MediaQuery.of(context).padding.top;
    final headerOffset = safeTop + (isMobile ? 84 : 96) + 72 + 12;

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
      if (p.startsWith('/history')) return 'Full Trip History';
      if (p.startsWith('/drafts')) return 'Drafts';
      if (p.startsWith('/payments')) return 'Payment History';
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
        path: '/',
        pageName: t.home,
        showFab: true,
        showBackButton: false,
      ),
      _NavItem(
        icon: const Icon(Icons.add),
        label: t.addTrip,
        onTap: () {
          context.pushNamed('plan');
        },
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
    bool matchesDestination(String currentPath, String destinationPath) {
      if (destinationPath == '/') {
        return currentPath == '/' || currentPath == '/home';
      }
      return currentPath == destinationPath ||
          currentPath.startsWith('$destinationPath/');
    }

    final isRootRoute = destinations.any(
      (d) => matchesDestination(path, d.path),
    );
    selectedIndex = destinations.indexWhere(
      (d) => matchesDestination(path, d.path),
    );
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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // For desktop/tablet, use a different layout without AppBar in body
    if (!isMobile) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: Row(
          children: [
            // Fixed width navigation rail area
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border(
                  right: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Header area with branding
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.travel_explore,
                            color: scheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Travel Wizards',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Navigation rail
                  Expanded(child: _VerticalNavigationMenu(currentPath: path)),
                ],
              ),
            ),
            // Main content area
            Expanded(
              child: Column(
                children: [
                  // Top bar with search and actions
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Search bar - make it more responsive
                        Expanded(
                          flex: 2,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: SearchBar(
                              controller: _searchController,
                              hintText:
                                  'Search destinations, trips, and travelers',
                              leading: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.search),
                              ),
                              elevation: const WidgetStatePropertyAll(0),
                              backgroundColor: WidgetStatePropertyAll(
                                scheme.surfaceContainerHigh,
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onTap: () {
                                // TODO: Implement search
                              },
                            ),
                          ),
                        ),
                        // Action buttons - wrap in responsive container
                        Flexible(
                          flex: 1,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Notifications',
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                  ),
                                  onPressed: () =>
                                      context.pushNamed('notifications'),
                                ),
                                IconButton(
                                  tooltip: 'Saved ideas',
                                  icon: const Icon(
                                    Icons.favorite_outline_rounded,
                                  ),
                                  onPressed: () => context.pushNamed('drafts'),
                                ),
                                const SizedBox(width: 8),
                                FutureBuilder<String?>(
                                  future: AuthService.instance
                                      .getPreferredAvatarUrl(),
                                  builder: (context, snapshot) {
                                    final url = snapshot.data;
                                    return IconButton(
                                      tooltip: 'Account',
                                      icon: ProfileAvatar(
                                        photoUrl: url,
                                        size: 40,
                                        backgroundColor:
                                            scheme.primaryContainer,
                                        iconColor: scheme.onPrimaryContainer,
                                        semanticLabel: 'Open account menu',
                                      ),
                                      onPressed: () async {
                                        await showModalBottomSheet(
                                          context: context,
                                          showDragHandle: true,
                                          useSafeArea: true,
                                          builder: (ctx) =>
                                              _ProfileQuickSheet(),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content area
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey(path),
                        child: widget.child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: showFabButton
            ? Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 16),
                child: FloatingActionButton.extended(
                  onPressed: () => context.pushNamed('plan'),
                  label: Text(t.addTrip),
                  icon: const Icon(Icons.add_rounded),
                  elevation: 2,
                  extendedPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 0,
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    }

    // Mobile layout with AppBar
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: isMobile ? 84 : 96,
        leadingWidth: 64,
        systemOverlayStyle: scheme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: showBackButton && (!isRootRoute || isMobile)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (!NavigationService.instance.handleBackNavigation(
                    context,
                  )) {
                    Navigator.of(context).maybePop();
                  }
                },
              )
            : isMobile && isRootRoute
            ? Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  tooltip: 'Open navigation',
                ),
              )
            : null,
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.surface.withValues(alpha: 0.88),
                    scheme.surface.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        title: isMobile || !isRootRoute
            ? AnimatedBuilder(
                animation: AppBarTitleController.instance,
                builder: (context, _) {
                  String effectiveTitle;
                  if (path.startsWith('/trips/')) {
                    effectiveTitle =
                        AppBarTitleController.instance.override ?? 'Trip';
                  } else {
                    if (AppBarTitleController.instance.override != null) {
                      AppBarTitleController.instance.setOverride(null);
                    }
                    effectiveTitle = pageName.isEmpty ? t.appTitle : pageName;
                  }
                  return Text(
                    effectiveTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.pushNamed('notifications'),
          ),
          IconButton(
            tooltip: 'Saved ideas',
            icon: const Icon(Icons.favorite_outline_rounded),
            onPressed: () => context.pushNamed('drafts'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FutureBuilder<String?>(
              future: AuthService.instance.getPreferredAvatarUrl(),
              builder: (context, snapshot) {
                final url = snapshot.data;
                return IconButton(
                  tooltip: 'Account',
                  icon: ProfileAvatar(
                    photoUrl: url,
                    size: 40,
                    backgroundColor: scheme.primaryContainer,
                    iconColor: scheme.onPrimaryContainer,
                    semanticLabel: 'Open account menu',
                  ),
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      useSafeArea: true,
                      builder: (ctx) => _ProfileQuickSheet(),
                    );
                  },
                );
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 20 : 12, 0, 20, 16),
            child: SearchAnchor.bar(
              searchController: _searchController,
              barHintText: 'Search destinations, trips, and travelers',
              barLeading: const Icon(Icons.search_rounded),
              onSubmitted: (value) => _handleSearch(context, value),
              suggestionsBuilder: (context, controller) =>
                  _buildSearchSuggestions(context, controller),
            ),
          ),
        ),
      ),
      drawer: isMobile ? _MobileDrawer() : null,
      body: ColoredBox(
        color: scheme.surface,
        child: isMobile
            ? Column(
                children: [
                  SizedBox(height: headerOffset),
                  const OfflineStatusWidget(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey(path),
                            child: widget.child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    child: KeyedSubtree(
                      key: ValueKey('rail-$path'),
                      child: _ExpandedRail(currentPath: path),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: headerOffset),
                        const OfflineStatusWidget(),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 16, 24, 24),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 320),
                                switchInCurve: Curves.easeOutBack,
                                switchOutCurve: Curves.easeIn,
                                child: KeyedSubtree(
                                  key: ValueKey(path),
                                  child: widget.child,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: isMobile && isRootRoute
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => destinations[i].onTap(),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    label: d.label,
                    icon: d.icon,
                    selectedIcon: d.selectedIcon ?? d.icon,
                  ),
              ],
            )
          : null,
      floatingActionButton: !isMobile && showFabButton
          ? Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: FloatingActionButton.extended(
                onPressed: () => context.pushNamed('plan'),
                label: Text(t.addTrip),
                icon: const Icon(Icons.add_rounded),
                elevation: 2,
                extendedPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  void _handleSearch(BuildContext context, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchController.closeView(trimmed);
    context.goNamed('explore', queryParameters: {'q': trimmed});
  }

  Iterable<Widget> _buildSearchSuggestions(
    BuildContext context,
    SearchController controller,
  ) {
    final options = <_SearchSuggestion>[
      _SearchSuggestion(
        label: 'Upcoming trips overview',
        icon: Icons.flight_takeoff_rounded,
        action: (ctx) => ctx.goNamed('home'),
      ),
      _SearchSuggestion(
        label: 'Brainstorm ideas with AI',
        icon: Icons.auto_awesome_rounded,
        action: (ctx) => ctx.goNamed('brainstorm'),
      ),
      _SearchSuggestion(
        label: 'Plan a new getaway',
        icon: Icons.add_location_alt_rounded,
        action: (ctx) => ctx.pushNamed('plan'),
      ),
      _SearchSuggestion(
        label: 'Review bookings',
        icon: Icons.receipt_long_rounded,
        action: (ctx) => ctx.goNamed('bookings'),
      ),
      _SearchSuggestion(
        label: 'Trip history timeline',
        icon: Icons.history_rounded,
        action: (ctx) => ctx.goNamed('trip_history'),
      ),
      _SearchSuggestion(
        label: 'Travel buddies',
        icon: Icons.group_rounded,
        action: (ctx) => ctx.goNamed('travel_buddies'),
      ),
    ];

    final query = controller.text.trim().toLowerCase();

    return options
        .where(
          (option) =>
              query.isEmpty || option.label.toLowerCase().contains(query),
        )
        .map(
          (option) => ListTile(
            leading: Icon(option.icon),
            title: Text(option.label),
            onTap: () {
              controller.closeView(option.label);
              option.action(context);
            },
          ),
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
                leading: ProfileAvatar(
                  photoUrl: avatarUrl,
                  size: 48,
                  icon: Icons.person_rounded,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  semanticLabel: 'Your profile avatar',
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
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    await AuthService.instance.signOut();
                    if (context.mounted) {
                      GoRouter.of(context).go('/login');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
                    }
                  }
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
              onTap: () async {
                Navigator.of(context).pop();
                try {
                  await AuthService.instance.signOut();
                  if (context.mounted) {
                    GoRouter.of(context).go('/login');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Vertical navigation menu for desktop layout
class _VerticalNavigationMenu extends StatelessWidget {
  const _VerticalNavigationMenu({required this.currentPath});
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final menuItems = [
      _MenuItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_filled,
        label: t.home,
        path: '/',
        onTap: () => context.goNamed('home'),
      ),
      _MenuItem(
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore_rounded,
        label: t.explore,
        path: '/explore',
        onTap: () => context.goNamed('explore'),
      ),
      _MenuItem(
        icon: Icons.bolt_rounded,
        selectedIcon: Icons.bolt_rounded,
        label: 'Brainstorm',
        path: '/brainstorm',
        onTap: () => context.goNamed('brainstorm'),
      ),
      _MenuItem(
        icon: Icons.book_rounded,
        selectedIcon: Icons.book_rounded,
        label: 'Bookings',
        path: '/bookings',
        onTap: () => context.goNamed('bookings_shell'),
      ),
      _MenuItem(
        icon: Icons.confirmation_number_rounded,
        selectedIcon: Icons.confirmation_number_rounded,
        label: 'Tickets',
        path: '/tickets',
        onTap: () => context.goNamed('tickets_shell'),
      ),
      _MenuItem(
        icon: Icons.account_balance_wallet_rounded,
        selectedIcon: Icons.account_balance_wallet_rounded,
        label: 'Budget',
        path: '/budget',
        onTap: () => context.goNamed('budget_shell'),
      ),
      _MenuItem(
        icon: Icons.history_rounded,
        selectedIcon: Icons.history_rounded,
        label: 'History',
        path: '/history',
        onTap: () => context.goNamed('trip_history_shell'),
      ),
      _MenuItem(
        icon: Icons.drafts_rounded,
        selectedIcon: Icons.drafts_rounded,
        label: 'Drafts',
        path: '/drafts',
        onTap: () => context.goNamed('drafts_shell'),
      ),
      _MenuItem(
        icon: Icons.receipt_long_rounded,
        selectedIcon: Icons.receipt_long_rounded,
        label: 'Payments',
        path: '/payments',
        onTap: () => context.goNamed('payment_history_shell'),
      ),
      _MenuItem(
        icon: Icons.settings_rounded,
        selectedIcon: Icons.settings_rounded,
        label: t.settings,
        path: '/settings',
        onTap: () => context.goNamed('settings'),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final item in menuItems)
          _NavigationMenuItem(
            item: item,
            isSelected:
                currentPath.startsWith(item.path) ||
                (item.path == '/' && currentPath == '/'),
          ),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.path,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;
  final VoidCallback onTap;
}

class _NavigationMenuItem extends StatelessWidget {
  const _NavigationMenuItem({required this.item, required this.isSelected});

  final _MenuItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.secondaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 24,
                  color: isSelected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
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
        onTap: () => context.goNamed('bookings_shell'),
      ),
      _RailItem(
        icon: const Icon(Icons.confirmation_number_rounded),
        selectedIcon: const Icon(Icons.confirmation_number_rounded),
        label: 'Tickets',
        matches: (p) => p.startsWith('/tickets'),
        onTap: () => context.goNamed('tickets_shell'),
      ),
      _RailItem(
        icon: const Icon(Icons.account_balance_wallet_rounded),
        selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
        label: 'Budget',
        matches: (p) => p.startsWith('/budget'),
        onTap: () => context.goNamed('budget_shell'),
      ),
      _RailItem(
        icon: const Icon(Icons.history_rounded),
        selectedIcon: const Icon(Icons.history_rounded),
        label: 'History',
        matches: (p) => p.startsWith('/history'),
        onTap: () => context.goNamed('trip_history_shell'),
      ),
      _RailItem(
        icon: const Icon(Icons.drafts_rounded),
        selectedIcon: const Icon(Icons.drafts_rounded),
        label: 'Drafts',
        matches: (p) => p.startsWith('/drafts'),
        onTap: () => context.goNamed('drafts_shell'),
      ),
      _RailItem(
        icon: const Icon(Icons.receipt_long_rounded),
        selectedIcon: const Icon(Icons.receipt_long_rounded),
        label: 'Payments',
        matches: (p) => p.startsWith('/payments'),
        onTap: () => context.goNamed('payment_history_shell'),
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

    final colorScheme = Theme.of(context).colorScheme;

    final rail = NavigationRail(
      extended: true,
      selectedIndex: sel,
      onDestinationSelected: (i) => railItems[i].onTap(),
      labelType: NavigationRailLabelType.none,
      minWidth: 88,
      groupAlignment: -0.2,
      leading: const SizedBox(height: 16),
      destinations: [
        for (final it in railItems)
          NavigationRailDestination(
            icon: it.icon,
            label: Text(it.label),
            selectedIcon: it.selectedIcon,
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
      ],
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: rail,
      ),
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

class _SearchSuggestion {
  const _SearchSuggestion({
    required this.label,
    required this.icon,
    required this.action,
  });

  final String label;
  final IconData icon;
  final void Function(BuildContext context) action;
}
