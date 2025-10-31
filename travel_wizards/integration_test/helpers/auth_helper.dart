import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Authentication helper for integration tests
class AuthHelper {
  final WidgetTester tester;
  final FirebaseAuth auth;

  AuthHelper(this.tester, this.auth);

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('🔐 Attempting Google sign-in...');

      // Find and tap Google sign-in button
      final googleButton = find.textContaining('Google', findRichText: true);
      if (googleButton.evaluate().isEmpty) {
        debugPrint('⚠️ Google sign-in button not found');
        return null;
      }

      await tester.tap(googleButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final user = auth.currentUser;
      if (user != null) {
        debugPrint('✅ Google sign-in successful: ${user.uid}');
        debugPrint('   Email: ${user.email}');
      } else {
        debugPrint('⚠️ Google sign-in completed but no user');
      }

      return user;
    } catch (e) {
      debugPrint('⚠️ Google sign-in failed: $e');
      return null;
    }
  }

  /// Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      debugPrint('🔐 Attempting email/password sign-in...');
      debugPrint('   Email: $email');

      // Find email field
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, email);
      await tester.pumpAndSettle();

      // Find password field
      final passwordField = find.byType(TextField).at(1);
      await tester.enterText(passwordField, password);
      await tester.pumpAndSettle();

      // Find and tap sign-in button
      final signInButton = find.textContaining('Sign In', findRichText: true);
      if (signInButton.evaluate().isEmpty) {
        debugPrint('⚠️ Sign In button not found');
        return null;
      }

      await tester.tap(signInButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final user = auth.currentUser;
      if (user != null) {
        debugPrint('✅ Email sign-in successful: ${user.uid}');
      } else {
        debugPrint('⚠️ Email sign-in failed');
      }

      return user;
    } catch (e) {
      debugPrint('⚠️ Email sign-in error: $e');
      return null;
    }
  }

  /// Sign up with email and password
  Future<User?> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      debugPrint('📝 Attempting sign-up...');
      debugPrint('   Email: $email');
      debugPrint('   Name: $name');

      // Look for sign-up button or link
      final signUpLink = find.textContaining('Sign Up', findRichText: true);
      if (signUpLink.evaluate().isNotEmpty) {
        await tester.tap(signUpLink.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Fill in sign-up form
      final textFields = find.byType(TextField);
      if (textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.at(0), name);
        await tester.pumpAndSettle();

        await tester.enterText(textFields.at(1), email);
        await tester.pumpAndSettle();

        await tester.enterText(textFields.at(2), password);
        await tester.pumpAndSettle();

        // Find confirm password field if exists
        if (textFields.evaluate().length >= 4) {
          await tester.enterText(textFields.at(3), password);
          await tester.pumpAndSettle();
        }
      }

      // Tap create account button
      final createButton = find.textContaining('Create', findRichText: true);
      if (createButton.evaluate().isNotEmpty) {
        await tester.tap(createButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      final user = auth.currentUser;
      if (user != null) {
        debugPrint('✅ Sign-up successful: ${user.uid}');
      } else {
        debugPrint('⚠️ Sign-up completed but no user');
      }

      return user;
    } catch (e) {
      debugPrint('⚠️ Sign-up error: $e');
      return null;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Signing out...');
      await auth.signOut();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      debugPrint('✅ Sign-out successful');
    } catch (e) {
      debugPrint('⚠️ Sign-out error: $e');
    }
  }

  /// Delete current user account from settings
  Future<bool> deleteAccountFromSettings() async {
    try {
      debugPrint('🗑️ Attempting to delete account from settings...');

      // Navigate to settings
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isEmpty) {
        debugPrint('⚠️ Settings icon not found');
        return false;
      }

      await tester.tap(settingsIcon);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Look for Privacy or Account settings
      final privacyOption = find.textContaining('Privacy', findRichText: true);
      if (privacyOption.evaluate().isNotEmpty) {
        await tester.tap(privacyOption.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Find delete account option
      final deleteOption = find.textContaining('Delete', findRichText: true);
      if (deleteOption.evaluate().isEmpty) {
        debugPrint('⚠️ Delete account option not found');
        return false;
      }

      await tester.tap(deleteOption.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Confirm deletion in dialog
      final confirmButton = find.textContaining('Confirm', findRichText: true);
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));
        debugPrint('✅ Account deletion initiated');
        return true;
      }

      // Alternative: look for Yes/Delete button
      final yesButton = find.textContaining('Yes', findRichText: true);
      if (yesButton.evaluate().isNotEmpty) {
        await tester.tap(yesButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));
        debugPrint('✅ Account deletion initiated');
        return true;
      }

      debugPrint('⚠️ Could not find confirmation button');
      return false;
    } catch (e) {
      debugPrint('⚠️ Account deletion error: $e');
      return false;
    }
  }

  /// Get current user
  User? getCurrentUser() => auth.currentUser;

  /// Check if user is signed in
  bool isSignedIn() => auth.currentUser != null;
}
