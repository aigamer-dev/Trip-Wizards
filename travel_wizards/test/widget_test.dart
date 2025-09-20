// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/app/app.dart';
import 'package:travel_wizards/src/app/theme.dart';
import 'test_helper.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    // Initialize Firebase for testing
    await initializeFirebaseForTest();

    // Build app with fallback schemes (MaterialApp is provided inside TravelWizardsApp).
    await tester.pumpWidget(
      TravelWizardsApp(
        lightScheme: kFallbackLightScheme,
        darkScheme: kFallbackDarkScheme,
      ),
    );

    // Pump one frame to complete the initial build.
    await tester.pump();

    // Expect to find a MaterialApp widget from the app.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
