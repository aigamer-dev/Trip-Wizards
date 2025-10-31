import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocalSyncRepository {
  LocalSyncRepository._();
  static final LocalSyncRepository instance = LocalSyncRepository._();

  static const _boxName = 'sync_meta';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  String _uidOrLocal() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'local';
    } catch (_) {
      // Firebase not initialized or unavailable in this context (e.g., tests)
      return 'local';
    }
  }

  String _key(String base) => '${_uidOrLocal()}:$base';

  // Calendar
  Future<void> saveCalendarSync({required int count}) async {
    await _box.put(_key('calendar_last_count'), count);
    await _box.put(
      _key('calendar_last_time'),
      DateTime.now().toIso8601String(),
    );
  }

  int get calendarLastCount =>
      (_box.get(_key('calendar_last_count')) as int?) ?? 0;
  DateTime? get calendarLastTime {
    final s = _box.get(_key('calendar_last_time')) as String?;
    return s == null ? null : DateTime.tryParse(s);
  }

  // Contacts
  Future<void> saveContactsSync({required int count}) async {
    await _box.put(_key('contacts_last_count'), count);
    await _box.put(
      _key('contacts_last_time'),
      DateTime.now().toIso8601String(),
    );
  }

  int get contactsLastCount =>
      (_box.get(_key('contacts_last_count')) as int?) ?? 0;
  DateTime? get contactsLastTime {
    final s = _box.get(_key('contacts_last_time')) as String?;
    return s == null ? null : DateTime.tryParse(s);
  }
}
