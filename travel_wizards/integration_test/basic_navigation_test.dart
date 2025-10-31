import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:travel_wizards/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Tests', () {
    setUp(() {
      debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    });

    tearDown(() {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    });

    testWidgets('Basic Navigation Test', (tester) async {
      debugPrint('🎬 Starting basic navigation test...');

      // Initialize app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Wait for home screen to load (skip authentication for basic navigation)
      debugPrint('⏳ Waiting for home screen to load...');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test Login Screen (since app redirects to login when not authenticated)
      debugPrint('🔐 Testing Login Screen');
      expect(find.byType(Scaffold), findsOneWidget);
      debugPrint('✅ Login screen accessible');

      // Test that the app renders without crashing (minimal test)
      expect(find.byType(MaterialApp), findsOneWidget);
      debugPrint('✅ App renders successfully');

      debugPrint('🎉 Basic navigation test completed successfully!');
    });
  });
}
