import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:travel_wizards/src/core/routing/nav_shell.dart';
import 'package:travel_wizards/src/core/routing/transitions.dart';
import 'package:travel_wizards/src/features/authentication/views/screens/email_login_screen.dart';
import 'package:travel_wizards/src/features/authentication/views/screens/login_landing_screen.dart';
import 'package:travel_wizards/src/features/bookings/views/screens/booking_details_screen.dart';
import 'package:travel_wizards/src/features/bookings/views/screens/enhanced_bookings_screen.dart';
import 'package:travel_wizards/src/features/brainstorm/views/screens/brainstorm_screen.dart';
import 'package:travel_wizards/src/features/brainstorm/views/screens/group_chat_screen.dart';
import 'package:travel_wizards/src/features/concierge/views/screens/enhanced_concierge_chat_screen.dart';
import 'package:travel_wizards/src/features/emergency/views/screens/emergency_screen.dart';
import 'package:travel_wizards/src/features/explore/views/screens/enhanced_explore_screen.dart';
import 'package:travel_wizards/src/features/home/views/screens/home_screen.dart';
import 'package:travel_wizards/src/features/maps/views/screens/map_screen.dart';
import 'package:travel_wizards/src/features/notifications/views/screens/notifications_screen.dart';
import 'package:travel_wizards/src/features/onboarding/data/onboarding_state.dart';
import 'package:travel_wizards/src/features/onboarding/views/screens/enhanced_onboarding_screen.dart';
import 'package:travel_wizards/src/features/payments/views/screens/budget_screen.dart';
import 'package:travel_wizards/src/features/payments/views/screens/expenses_screen.dart';
import 'package:travel_wizards/src/features/payments/views/screens/payment_history_screen.dart';
import 'package:travel_wizards/src/features/settings/views/screens/payments/payment_options_screen.dart';
import 'package:travel_wizards/src/features/settings/views/screens/profile/profile_screen.dart';
import 'package:travel_wizards/src/features/settings/views/screens/settings_screen.dart';
import 'package:travel_wizards/src/features/settings/views/screens/tickets/tickets_screen.dart';
import 'package:travel_wizards/src/features/social/views/screens/social_features_screen.dart';
import 'package:travel_wizards/src/features/social/views/screens/travel_buddies_screen.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/add_to_trip_screen.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/drafts_screen.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/trip_details_screen.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/trip_execution_screen.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/trip_history_screen.dart';
import 'package:travel_wizards/src/shared/services/navigation_service.dart';

import 'package:travel_wizards/src/shared/widgets/static_tutorials_screen.dart';

import 'package:travel_wizards/src/features/trip_planning/views/screens/plan_trip_screen.dart';
import 'package:travel_wizards/src/shared/widgets/not_found_screen.dart';
import 'package:travel_wizards/src/shared/widgets/static_about_screen.dart';
import 'package:travel_wizards/src/shared/widgets/static_faq_screen.dart';
import 'package:travel_wizards/src/shared/widgets/static_feedback_screen.dart';
import 'package:travel_wizards/src/shared/widgets/static_help_screen.dart';
import 'package:travel_wizards/src/shared/widgets/static_legal_screen.dart';
import 'package:travel_wizards/src/shared/widgets/travel_components/components_demo.dart';

GoRouter _buildRouter() {
  final router = GoRouter(
    // Listen to Firebase Auth and onboarding state to trigger redirects.
    refreshListenable: CombinedListenable([
      GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
      OnboardingState.instance,
    ]),

    // Initialize navigation service
    navigatorKey: NavigationService.instance.navigatorKey,

    // Enhanced redirect logic with better deep link support
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final path = state.uri.path;
      final hasOnboarded = OnboardingState.instance.hasOnboarded;
      if (kDebugMode) {
        debugPrint(
          '➡️ GoRouter.redirect: path=$path, isLoggedIn=$isLoggedIn, hasOnboarded=$hasOnboarded',
        );
      }
      final isAuthRoute = path == '/login' || path == '/email-login';
      final isOnboardingRoute = path == '/onboarding';

      // Handle deep links for authenticated routes
      if (isLoggedIn && state.uri.queryParameters.isNotEmpty) {
        NavigationService.instance.handleDeepLink(state.uri.toString());
      }

      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // If logged in and trying to access auth pages, send to home.
      if (isLoggedIn && isAuthRoute) return '/';

      // If logged in but hasn't onboarded, force onboarding except on onboarding route
      if ((hasOnboarded == false) && !isOnboardingRoute) {
        return '/onboarding';
      }

      return null;
    },
    errorBuilder: (context, state) => const NotFoundScreen(),

    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => fadePage(const LoginLandingScreen()),
      ),
      GoRoute(
        path: '/email-login',
        name: 'email_login',
        pageBuilder: (context, state) => fadePage(const EmailLoginScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) =>
            fadePage(const EnhancedOnboardingScreen()),
      ),

      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => fadePage(const ProfileScreen()),
      ),
      GoRoute(
        path: '/plan',
        name: 'plan',
        pageBuilder: (context, state) =>
            fadePage(PlanTripScreen(args: state.extra as PlanTripArgs?)),
      ),
      GoRoute(
        path: '/trips/:id',
        name: 'trip_details',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          return fadePage(TripDetailsScreen(tripId: id));
        },
      ),
      GoRoute(
        path: '/trips/:id/execute',
        name: 'trip_execution',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          final tripName = state.uri.queryParameters['tripName'] ?? 'Trip';
          return fadePage(TripExecutionScreen(tripId: id, tripName: tripName));
        },
      ),
      // Drawer standalone pages
      GoRoute(
        path: '/bookings/:id',
        name: 'booking_details',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          return fadePage(BookingDetailsScreen(bookingId: id));
        },
      ),

      GoRoute(
        path: '/settings/payments',
        name: 'payment_options',
        pageBuilder: (context, state) => fadePage(const PaymentOptionsScreen()),
      ),
      GoRoute(
        path: '/concierge',
        name: 'concierge',
        pageBuilder: (context, state) =>
            fadePage(const EnhancedConciergeChatScreen()),
      ),
      GoRoute(
        path: '/add-to-trip',
        name: 'add_to_trip',
        pageBuilder: (context, state) => fadePage(const AddToTripScreen()),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => fadePage(const NotificationsScreen()),
      ),
      GoRoute(
        path: '/emergency',
        name: 'emergency',
        pageBuilder: (context, state) => fadePage(const EmergencyScreen()),
      ),
      GoRoute(
        path: '/group-chat/:tripId',
        name: 'group_chat',
        pageBuilder: (context, state) {
          final tripId = state.pathParameters['tripId'] ?? '';
          final tripName = state.uri.queryParameters['tripName'] ?? 'Trip';
          return fadePage(GroupChatScreen(tripId: tripId, tripName: tripName));
        },
      ),
      GoRoute(
        path: '/expenses/:tripId',
        name: 'expenses',
        pageBuilder: (context, state) {
          final tripId = state.pathParameters['tripId'] ?? '';
          final buddiesParam = state.uri.queryParameters['buddies'] ?? '';
          final buddies = buddiesParam.isEmpty
              ? <String>[]
              : buddiesParam.split(',');
          return fadePage(ExpensesScreen(tripId: tripId, tripBuddies: buddies));
        },
      ),
      // Social Features
      GoRoute(
        path: '/trips/:id/social',
        name: 'trip_social',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          return fadePage(SocialFeaturesScreen(tripId: id));
        },
      ),
      GoRoute(
        path: '/travel-buddies',
        name: 'travel_buddies',
        pageBuilder: (context, state) => fadePage(const TravelBuddiesScreen()),
      ),
      // Static information pages
      GoRoute(
        path: '/about',
        name: 'about',
        pageBuilder: (context, state) => fadePage(const StaticAboutScreen()),
      ),
      GoRoute(
        path: '/legal',
        name: 'legal',
        pageBuilder: (context, state) => fadePage(const StaticLegalScreen()),
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        pageBuilder: (context, state) => fadePage(const StaticHelpScreen()),
      ),
      GoRoute(
        path: '/faq',
        name: 'faq',
        pageBuilder: (context, state) => fadePage(const StaticFaqScreen()),
      ),
      GoRoute(
        path: '/tutorials',
        name: 'tutorials',
        pageBuilder: (context, state) =>
            fadePage(const StaticTutorialsScreen()),
      ),
      GoRoute(
        path: '/feedback',
        name: 'feedback',
        pageBuilder: (context, state) => fadePage(const StaticFeedbackScreen()),
      ),
      GoRoute(
        path: '/components-demo',
        name: 'components_demo',
        pageBuilder: (context, state) => fadePage(const ComponentsDemoPage()),
      ),
      GoRoute(
        path: '/map-demo',
        name: 'map_demo',
        pageBuilder: (context, state) => fadePage(const MapScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => NavShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/explore',
            name: 'explore',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EnhancedExploreScreen()),
          ),
          GoRoute(
            path: '/brainstorm',
            name: 'brainstorm',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BrainstormScreen()),
          ),
          GoRoute(
            path: '/bookings',
            name: 'bookings_shell',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EnhancedBookingsScreen()),
          ),
          GoRoute(
            path: '/tickets',
            name: 'tickets_shell',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TicketsScreen()),
          ),
          GoRoute(
            path: '/budget',
            name: 'budget_shell',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BudgetScreen()),
          ),
          GoRoute(
            path: '/history',
            name: 'trip_history_shell',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TripHistoryScreen()),
          ),
          GoRoute(
            path: '/drafts',
            name: 'drafts_shell',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DraftsScreen()),
          ),
          GoRoute(
            path: '/payments',
            name: 'payment_history_shell',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PaymentHistoryScreen()),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings_shell',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );

  NavigationService.instance.attachRouter(router);
  return router;
}

final GoRouter appRouter = _buildRouter();

// Helper to refresh GoRouter when a Stream emits (e.g., auth state changes)
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      super.notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Utility to combine multiple [Listenable]s into one for GoRouter refreshListenable.
class CombinedListenable extends ChangeNotifier {
  final List<Listenable> _list;
  final List<VoidCallback> _removers = [];
  CombinedListenable(this._list) {
    for (final l in _list) {
      void listener() => notifyListeners();
      l.addListener(listener);
      _removers.add(() => l.removeListener(listener));
    }
  }

  @override
  void dispose() {
    for (final remove in _removers) {
      remove();
    }
    _removers.clear();
    super.dispose();
  }
}
