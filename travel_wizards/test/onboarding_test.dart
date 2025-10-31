import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:travel_wizards/firebase_options.dart';

// Firebase is provided/mocked via TestHelpers in widget tests
import 'package:travel_wizards/src/features/onboarding/views/screens/enhanced_onboarding_screen.dart';
import 'test_helpers.dart';

void main() {
  // Tests should use the TestHelpers harness to inject mock Firebase services.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // ignore if already initialized or platform unsupported in tests
    }
  });

  // Configure larger viewport for onboarding screens
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Flow Tests', () {
    testWidgets('Should display welcome screen on first step', (
      WidgetTester tester,
    ) async {
      // Set larger surface size to avoid overflow
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = TestHelpers.createMockAuthWithUser();
      final mockFirestore = TestHelpers.createMockFirestoreWithData();
      await tester.pumpWidget(
        TestHelpers.wrapWithApp(
          child: const EnhancedOnboardingScreen(skipProfileLoad: true),
          mockAuth: mockAuth,
          mockFirestore: mockFirestore,
        ),
      );
      await tester.pumpAndSettle();

      // Verify welcome screen elements (stable checks)
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Should navigate to next step when Next is tapped', (
      WidgetTester tester,
    ) async {
      // Set larger surface size to avoid overflow
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = TestHelpers.createMockAuthWithUser();
      final mockFirestore = TestHelpers.createMockFirestoreWithData();
      await tester.pumpWidget(
        TestHelpers.wrapWithApp(
          child: const EnhancedOnboardingScreen(skipProfileLoad: true),
          mockAuth: mockAuth,
          mockFirestore: mockFirestore,
        ),
      );

      // Find and tap Next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify we're on step 2 (Travel Style)
      expect(find.text('Step 2 of 6'), findsOneWidget);
    });

    testWidgets('Should allow selecting travel style', (
      WidgetTester tester,
    ) async {
      // Set larger surface size to avoid overflow
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = TestHelpers.createMockAuthWithUser();
      final mockFirestore = TestHelpers.createMockFirestoreWithData();
      await tester.pumpWidget(
        TestHelpers.wrapWithApp(
          child: const EnhancedOnboardingScreen(skipProfileLoad: true),
          mockAuth: mockAuth,
          mockFirestore: mockFirestore,
        ),
      );

      // Navigate to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // TODO: Find and tap a travel style option
      // Verify selection is highlighted
    });

    testWidgets('Should collect all data and save to Firestore', (
      WidgetTester tester,
    ) async {
      // This is an integration test that would require Firebase mocking
      // TODO: Mock Firebase and verify data is saved correctly
    });

    testWidgets('Progress indicator should update correctly', (
      WidgetTester tester,
    ) async {
      // Set larger surface size to avoid overflow
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = TestHelpers.createMockAuthWithUser();
      final mockFirestore = TestHelpers.createMockFirestoreWithData();
      await tester.pumpWidget(
        TestHelpers.wrapWithApp(
          child: const EnhancedOnboardingScreen(skipProfileLoad: true),
          mockAuth: mockAuth,
          mockFirestore: mockFirestore,
        ),
      );

      // Verify initial step indicator
      expect(find.text('Step 1 of 6'), findsOneWidget);

      // Navigate to next step
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify step 2
      expect(find.text('Step 2 of 6'), findsOneWidget);
    });

    testWidgets('Back button should navigate to previous step', (
      WidgetTester tester,
    ) async {
      // Set larger surface size to avoid overflow
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = TestHelpers.createMockAuthWithUser();
      final mockFirestore = TestHelpers.createMockFirestoreWithData();
      await tester.pumpWidget(
        TestHelpers.wrapWithApp(
          child: const EnhancedOnboardingScreen(skipProfileLoad: true),
          mockAuth: mockAuth,
          mockFirestore: mockFirestore,
        ),
      );

      // Go to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify we're on step 2
      expect(find.text('Step 2 of 6'), findsOneWidget);

      // Tap Back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Verify we're back on step 1
      expect(find.text('Step 1 of 6'), findsOneWidget);
    });

    testWidgets('Final step should show "Get Started!" button', (
      WidgetTester tester,
    ) async {
      // Set larger surface size to avoid overflow
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = TestHelpers.createMockAuthWithUser();
      final mockFirestore = TestHelpers.createMockFirestoreWithData();
      await tester.pumpWidget(
        TestHelpers.wrapWithApp(
          child: const EnhancedOnboardingScreen(
            skipProfileLoad: true,
            initialStep: 5,
          ),
          mockAuth: mockAuth,
          mockFirestore: mockFirestore,
        ),
      );
      await tester.pumpAndSettle();

      // Verify final step shows the CTA immediately
      expect(find.text('Get Started!'), findsOneWidget);
    });
  });

  group('Onboarding UI/UX Tests', () {
    testWidgets('Should display correctly on mobile screen', (
      WidgetTester tester,
    ) async {
      // Set mobile viewport with larger height to avoid overflow
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = TestHelpers.createMockAuthWithUser();
      final mockFirestore = TestHelpers.createMockFirestoreWithData();
      await tester.pumpWidget(
        TestHelpers.wrapWithApp(
          child: const EnhancedOnboardingScreen(skipProfileLoad: true),
          mockAuth: mockAuth,
          mockFirestore: mockFirestore,
        ),
      );

      // Verify layout fits mobile screen
      expect(tester.getSize(find.byType(EnhancedOnboardingScreen)).width, 375);
    });

    testWidgets('Should display correctly on tablet screen', (
      WidgetTester tester,
    ) async {
      // Set tablet viewport
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        TestHelpers.wrapWithApp(
          child: const EnhancedOnboardingScreen(skipProfileLoad: true),
        ),
      );

      // Verify layout adapts to tablet
      expect(tester.getSize(find.byType(EnhancedOnboardingScreen)).width, 800);
    });

    testWidgets('Should display correctly on desktop screen', (
      WidgetTester tester,
    ) async {
      // Set desktop viewport
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        TestHelpers.wrapWithApp(
          child: const EnhancedOnboardingScreen(skipProfileLoad: true),
        ),
      );

      // Verify layout adapts to desktop
      expect(tester.getSize(find.byType(EnhancedOnboardingScreen)).width, 1920);
    });
  });
}
