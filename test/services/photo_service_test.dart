import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/errors.dart';
import 'package:one_photo_app/data/entry.dart';
import 'package:one_photo_app/data/photo_storage.dart';
import 'package:one_photo_app/services/photo_picker.dart';
import 'package:one_photo_app/services/photo_service.dart';
import 'package:one_photo_app/services/settings_store.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes.dart';

void main() {
  late Directory root;
  late PhotoStorage storage;
  late FakeEntryRepository repo;
  late FakePhotoPicker picker;
  late SettingsStore settings;
  late DateTime now;
  late PhotoService service;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('onephoto_service');
    storage = PhotoStorage(Directory(p.join(root.path, 'photos')));
    repo = FakeEntryRepository();
    picker = FakePhotoPicker();
    SharedPreferences.setMockInitialValues({});
    settings = SettingsStore(await SharedPreferences.getInstance());
    now = DateTime(2026, 10, 9, 12);
    service = PhotoService(
      repository: repo,
      storage: storage,
      picker: picker,
      settings: settings,
      clock: () => now,
    );
  });

  tearDown(() => root.deleteSync(recursive: true));

  File source([String name = 'source.jpg']) => writeSourcePhoto(root, name);

  group('savePhoto', () {
    test('writes the file and one entry with only a file name', () async {
      final entry = await service.savePhoto('2026-10-09', source());
      expect(repo.rows.keys, ['2026-10-09']);
      expect(entry.fileName, isNot(contains(p.separator)));
      expect(service.fileFor(entry).existsSync(), isTrue);
    });

    test('replacing deletes the old file after the DB update (F4c)', () async {
      final first = await service.savePhoto('2026-10-09', source('a.jpg'));
      now = now.add(const Duration(minutes: 1));
      final second = await service.savePhoto('2026-10-09', source('b.jpg'));

      expect(repo.rows, hasLength(1));
      expect(repo.rows['2026-10-09']!.fileName, second.fileName);
      expect(storage.resolve(first.fileName).existsSync(), isFalse);
      expect(await storage.listFileNames(), [second.fileName]);
      expect(second.createdAt, first.createdAt);
      expect(second.updatedAt, now);
    });

    test('DB failure deletes the new file and keeps the old (F8b)', () async {
      final first = await service.savePhoto('2026-10-09', source('a.jpg'));
      repo.failUpserts = true;

      await expectLater(
        service.savePhoto('2026-10-09', source('b.jpg')),
        throwsA(isA<PhotoSaveException>()),
      );
      expect(await storage.listFileNames(), [first.fileName]);
      expect(repo.rows['2026-10-09'], first);
    });

    test('file copy failure leaves DB untouched (F8b)', () async {
      final missing = File(p.join(root.path, 'missing.jpg'));
      await expectLater(
        service.savePhoto('2026-10-09', missing),
        throwsA(isA<PhotoSaveException>()),
      );
      expect(repo.rows, isEmpty);
      expect(await storage.listFileNames(), isEmpty);
    });
  });

  group('todayKey uses the local clock', () {
    test('23:59 is still the same day', () async {
      now = DateTime(2026, 10, 9, 23, 59);
      picker.cameraResult = source();
      final entry = await service.pickAndSave(
        service.todayKey(),
        PhotoSource.camera,
      );
      expect(entry!.dateKey, '2026-10-09');
      expect(entry.fileName, startsWith('2026-10-09_'));
    });

    test('00:00 is the next day', () async {
      now = DateTime(2026, 10, 10);
      picker.cameraResult = source();
      final entry = await service.pickAndSave(
        service.todayKey(),
        PhotoSource.camera,
      );
      expect(entry!.dateKey, '2026-10-10');
    });
  });

  group('pickAndSave', () {
    test('cancel changes nothing (F2c)', () async {
      final entry = await service.pickAndSave('2026-10-09', PhotoSource.camera);
      expect(entry, isNull);
      expect(repo.rows, isEmpty);
      expect(await storage.listFileNames(), isEmpty);
      expect(settings.pendingDateKey, isNull);
    });

    test('gallery photo goes to the tapped day, not today (F3b)', () async {
      picker.galleryResult = source();
      final entry = await service.pickAndSave(
        '2026-09-14',
        PhotoSource.gallery,
      );
      expect(entry!.dateKey, '2026-09-14');
      expect(picker.galleryCalls, 1);
      expect(picker.cameraCalls, 0);
    });

    test('stores the pending day while the picker is open', () async {
      String? seen;
      picker
        ..cameraResult = source()
        ..onOpen = () => seen = settings.pendingDateKey;
      await service.pickAndSave('2026-10-05', PhotoSource.camera);
      expect(seen, '2026-10-05');
      expect(settings.pendingDateKey, isNull);
    });

    test('permission denial propagates and changes nothing (F8a)', () async {
      picker.error = const PermissionDeniedException(PermissionKind.camera);
      await expectLater(
        service.pickAndSave('2026-10-09', PhotoSource.camera),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(repo.rows, isEmpty);
      expect(settings.pendingDateKey, isNull);
    });
  });

  group('deleteEntry', () {
    test('removes the row and the file (F5c)', () async {
      final entry = await service.savePhoto('2026-10-09', source());
      await service.deleteEntry('2026-10-09');
      expect(repo.rows, isEmpty);
      expect(storage.resolve(entry.fileName).existsSync(), isFalse);
    });

    test('is a no-op for an empty day', () async {
      await service.deleteEntry('2026-10-01');
      expect(repo.rows, isEmpty);
    });
  });

  group('cleanOrphans (F6f)', () {
    test('deletes only files no entry refers to', () async {
      final kept = await service.savePhoto('2026-10-09', source());
      final orphan = await storage.save(
        source('o.jpg'),
        dateKey: '2026-10-08',
        now: now,
      );

      expect(await service.cleanOrphans(), 1);
      expect(await storage.listFileNames(), [kept.fileName]);
      expect(storage.resolve(orphan).existsSync(), isFalse);
    });

    test('keeps everything when all files are referenced', () async {
      await service.savePhoto('2026-10-09', source());
      expect(await service.cleanOrphans(), 0);
    });
  });

  group('recoverLostPhoto', () {
    test('saves the lost photo to the pending day and clears it', () async {
      await settings.setPendingDateKey('2026-10-03');
      picker.lostResult = source();
      final entry = await service.recoverLostPhoto();
      expect(entry!.dateKey, '2026-10-03');
      expect(settings.pendingDateKey, isNull);
    });

    test('falls back to today without a pending day', () async {
      picker.lostResult = source();
      expect((await service.recoverLostPhoto())!.dateKey, '2026-10-09');
    });

    test('nothing lost → nothing saved, stale pending cleared', () async {
      await settings.setPendingDateKey('2026-10-03');
      expect(await service.recoverLostPhoto(), isNull);
      expect(repo.rows, isEmpty);
      expect(settings.pendingDateKey, isNull);
    });
  });

  group('fillDemoDays', () {
    test('without a photo returns null and adds nothing', () async {
      expect(await service.fillDemoDays(365), isNull);
      expect(repo.rows, isEmpty);
    });

    test('fills every empty day of the last N days, keeps existing', () async {
      final original = await service.savePhoto('2026-10-05', source());
      final filled = await service.fillDemoDays(365);

      expect(filled, 364);
      expect(repo.rows, hasLength(365));
      expect(repo.rows['2026-10-05'], original);
      expect(repo.rows.containsKey('2026-10-09'), isTrue);
      expect(repo.rows.containsKey('2025-10-10'), isTrue);
      expect(repo.rows.containsKey('2025-10-09'), isFalse);
      expect(await storage.listFileNames(), hasLength(365));
    });
  });

  test('loadAll returns repository entries', () async {
    final e = Entry(
      dateKey: '2026-10-01',
      fileName: 'x.jpg',
      createdAt: now,
      updatedAt: now,
    );
    repo.rows[e.dateKey] = e;
    expect(await service.loadAll(), [e]);
  });
}
