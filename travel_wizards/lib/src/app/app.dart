import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../routing/router.dart';
import 'theme.dart';
import 'settings_controller.dart';
import '../services/permissions_service.dart';
import '../services/calendar_service.dart';
import '../services/contacts_service.dart';
import '../services/notifications_service.dart';
import '../services/error_handling_service.dart';
import '../services/accessibility_service.dart';
import '../utils/dependency_audit_utility.dart';

class TravelWizardsApp extends StatelessWidget {
  const TravelWizardsApp({
    super.key,
    required this.lightScheme,
    required this.darkScheme,
  });

  final ColorScheme lightScheme;
  final ColorScheme darkScheme;

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        // Kick off silent permission requests once after first frame.
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Best-effort: ignore results; user can deny and continue.
          await PermissionsService.instance.requestSilently(
            AppPermission.location,
          );
          await PermissionsService.instance.requestSilently(
            AppPermission.contacts,
          );
          await PermissionsService.instance.requestSilently(
            AppPermission.calendar,
          );
          // Kick off lightweight background syncs (non-blocking).
          // Calendar trips import
          try {
            // Ensure timezone db is initialized before reading calendar dates
            CalendarService.ensureTimezoneInitialized();
            // Fire-and-forget; errors are tolerated
            // ignore: unawaited_futures
            CalendarService.syncTripsFromCalendar();
          } catch (e) {
            ErrorHandlingService.instance.handleError(
              e,
              context: 'App initialization: Calendar sync',
              showToUser: false,
            );
          }
          // Contacts import
          try {
            // ignore: unawaited_futures
            ContactsService.instance.syncContacts();
          } catch (e) {
            ErrorHandlingService.instance.handleError(
              e,
              context: 'App initialization: Contacts sync',
              showToUser: false,
            );
          }
          // Initialize accessibility service
          try {
            // ignore: unawaited_futures
            AccessibilityService.instance.initialize();
          } catch (e) {
            ErrorHandlingService.instance.handleError(
              e,
              context: 'App initialization: Accessibility service',
              showToUser: false,
            );
          }
          // Initialize in-app notifications (SnackBars) once the messenger exists
          try {
            final messenger = TravelWizardsApp.messengerKey.currentState;
            if (messenger != null) {
              NotificationsService.instance.init(messenger);
            }
          } catch (e) {
            ErrorHandlingService.instance.handleError(
              e,
              context: 'App initialization: Notifications service',
              showToUser: false,
            );
          }

          // Run dependency audit in debug mode only
          try {
            if (kDebugMode) {
              // Run dependency audit for development insights
              // ignore: unawaited_futures
              DependencyAuditUtility.runDependencyAudit();
            }
          } catch (e) {
            ErrorHandlingService.instance.handleError(
              e,
              context: 'App initialization: Dependency audit',
              showToUser: false,
            );
          }
        });
        return ChangeNotifierProvider<AccessibilityService>.value(
          value: AccessibilityService.instance,
          child: Consumer<AccessibilityService>(
            builder: (context, accessibilityService, child) {
              final baseTheme = themeFromScheme(
                AppSettings.instance.themeMode == ThemeMode.dark
                    ? darkScheme
                    : lightScheme,
              );
              final accessibleTheme = accessibilityService
                  .createAccessibleTheme(baseTheme);
              final accessibleDarkTheme = accessibilityService
                  .createAccessibleTheme(themeFromScheme(darkScheme));

              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context)!.appTitle,
                theme: accessibleTheme,
                darkTheme: accessibleDarkTheme,
                themeMode: AppSettings.instance.themeMode,
                locale: AppSettings.instance.locale,
                routerConfig: appRouter,
                scaffoldMessengerKey: messengerKey,
                supportedLocales: const [
                  Locale('en'),
                  Locale('hi'),
                  Locale('bn'),
                  Locale('te'),
                  Locale('mr'),
                  Locale('ta'),
                  Locale('ur'),
                  Locale('gu'),
                  Locale('ml'),
                  Locale('kn'),
                  Locale('or'),
                ],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              );
            },
          ),
        );
      },
    );
  }
}
