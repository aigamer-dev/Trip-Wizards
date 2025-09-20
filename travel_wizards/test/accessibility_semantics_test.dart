import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:travel_wizards/src/screens/home_screen.dart';
import 'package:travel_wizards/src/l10n/app_localizations.dart';
import 'test_helper.dart';

void main() {
  testWidgets('Home ongoing trip semantics present', (tester) async {
    // Initialize Firebase for testing
    await initializeFirebaseForTest();

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(),
      ),
    );
    // Expect the trip progress text present (proxy for semantics wrapper inclusion)
    expect(find.text('Manali — Day 3/5 • Next: Solang'), findsOneWidget);
  });
}
