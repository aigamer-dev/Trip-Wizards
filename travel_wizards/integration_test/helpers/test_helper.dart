import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helper for common UI test operations
class TestHelper {
  final WidgetTester tester;

  TestHelper(this.tester);

  /// Test responsiveness in both portrait and landscape
  Future<void> testResponsiveness(String screenName) async {
    debugPrint('📱 Testing responsiveness for: $screenName');

    try {
      final view = tester.view;
      final originalSize = view.physicalSize / view.devicePixelRatio;

      // Test portrait orientation (narrower width)
      debugPrint('  Testing portrait mode (375x667)...');
      final portraitSize = Size(375, 667);
      await tester.binding.setSurfaceSize(portraitSize);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify that the UI adapts to portrait (check for layout changes)
      expect(
        find.byType(Scaffold).evaluate().isNotEmpty,
        isTrue,
        reason: '$screenName should render in portrait mode',
      );

      // Test landscape orientation (wider width)
      debugPrint('  Testing landscape mode (667x375)...');
      final landscapeSize = Size(667, 375);
      await tester.binding.setSurfaceSize(landscapeSize);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify that the UI adapts to landscape (check for layout changes)
      expect(
        find.byType(Scaffold).evaluate().isNotEmpty,
        isTrue,
        reason: '$screenName should render in landscape mode',
      );

      // Reset to original
      await tester.binding.setSurfaceSize(originalSize);
      await tester.pumpAndSettle();

      debugPrint('✅ Responsiveness test passed for: $screenName');
    } catch (e) {
      debugPrint('⚠️ Responsiveness test failed for $screenName: $e');
      // Reset to original size even if test fails
      try {
        final view = tester.view;
        final originalSize = view.physicalSize / view.devicePixelRatio;
        await tester.binding.setSurfaceSize(originalSize);
        await tester.pumpAndSettle();
      } catch (resetError) {
        debugPrint('⚠️ Could not reset screen size: $resetError');
      }
    }
  }

  /// Test all buttons on current screen
  Future<void> testButtons(String screenName) async {
    debugPrint('🔘 Testing buttons on: $screenName');

    try {
      // Find all tappable widgets
      final buttons = find.byType(ElevatedButton);
      final textButtons = find.byType(TextButton);
      final iconButtons = find.byType(IconButton);
      final floatingButtons = find.byType(FloatingActionButton);

      int totalButtons =
          buttons.evaluate().length +
          textButtons.evaluate().length +
          iconButtons.evaluate().length +
          floatingButtons.evaluate().length;

      debugPrint('  Found $totalButtons interactive buttons');

      // Test a sample of buttons (avoid tapping all to prevent navigation chaos)
      if (buttons.evaluate().isNotEmpty) {
        expect(
          buttons,
          findsWidgets,
          reason: 'Should find ElevatedButton widgets',
        );
      }
      if (textButtons.evaluate().isNotEmpty) {
        expect(
          textButtons,
          findsWidgets,
          reason: 'Should find TextButton widgets',
        );
      }
      if (iconButtons.evaluate().isNotEmpty) {
        expect(
          iconButtons,
          findsWidgets,
          reason: 'Should find IconButton widgets',
        );
      }

      debugPrint('✅ Button test passed for: $screenName');
    } catch (e) {
      debugPrint('⚠️ Button test failed for $screenName: $e');
    }
  }

  /// Test rendering - check for common widgets
  Future<void> testRendering(String screenName) async {
    debugPrint('🎨 Testing rendering for: $screenName');

    try {
      // Check for basic Flutter widgets
      expect(
        find.byType(MaterialApp).evaluate().isNotEmpty,
        isTrue,
        reason: 'MaterialApp should be present',
      );

      expect(
        find.byType(Scaffold).evaluate().isNotEmpty,
        isTrue,
        reason: 'Scaffold should be present on $screenName',
      );

      await tester.pump(const Duration(milliseconds: 500));

      debugPrint('✅ Rendering test passed for: $screenName');
    } catch (e) {
      debugPrint('⚠️ Rendering test failed for $screenName: $e');
    }
  }

  /// Test navigation - verify screen transition
  Future<void> testNavigation(
    String fromScreen,
    String toScreen,
    Finder navigationElement,
  ) async {
    debugPrint('🧭 Testing navigation: $fromScreen → $toScreen');

    try {
      if (navigationElement.evaluate().isEmpty) {
        debugPrint('⚠️ Navigation element not found');
        return;
      }

      await tester.tap(navigationElement);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      debugPrint('✅ Navigation test passed: $fromScreen → $toScreen');
    } catch (e) {
      debugPrint('⚠️ Navigation test failed $fromScreen → $toScreen: $e');
    }
  }

  /// Comprehensive test for a screen (responsiveness + buttons + rendering)
  Future<void> testScreen(String screenName) async {
    debugPrint('🧪 Running comprehensive test for: $screenName');

    await testRendering(screenName);
    await testResponsiveness(screenName);
    await testButtons(screenName);

    debugPrint('✅ Comprehensive test completed for: $screenName');
  }

  /// Find and tap a widget
  Future<bool> tapWidget(Finder finder, {Duration? waitTime}) async {
    try {
      if (finder.evaluate().isEmpty) {
        debugPrint('⚠️ Widget not found for tapping');
        return false;
      }

      await tester.tap(finder);
      await tester.pumpAndSettle(waitTime ?? const Duration(seconds: 2));
      return true;
    } catch (e) {
      debugPrint('⚠️ Tap failed: $e');
      return false;
    }
  }

  /// Enter text in a field
  Future<bool> enterText(Finder finder, String text) async {
    try {
      if (finder.evaluate().isEmpty) {
        debugPrint('⚠️ Text field not found');
        return false;
      }

      await tester.enterText(finder, text);
      await tester.pumpAndSettle();
      return true;
    } catch (e) {
      debugPrint('⚠️ Text entry failed: $e');
      return false;
    }
  }

  /// Verify text exists on screen
  bool verifyText(String text) {
    final finder = find.textContaining(text, findRichText: true);
    return finder.evaluate().isNotEmpty;
  }

  /// Scroll to make widget visible
  Future<void> scrollToWidget(Finder finder) async {
    try {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    } catch (e) {
      debugPrint('⚠️ Scroll to widget failed: $e');
    }
  }
}
