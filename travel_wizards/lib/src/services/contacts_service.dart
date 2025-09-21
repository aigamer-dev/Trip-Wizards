import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'local_sync_repository.dart';

/// Contacts service that reads device contacts and returns a processed count.
/// In the future, this can upsert contacts into local storage and/or Firestore.
class ContactsService {
  ContactsService._();
  static final ContactsService instance = ContactsService._();

  /// Fetches device contacts (names, phones, emails) after requesting
  /// permission. Returns the number of contacts processed.
  ///
  /// Set [maxContacts] to limit processing for performance.
  Future<int> syncContacts({int? maxContacts}) async {
    if (kIsWeb) {
      // Contacts plugin is not available on web; treat as no-op
      await LocalSyncRepository.instance.saveContactsSync(count: 0);
      return 0;
    }
    final granted = await _checkPermission();
    if (!granted) return 0;

    // Read basic contact info with properties; photos are skipped for speed.
    final list = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    final iterable = maxContacts != null ? list.take(maxContacts) : list;
    final count = iterable.length;
    // Persist last sync stats locally
    await LocalSyncRepository.instance.saveContactsSync(count: count);
    return count;
  }

  Future<bool> _checkPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.contacts.status;
    if (status.isGranted) return true;
    final result = await Permission.contacts.request();
    return result.isGranted;
  }
}
