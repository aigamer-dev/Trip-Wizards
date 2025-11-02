import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:travel_wizards/src/shared/services/accessibility_service.dart';
import 'package:travel_wizards/src/shared/services/calendar_service.dart';
import 'package:travel_wizards/src/shared/services/contacts_service.dart';
import 'package:travel_wizards/src/shared/services/error_handling_service.dart';
import 'package:travel_wizards/src/shared/services/notifications_service.dart';
import 'package:travel_wizards/src/shared/services/permissions_service.dart';
import 'package:travel_wizards/src/shared/utils/dependency_audit_utility.dart';
import '../l10n/app_localizations.dart';
import '../routing/router.dart';
import 'settings_controller.dart';

class TravelWizardsApp extends StatefulWidget {
  const TravelWizardsApp({
    super.key,
    required this.lightTheme,
    required this.darkTheme,
    this.routerConfig,
  });

  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final RouterConfig<Object>? routerConfig;

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  State<TravelWizardsApp> createState() => _TravelWizardsAppState();
}

class _TravelWizardsAppState extends State<TravelWizardsApp> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize permissions and services once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_hasInitialized) return;
      _hasInitialized = true;

      // Best-effort: ignore results; user can deny and continue.
      try {
        await PermissionsService.instance.requestSilently(
          AppPermission.location,
        );
        await PermissionsService.instance.requestSilently(
          AppPermission.contacts,
        );
        await PermissionsService.instance.requestSilently(
          AppPermission.calendar,
        );
      } catch (e) {
        // Ignore permission errors during initialization
      }

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
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        return ChangeNotifierProvider<AccessibilityService>.value(
          value: AccessibilityService.instance,
          child: Consumer<AccessibilityService>(
            builder: (context, accessibilityService, child) {
              final baseTheme = AppSettings.instance.themeMode == ThemeMode.dark
                  ? widget.darkTheme
                  : widget.lightTheme;
              final accessibleTheme = accessibilityService
                  .createAccessibleTheme(baseTheme);
              final accessibleDarkTheme = accessibilityService
                  .createAccessibleTheme(widget.darkTheme);
              final textScaler = TextScaler.linear(
                accessibilityService.textScaleFactor,
              );
              final boldText = accessibilityService.isHighContrastEnabled
                  ? true
                  : null;

              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context)!.appTitle,
                theme: accessibleTheme,
                darkTheme: accessibleDarkTheme,
                themeMode: AppSettings.instance.themeMode,
                locale: AppSettings.instance.locale,
                routerConfig: widget.routerConfig ?? appRouter,
                scaffoldMessengerKey: TravelWizardsApp.messengerKey,
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  final updatedQuery = mediaQuery.copyWith(
                    textScaler: textScaler,
                    boldText: boldText ?? mediaQuery.boldText,
                  );

                  return MediaQuery(
                    data: updatedQuery,
                    child: child ?? const SizedBox.shrink(),
                  );
                },
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
