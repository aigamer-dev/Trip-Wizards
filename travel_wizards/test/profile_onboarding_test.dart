import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:travel_wizards/firebase_options.dart';
import 'test_helpers.dart';
import 'package:travel_wizards/src/features/onboarding/views/screens/enhanced_onboarding_screen.dart';
// App localizations and delegates are provided by TestHelpers

void main() {
  // Ensure Firebase native bindings are initialized and a Firebase app exists
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

  group('EnhancedOnboardingScreen Profile Step Tests', () {
    testWidgets('displays profile step as second step', (
      WidgetTester tester,
    ) async {
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

      // First step should be welcome
      expect(find.text('Welcome to Travel Wizards!'), findsOneWidget);

      // Navigate to next step (profile)
      final nextButton = find.text('Next');
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Should now show profile step
      expect(find.text('Your Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('State'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
    });

    testWidgets('profile fields are editable', (WidgetTester tester) async {
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

      // Navigate to profile step
      final nextButton = find.text('Next');
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Enter name: TravelTextField builds a TextField, so find the label and then the TextField ancestor
      // Use the first TextField on the profile step for name input (TravelTextField builds a TextField)
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'John Doe');
      expect(find.text('John Doe'), findsOneWidget);

      // Select gender
      final genderDropdown = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Gender',
      );
      // Instead of opening overlay, call the DropdownButtonFormField's onChanged directly
      final DropdownButtonFormField<String> genderWidget = tester.widget(
        genderDropdown,
      );
      genderWidget.onChanged?.call('Male');
      await tester.pumpAndSettle();

      // Select state
      final stateDropdown = find.widgetWithText(
        DropdownButtonFormField<String>,
        'State',
      );
      // Select state by invoking onChanged to avoid overlay hit-test issues
      final DropdownButtonFormField<String> stateWidget = tester.widget(
        stateDropdown,
      );
      stateWidget.onChanged?.call('Karnataka');
      await tester.pumpAndSettle();

      // Enter city
      // City is also a TravelTextField -> TextField
      final cityField = find.byType(TextField).last;
      await tester.enterText(cityField, 'Bangalore');

      // Can proceed to next step
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('date picker opens when tapping date of birth', (
      WidgetTester tester,
    ) async {
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

      // Navigate to profile step
      final nextButton = find.text('Next');
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Tap date of birth field
      final dobField = find.text('Select date');
      await tester.tap(dobField);
      await tester.pumpAndSettle();

      // Date picker dialog should open
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('all states are available in dropdown', (
      WidgetTester tester,
    ) async {
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

      // Navigate to profile step
      final nextButton = find.text('Next');
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Open state dropdown
      final stateDropdown = find.widgetWithText(
        DropdownButtonFormField<String>,
        'State',
      );
      // Inspect the DropdownButtonFormField items directly to ensure states exist
      // Verify available options by setting the field value via onChanged
      final DropdownButtonFormField<String> stateWidget2 = tester.widget(
        stateDropdown,
      );
      for (final s in [
        'Karnataka',
        'Maharashtra',
        'Tamil Nadu',
        'West Bengal',
        'Uttar Pradesh',
      ]) {
        stateWidget2.onChanged?.call(s);
        await tester.pumpAndSettle();
        expect(find.text(s), findsOneWidget);
      }
    });

    testWidgets('profile step shows correct step number', (
      WidgetTester tester,
    ) async {
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

      // Check initial step
      expect(find.textContaining('Step 1 of 6'), findsOneWidget);

      // Navigate to profile step
      final nextButton = find.text('Next');
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Should show step 2
      expect(find.textContaining('Step 2 of 6'), findsOneWidget);
    });

    testWidgets('can navigate back from profile step', (
      WidgetTester tester,
    ) async {
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

      // Navigate to profile step
      final nextButton = find.text('Next');
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('Your Profile'), findsOneWidget);

      // Navigate back
      final backButton = find.text('Back');
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should be back at welcome step
      expect(find.text('Welcome to Travel Wizards!'), findsOneWidget);
    });

    testWidgets('profile step has all gender options', (
      WidgetTester tester,
    ) async {
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

      // Navigate to profile step
      final nextButton = find.text('Next');
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Open gender dropdown
      final genderDropdown = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Gender',
      );
      await tester.tap(genderDropdown);
      await tester.pumpAndSettle();

      // Check all gender options
      expect(find.text('Male'), findsWidgets);
      expect(find.text('Female'), findsWidgets);
      expect(find.text('Other'), findsWidgets);
      expect(find.text('Prefer not to say'), findsWidgets);
    });
  });
}
