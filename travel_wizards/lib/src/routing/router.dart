import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:travel_wizards/src/routing/nav_shell.dart';
import 'package:travel_wizards/src/routing/transitions.dart';
import 'package:travel_wizards/src/data/onboarding_state.dart';
import 'package:travel_wizards/src/services/navigation_service.dart';
import 'package:travel_wizards/src/screens/brainstorm/brainstorm_screen.dart';
import 'package:travel_wizards/src/screens/email_login_screen.dart';
import 'package:travel_wizards/src/screens/explore_screen.dart';
import 'package:travel_wizards/src/screens/home_screen.dart';
import 'package:travel_wizards/src/screens/login_landing_screen.dart';
import 'package:travel_wizards/src/screens/onboarding/onboarding_screen.dart';
import 'package:travel_wizards/src/screens/map/map_screen.dart';
import 'package:travel_wizards/src/screens/payments/budget_screen.dart';
import 'package:travel_wizards/src/screens/payments/payment_history_screen.dart';
import 'package:travel_wizards/src/screens/settings/appearance/appearance_settings_screen.dart';
import 'package:travel_wizards/src/screens/settings/accessibility_settings_screen.dart';
import 'package:travel_wizards/src/screens/settings/language/language_settings_screen.dart';
import 'package:travel_wizards/src/screens/settings/permissions/permissions_screen.dart';
import 'package:travel_wizards/src/screens/settings/privacy/privacy_settings_screen.dart';
import 'package:travel_wizards/src/screens/settings/profile/profile_screen.dart';
import 'package:travel_wizards/src/screens/settings/subscription/subscription_settings_screen.dart';
import 'package:travel_wizards/src/screens/settings/payments/payment_options_screen.dart';
import 'package:travel_wizards/src/screens/concierge/enhanced_concierge_chat_screen.dart';
import 'package:travel_wizards/src/screens/settings/tickets/tickets_screen.dart';
import 'package:travel_wizards/src/screens/settings_screen.dart';
import 'package:travel_wizards/src/screens/static/not_found_screen.dart';
import 'package:travel_wizards/src/screens/static/static_about_screen.dart';
import 'package:travel_wizards/src/screens/static/static_faq_screen.dart';
import 'package:travel_wizards/src/screens/static/static_feedback_screen.dart';
import 'package:travel_wizards/src/screens/static/static_help_screen.dart';
import 'package:travel_wizards/src/screens/static/static_legal_screen.dart';
import 'package:travel_wizards/src/screens/static/static_tutorials_screen.dart';
import 'package:travel_wizards/src/screens/trip/drafts_screen.dart';
import 'package:travel_wizards/src/screens/trip/trip_execution_screen.dart';
import 'package:travel_wizards/src/screens/notifications/notifications_screen.dart';
import 'package:travel_wizards/src/screens/emergency/emergency_screen.dart';
import 'package:travel_wizards/src/screens/social/social_features_screen.dart';
import 'package:travel_wizards/src/screens/social/travel_buddies_screen.dart';
import 'package:travel_wizards/src/screens/booking/booking_details_screen.dart';
import 'package:travel_wizards/src/screens/booking/enhanced_bookings_screen.dart';
import 'dart:async';

import 'package:travel_wizards/src/screens/trip/plan_trip_screen.dart';
import 'package:travel_wizards/src/screens/trip/trip_details_screen.dart';
import 'package:travel_wizards/src/screens/trip/trip_history_screen.dart';
import 'package:travel_wizards/src/screens/trip/add_to_trip_screen.dart';

final GoRouter appRouter = GoRouter(
  // Listen to Firebase Auth and onboarding state to trigger redirects.
  refreshListenable: CombinedListenable([
    GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    OnboardingState.instance,
  ]),

  // Initialize navigation service
  navigatorKey: GlobalKey<NavigatorState>(),

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
      pageBuilder: (context, state) => fadePage(const OnboardingScreen()),
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
          path: '/home',
          name: 'home_alias',
          redirect: (context, state) => '/',
        ),
        GoRoute(
          path: '/explore',
          name: 'explore',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ExploreScreen()),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => fadePage(const SettingsScreen()),
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
          path: '/brainstorm',
          name: 'brainstorm',
          pageBuilder: (context, state) => fadePage(const BrainstormScreen()),
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
            return fadePage(
              TripExecutionScreen(tripId: id, tripName: tripName),
            );
          },
        ),
        // Drawer standalone pages
        GoRoute(
          path: '/bookings',
          name: 'bookings',
          pageBuilder: (context, state) =>
              fadePage(const EnhancedBookingsScreen()),
        ),
        GoRoute(
          path: '/bookings/:id',
          name: 'booking_details',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? 'unknown';
            return fadePage(BookingDetailsScreen(bookingId: id));
          },
        ),
        GoRoute(
          path: '/tickets',
          name: 'tickets',
          pageBuilder: (context, state) => fadePage(const TicketsScreen()),
        ),
        GoRoute(
          path: '/budget',
          name: 'budget',
          pageBuilder: (context, state) => fadePage(const BudgetScreen()),
        ),
        GoRoute(
          path: '/history',
          name: 'trip_history',
          pageBuilder: (context, state) => fadePage(const TripHistoryScreen()),
        ),
        GoRoute(
          path: '/drafts',
          name: 'drafts',
          pageBuilder: (context, state) => fadePage(const DraftsScreen()),
        ),
        GoRoute(
          path: '/payments',
          name: 'payment_history',
          pageBuilder: (context, state) =>
              fadePage(const PaymentHistoryScreen()),
        ),
        GoRoute(
          path: '/settings/payments',
          name: 'payment_options',
          pageBuilder: (context, state) =>
              fadePage(const PaymentOptionsScreen()),
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
          pageBuilder: (context, state) =>
              fadePage(const NotificationsScreen()),
        ),
        GoRoute(
          path: '/emergency',
          name: 'emergency',
          pageBuilder: (context, state) => fadePage(const EmergencyScreen()),
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
          pageBuilder: (context, state) =>
              fadePage(const TravelBuddiesScreen()),
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
          pageBuilder: (context, state) =>
              fadePage(const StaticFeedbackScreen()),
        ),
        GoRoute(
          path: '/map-demo',
          name: 'map_demo',
          pageBuilder: (context, state) => fadePage(const MapScreen()),
        ),
        GoRoute(
          path: '/settings/appearance',
          name: 'appearance_settings',
          pageBuilder: (context, state) =>
              fadePage(const AppearanceSettingsScreen()),
        ),
        GoRoute(
          path: '/settings/accessibility',
          name: 'accessibility_settings',
          pageBuilder: (context, state) =>
              fadePage(const AccessibilitySettingsScreen()),
        ),
        GoRoute(
          path: '/settings/privacy',
          name: 'privacy_settings',
          pageBuilder: (context, state) =>
              fadePage(const PrivacySettingsScreen()),
        ),
        GoRoute(
          path: '/settings/language',
          name: 'language_settings',
          pageBuilder: (context, state) =>
              fadePage(const LanguageSettingsScreen()),
        ),
        GoRoute(
          path: '/settings/subscriptions',
          name: 'subscription_settings',
          pageBuilder: (context, state) =>
              fadePage(const SubscriptionSettingsScreen()),
        ),
        GoRoute(
          path: '/permissions',
          name: 'permissions',
          pageBuilder: (context, state) => fadePage(const PermissionsScreen()),
        ),
      ],
    ),
  ],
);

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
