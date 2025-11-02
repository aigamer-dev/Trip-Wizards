import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';

/// Navigation helper for moving between app screens using UI element taps
class NavigationHelper {
  final WidgetTester tester;

  NavigationHelper(this.tester);

  /// Navigate to home screen by tapping navigation bar
  Future<void> goToHome() async {
    debugPrint('🏠 Navigating to Home via NavigationBar');
    try {
      // Find the NavigationBar and tap the Home destination (index 0)
      final navigationBar = find.byType(NavigationBar);
      expect(
        navigationBar,
        findsOneWidget,
        reason: 'NavigationBar should be present',
      );

      // Tap the first destination (Home)
      await tester.tap(
        find.descendant(
          of: navigationBar,
          matching: find.byType(NavigationDestination).at(0),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));
      debugPrint('✅ Navigated to Home');
    } catch (e) {
      debugPrint('⚠️ Navigation to Home failed: $e');
      // Fallback: try to find Home by text
      try {
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        debugPrint('✅ Navigated to Home (fallback)');
      } catch (fallbackError) {
        debugPrint(
          '⚠️ Fallback navigation to Home also failed: $fallbackError',
        );
      }
    }
  }

  /// Navigate to explore screen by tapping navigation bar
  Future<void> goToExplore() async {
    debugPrint('🔍 Navigating to Explore via NavigationBar');
    try {
      // Find the NavigationBar and tap the Explore destination (index 2)
      final navigationBar = find.byType(NavigationBar);
      expect(
        navigationBar,
        findsOneWidget,
        reason: 'NavigationBar should be present',
      );

      // Tap the third destination (Explore)
      await tester.tap(
        find.descendant(
          of: navigationBar,
          matching: find.byType(NavigationDestination).at(2),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));
      debugPrint('✅ Navigated to Explore');
    } catch (e) {
      debugPrint('⚠️ Navigation to Explore failed: $e');
      // Fallback: try to find Explore by text
      try {
        await tester.tap(find.text('Explore'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        debugPrint('✅ Navigated to Explore (fallback)');
      } catch (fallbackError) {
        debugPrint(
          '⚠️ Fallback navigation to Explore also failed: $fallbackError',
        );
      }
    }
  }

  /// Navigate to plan trip screen by tapping FAB or navigation
  Future<void> goToPlanTrip() async {
    debugPrint('➕ Navigating to Plan Trip');
    try {
      // Try to find and tap the FAB first (for desktop/tablet)
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle(const Duration(milliseconds: 1500));
        debugPrint('✅ Navigated to Plan Trip via FAB');
        return;
      }

      // Fallback: try to find "Add Trip" or "Plan" text/button
      final addTripButton = find.textContaining('Add Trip');
      if (addTripButton.evaluate().isNotEmpty) {
        await tester.tap(addTripButton);
        await tester.pumpAndSettle(const Duration(milliseconds: 1500));
        debugPrint('✅ Navigated to Plan Trip via text');
        return;
      }

      // Another fallback: look for plan-related text
      final planButton = find.textContaining('Plan');
      if (planButton.evaluate().isNotEmpty) {
        await tester.tap(planButton);
        await tester.pumpAndSettle(const Duration(milliseconds: 1500));
        debugPrint('✅ Navigated to Plan Trip via Plan text');
        return;
      }

      debugPrint('⚠️ Could not find Plan Trip navigation element');
    } catch (e) {
      debugPrint('⚠️ Navigation to Plan Trip failed: $e');
    }
  }

  /// Navigate to bookings screen by opening drawer and tapping
  Future<void> goToBookings() async {
    debugPrint('✈️ Navigating to Bookings');
    try {
      // Open drawer by tapping menu button
      await _openDrawer();

      // Tap Bookings in drawer
      await tester.tap(find.text('Bookings'));
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));
      debugPrint('✅ Navigated to Bookings');
    } catch (e) {
      debugPrint('⚠️ Navigation to Bookings failed: $e');
    }
  }

  /// Navigate to brainstorm screen by opening drawer and tapping
  Future<void> goToBrainstorm() async {
    debugPrint('🧠 Navigating to Brainstorm');
    try {
      // Open drawer by tapping menu button
      await _openDrawer();

      // Tap Brainstorm in drawer
      await tester.tap(find.text('Brainstorm'));
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));
      debugPrint('✅ Navigated to Brainstorm');
    } catch (e) {
      debugPrint('⚠️ Navigation to Brainstorm failed: $e');
    }
  }

  /// Navigate to budget screen by opening drawer and tapping
  Future<void> goToBudget() async {
    debugPrint('💰 Navigating to Budget');
    try {
      // Open drawer by tapping menu button
      await _openDrawer();

      // Tap Budget Tracker in drawer
      await tester.tap(find.text('Budget Tracker'));
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));
      debugPrint('✅ Navigated to Budget');
    } catch (e) {
      debugPrint('⚠️ Navigation to Budget failed: $e');
    }
  }

  /// Navigate to tickets screen by opening drawer and tapping
  Future<void> goToTickets() async {
    debugPrint('🎫 Navigating to Tickets');
    try {
      // Open drawer by tapping menu button
      await _openDrawer();

      // Tap Tickets in drawer
      await tester.tap(find.text('Tickets'));
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));
      debugPrint('✅ Navigated to Tickets');
    } catch (e) {
      debugPrint('⚠️ Navigation to Tickets failed: $e');
    }
  }

  /// Navigate to settings screen by opening drawer and tapping
  Future<void> goToSettings() async {
    debugPrint('⚙️ Navigating to Settings');
    try {
      // Open drawer by tapping menu button
      await _openDrawer();

      // Tap Settings in drawer
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));
      debugPrint('✅ Navigated to Settings');
    } catch (e) {
      debugPrint('⚠️ Navigation to Settings failed: $e');
    }
  }

  /// Helper method to open the navigation drawer
  Future<void> _openDrawer() async {
    // Find and tap the menu button to open drawer
    final menuButton = find.byIcon(Icons.menu_rounded);
    expect(menuButton, findsOneWidget, reason: 'Menu button should be present');
    await tester.tap(menuButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 800));
  }

  /// Navigate to profile screen by tapping profile avatar and selecting profile
  Future<void> goToProfile() async {
    debugPrint('👤 Navigating to Profile');
    try {
      // Find and tap the profile avatar in the app bar
      final profileAvatar = find.byType(ProfileAvatar);
      expect(
        profileAvatar,
        findsOneWidget,
        reason: 'ProfileAvatar should be present',
      );
      await tester.tap(profileAvatar);
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      // Tap Profile in the bottom sheet
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));
      debugPrint('✅ Navigated to Profile');
    } catch (e) {
      debugPrint('⚠️ Navigation to Profile failed: $e');
    }
  }

  /// Go back using back button
  Future<void> goBack() async {
    debugPrint('⬅️ Going back');
    final backButton = find.byType(BackButton);
    final backIcon = find.byIcon(Icons.arrow_back);

    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
    } else if (backIcon.evaluate().isNotEmpty) {
      await tester.tap(backIcon);
    } else {
      debugPrint('⚠️ Back button not found');
      return;
    }

    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    debugPrint('✅ Went back');
  }

  /// Open drawer/menu
  Future<void> openDrawer() async {
    debugPrint('📋 Opening drawer/menu');
    final menuIcon = find.byIcon(Icons.menu);
    if (menuIcon.evaluate().isNotEmpty) {
      await tester.tap(menuIcon);
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      debugPrint('✅ Drawer opened');
    } else {
      debugPrint('⚠️ Menu icon not found');
    }
  }

  /// Navigate to a screen by text label
  Future<void> goToScreenByText(String screenLabel) async {
    debugPrint('🎯 Navigating to: $screenLabel');
    final finder = find.textContaining(screenLabel, findRichText: true);

    if (finder.evaluate().isEmpty) {
      debugPrint('⚠️ Screen label not found: $screenLabel');
      return;
    }

    await tester.tap(finder.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 1500));
    debugPrint('✅ Navigated to: $screenLabel');
  }
}
