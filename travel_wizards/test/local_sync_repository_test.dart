import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:travel_wizards/src/services/local_sync_repository.dart';

void main() {
  group('LocalSyncRepository', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      await LocalSyncRepository.instance.init();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await tempDir.delete(recursive: true);
    });

    test('saves and reads contacts sync stats', () async {
      await LocalSyncRepository.instance.saveContactsSync(count: 5);
      expect(LocalSyncRepository.instance.contactsLastCount, 5);
      expect(LocalSyncRepository.instance.contactsLastTime, isNotNull);
    });

    test('saves and reads calendar sync stats', () async {
      await LocalSyncRepository.instance.saveCalendarSync(count: 3);
      expect(LocalSyncRepository.instance.calendarLastCount, 3);
      expect(LocalSyncRepository.instance.calendarLastTime, isNotNull);
    });
  });
}
