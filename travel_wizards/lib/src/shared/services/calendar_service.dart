import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'gemini_service.dart';
import 'local_sync_repository.dart';
import 'trips_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';

class CalendarService {
  static bool _tzInitialized = false;

  static void ensureTimezoneInitialized() {
    if (!_tzInitialized) {
      tzdata.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  static final DeviceCalendarPlugin _calendar = DeviceCalendarPlugin();

  static Future<bool> checkPermission() async {
    if (kIsWeb) return false; // Calendar access not supported on web
    final status = await Permission.calendarFullAccess.status;
    if (!status.isGranted) {
      final result = await Permission.calendarFullAccess.request();
      return result.isGranted;
    }
    return true;
  }

  static Future<List<Calendar>> getCalendars() async {
    final granted = await checkPermission();
    if (!granted) return [];
    final result = await _calendar.retrieveCalendars();
    return result.data ?? [];
  }

  static Future<void> addTripToCalendar({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? calendarId,
  }) async {
    ensureTimezoneInitialized();
    final granted = await checkPermission();
    if (!granted) return;
    final calendars = await getCalendars();
    final calId = calendarId ?? calendars.firstOrNull?.id;
    if (calId == null) return;
    final location = tz.local;
    final event = Event(
      calId,
      start: tz.TZDateTime.from(start, location),
      end: tz.TZDateTime.from(end, location),
      description: description,
    );
    await _calendar.createOrUpdateEvent(event);
  }

  static Future<void> removeTripFromCalendar(
    String eventId, {
    String? calendarId,
  }) async {
    final granted = await checkPermission();
    if (!granted || calendarId == null) return;
    await _calendar.deleteEvent(calendarId, eventId);
  }

  /// Use Gemini (on-device) to classify if a calendar event is a trip.
  static Future<bool> isTripEvent(String title, String? description) async {
    final text = '$title ${description ?? ''}';
    return GeminiService.isTripText(text);
  }

  /// Sync calendar events to trips (reverse integration)
  static Future<List<Event>> getTripEventsFromCalendar() async {
    final granted = await checkPermission();
    if (!granted) return [];
    final calendars = await getCalendars();
    List<Event> tripEvents = [];
    for (final cal in calendars) {
      final eventsResult = await _calendar.retrieveEvents(
        cal.id!,
        RetrieveEventsParams(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 365)),
        ),
      );
      final events = eventsResult.data ?? [];
      for (final event in events) {
        if (await isTripEvent(event.title ?? '', event.description)) {
          tripEvents.add(event);
        }
      }
    }
    return tripEvents;
  }

  /// Call this at startup or via a sync button to import trips from calendar.
  static Future<int> syncTripsFromCalendar() async {
    final tripEvents = await getTripEventsFromCalendar();
    int count = 0;
    final user = () {
      try {
        return FirebaseAuth.instance.currentUser;
      } catch (_) {
        return null;
      }
    }();
    for (final e in tripEvents) {
      // Derive a basic Trip from the event window; if end is missing, assume 2 days
      final start = e.start?.toLocal() ?? DateTime.now();
      final end = e.end?.toLocal() ?? start.add(const Duration(days: 2));
      final id = 'cal_${e.eventId ?? e.hashCode}';
      final trip = Trip(
        id: id,
        title: e.title ?? 'Trip',
        startDate: start,
        endDate: end,
        destinations: const <String>[],
        notes: e.description,
        ownerId: user?.uid ?? '',
        source: 'calendar',
      );
      if (user != null) {
        try {
          await TripsRepository.instance.upsertTrip(trip);
        } catch (_) {
          // Ignore write failures silently for now
        }
      }
      count += 1;
    }
    await LocalSyncRepository.instance.saveCalendarSync(count: count);
    return count;
  }
}
