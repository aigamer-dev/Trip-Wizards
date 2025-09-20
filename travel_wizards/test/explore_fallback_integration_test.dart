import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/l10n/app_localizations.dart';
import 'package:travel_wizards/src/screens/explore_screen.dart';
import 'package:travel_wizards/src/services/backend_service.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Explore remote failure fallback', () {
    testWidgets('shows SnackBar and falls back to local ideas', (tester) async {
      // Initialize Firebase for testing
      await initializeFirebaseForTest();

      // Prepare dotenv to enable remote mode via kUseRemoteIdeas getter.
      dotenv.testLoad(
        fileInput:
            'USE_REMOTE_IDEAS=true\nBACKEND_BASE_URL=http://127.0.0.1:65535',
      );

      // Short timeout so the failing call returns fast.
      BackendService.init(
        BackendConfig(
          baseUrl: Uri.parse('http://127.0.0.1:65535'),
          timeout: const Duration(milliseconds: 150),
        ),
      );

      // Ensure SharedPreferences is available for ExploreStore/AppSettings.
      SharedPreferences.setMockInitialValues({});

      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => const ExploreScreen())],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) {
            return Scaffold(body: child);
          },
        ),
      );

      // Allow initial work and the remote failure path to complete.
      // Pump a bit longer due to async timeout.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Expect a SnackBar with the fallback message.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Network issue'), findsWidgets);

      // Verify that a known local idea title renders.
      expect(find.text('Weekend in Hampi'), findsOneWidget);
    });
  });
}
