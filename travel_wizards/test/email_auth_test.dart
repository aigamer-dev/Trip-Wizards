import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/features/authentication/views/screens/email_login_screen.dart';
import 'test_helpers.dart';

void main() {
  group('EmailLoginScreen Widget Tests', () {
    testWidgets('displays sign in form by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TestHelpers.wrapWithRouter(child: const EmailLoginScreen()),
      );
      await tester.pumpAndSettle();

      // Verify sign in UI elements
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text("Don't have an account? Sign Up"), findsOneWidget);

      // Name field should not be visible in sign in mode
      expect(find.text('Name'), findsNothing);
      expect(find.text('Confirm Password'), findsNothing);
    });

    testWidgets('switches to sign up form', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.wrapWithRouter(child: const EmailLoginScreen()),
      );
      await tester.pumpAndSettle();

      // Tap the sign up link
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pumpAndSettle();

      // Verify sign up UI elements
      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('validates email format', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.wrapWithRouter(child: const EmailLoginScreen()),
      );
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(
        find.byType(TextField).at(0), // Email field is first
        'invalid-email',
      );
      await tester.enterText(
        find.byType(TextField).at(1), // Password field is second
        'password123',
      );

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('validates password length', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.wrapWithRouter(child: const EmailLoginScreen()),
      );
      await tester.pumpAndSettle();

      // Enter short password
      await tester.enterText(
        find.byType(TextField).at(0), // Email field is first
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextField).at(1), // Password field is second
        '12345',
      );

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('validates password confirmation in sign up', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TestHelpers.wrapWithRouter(child: const EmailLoginScreen()),
      );
      await tester.pumpAndSettle();

      // Switch to sign up
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pumpAndSettle();

      // Fill form with mismatched passwords
      await tester.enterText(
        find.byType(TextField).at(0), // Name field
        'Test User',
      );
      await tester.enterText(
        find.byType(TextField).at(1), // Email field
        'test@example.com',
      );

      await tester.enterText(
        find.byType(TextField).at(2),
        'password123',
      ); // Password
      await tester.enterText(
        find.byType(TextField).at(3),
        'password456',
      ); // Confirm Password

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows password strength indicator in sign up', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TestHelpers.wrapWithRouter(child: const EmailLoginScreen()),
      );
      await tester.pumpAndSettle();

      // Switch to sign up
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pumpAndSettle();

      // Enter weak password
      await tester.enterText(find.byType(TextField).at(2), 'weak');
      await tester.pumpAndSettle();

      expect(find.textContaining('Strength:'), findsOneWidget);
      expect(find.text('Strength: Too short'), findsOneWidget);

      // Enter stronger password
      await tester.enterText(find.byType(TextField).at(2), 'StrongPass123!');
      await tester.pumpAndSettle();

      expect(find.text('Strength: Strong'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.wrapWithRouter(child: const EmailLoginScreen()),
      );
      await tester.pumpAndSettle();

      // Find visibility toggle button
      final visibilityIcons = find.byIcon(Icons.visibility_off);
      expect(visibilityIcons, findsOneWidget);

      // Tap to show password
      await tester.tap(visibilityIcons.first);
      await tester.pumpAndSettle();

      // Should now show visibility icon
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('form resets when switching between sign in and sign up', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TestHelpers.wrapWithRouter(child: const EmailLoginScreen()),
      );
      await tester.pumpAndSettle();

      // Enter data in sign in form
      await tester.enterText(
        find.byType(TextField).at(0), // Email field
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextField).at(1), // Password field
        'password123',
      );

      // Switch to sign up
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pumpAndSettle();

      // Password strength should be reset
      expect(find.textContaining('Strength:'), findsNothing);

      // Switch back to sign in
      await tester.tap(find.text('Already have an account? Sign In'));
      await tester.pumpAndSettle();

      // Password strength should still not show in sign in mode
      expect(find.textContaining('Strength:'), findsNothing);
    });
  });
}
