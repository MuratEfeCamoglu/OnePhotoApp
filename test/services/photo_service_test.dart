import 'package:one_photo_app/core/categories.dart';

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

    // Copies 364 real files; slow when the whole suite runs in parallel.
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
    }, timeout: const Timeout(Duration(minutes: 2)));
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

  group('saveNote (F11)', () {
    test('trims, stores and returns the updated entry', () async {
      await service.savePhoto('2026-10-09', source());
      now = now.add(const Duration(hours: 1));
      final updated = await service.saveNote('2026-10-09', '  Güzel gün  ');
      expect(updated!.note, 'Güzel gün');
      expect(repo.rows['2026-10-09']!.note, 'Güzel gün');
      expect(updated.updatedAt, now);
    });

    test('blank text removes the note', () async {
      await service.savePhoto('2026-10-09', source());
      await service.saveNote('2026-10-09', 'x');
      await service.saveNote('2026-10-09', '   ');
      expect(repo.rows['2026-10-09']!.note, isNull);
    });

    test('no photo → nothing saved', () async {
      expect(await service.saveNote('2026-10-09', 'x'), isNull);
      expect(repo.rows, isEmpty);
    });

    test('over-long notes are clipped', () async {
      await service.savePhoto('2026-10-09', source());
      final updated = await service.saveNote('2026-10-09', 'a' * 600);
      expect(updated!.note!.length, Entry.maxNoteLength);
    });

    test('replacing the photo keeps the note', () async {
      await service.savePhoto('2026-10-09', source('a.jpg'));
      await service.saveNote('2026-10-09', 'Kalsın');
      now = now.add(const Duration(minutes: 1));
      final replaced = await service.savePhoto('2026-10-09', source('b.jpg'));
      expect(replaced.note, 'Kalsın');
    });
  });

  group('saveDetails (F12)', () {
    test('stores category with the note', () async {
      await service.savePhoto('2026-10-09', source());
      final e = await service.saveDetails(
        '2026-10-09',
        note: 'Akşam yemeği',
        category: PhotoCategory.food,
      );
      expect(e!.category, PhotoCategory.food);
      expect(repo.rows['2026-10-09']!.note, 'Akşam yemeği');
    });

    test('category can be cleared', () async {
      await service.savePhoto('2026-10-09', source());
      await service.saveDetails(
        '2026-10-09',
        note: '',
        category: PhotoCategory.pet,
      );
      await service.saveDetails('2026-10-09', note: '', category: null);
      expect(repo.rows['2026-10-09']!.category, isNull);
    });

    test('saveNote keeps the category', () async {
      await service.savePhoto('2026-10-09', source());
      await service.saveDetails(
        '2026-10-09',
        note: '',
        category: PhotoCategory.pet,
      );
      await service.saveNote('2026-10-09', 'Kedi');
      expect(repo.rows['2026-10-09']!.category, PhotoCategory.pet);
    });

    test('replacing the photo keeps the category', () async {
      await service.savePhoto('2026-10-09', source('a.jpg'));
      await service.saveDetails(
        '2026-10-09',
        note: '',
        category: PhotoCategory.view,
      );
      now = now.add(const Duration(minutes: 1));
      final replaced = await service.savePhoto('2026-10-09', source('b.jpg'));
      expect(replaced.category, PhotoCategory.view);
    });
  });
}
