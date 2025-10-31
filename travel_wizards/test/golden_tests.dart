import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_wizards/src/shared/widgets/travel_components/travel_components.dart';
import 'package:travel_wizards/src/features/authentication/views/screens/email_login_screen.dart';
import 'package:travel_wizards/src/features/authentication/views/screens/login_landing_screen.dart';
import 'package:travel_wizards/src/features/onboarding/views/screens/enhanced_onboarding_screen.dart';
import 'package:travel_wizards/src/core/l10n/app_localizations.dart';

void main() {
  group('Component Golden Tests', () {
    testWidgets('PrimaryButton matches golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: PrimaryButton(
                onPressed: () {},
                child: const Text('Primary Button'),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button.png'),
      );
    });

    testWidgets('SecondaryButton matches golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: SecondaryButton(
                onPressed: () {},
                child: const Text('Secondary Button'),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(SecondaryButton),
        matchesGoldenFile('goldens/secondary_button.png'),
      );
    });

    testWidgets('TravelTextField matches golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: TravelTextField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(TravelTextField),
        matchesGoldenFile('goldens/travel_text_field.png'),
      );
    });

    testWidgets('TravelCard matches golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: TravelCard(
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Sample Card'),
                        SizedBox(height: 8),
                        Text('This is a sample card for testing.'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(TravelCard),
        matchesGoldenFile('goldens/travel_card.png'),
      );
    });

    testWidgets('TravelAvatar matches golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(child: TravelAvatar(child: Text('JD'))),
          ),
        ),
      );

      await expectLater(
        find.byType(TravelAvatar),
        matchesGoldenFile('goldens/travel_avatar.png'),
      );
    });
  });

  group('Auth & Onboarding Screen Golden Tests', () {
    testWidgets('EmailLoginScreen matches golden', (tester) async {
      // Set larger viewport for golden tests
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EmailLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(EmailLoginScreen),
        matchesGoldenFile('goldens/auth_onboarding/email_login_screen.png'),
      );
    });

    testWidgets('LoginLandingScreen matches golden', (tester) async {
      // Set larger viewport for golden tests
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginLandingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LoginLandingScreen),
        matchesGoldenFile('goldens/auth_onboarding/login_landing_screen.png'),
      );
    });

    testWidgets('EnhancedOnboardingScreen Welcome Step matches golden', (
      tester,
    ) async {
      // Set larger viewport for golden tests
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EnhancedOnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(EnhancedOnboardingScreen),
        matchesGoldenFile(
          'goldens/auth_onboarding/onboarding_welcome_step.png',
        ),
      );
    });
  });
}
