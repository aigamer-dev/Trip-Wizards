import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import '../routing/router.dart';
import 'theme.dart';
import 'settings_controller.dart';
import '../services/permissions_service.dart';
import '../services/calendar_service.dart';
import '../services/contacts_service.dart';
import '../services/notifications_service.dart';

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
          } catch (_) {}
          // Contacts import
          try {
            // ignore: unawaited_futures
            ContactsService.instance.syncContacts();
          } catch (_) {}
          // Initialize in-app notifications (SnackBars) once the messenger exists
          try {
            final messenger = TravelWizardsApp.messengerKey.currentState;
            if (messenger != null) {
              NotificationsService.instance.init(messenger);
            }
          } catch (_) {}
        });
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          theme: themeFromScheme(lightScheme),
          darkTheme: themeFromScheme(darkScheme),
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
    );
  }
}
