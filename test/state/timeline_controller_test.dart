import 'package:one_photo_app/core/categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/calendar.dart';
import 'package:one_photo_app/core/errors.dart';
import 'package:one_photo_app/services/photo_picker.dart';

import '../fakes.dart';

void main() {
  late TestHarness h;
  tearDown(() => h.dispose());

  test('is loading until startup finishes, then exposes entries', () async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    expect(h.controller.isLoading, isTrue);
    await h.controller.startup();
    expect(h.controller.isLoading, isFalse);
    expect(h.controller.isEmpty, isFalse);
    expect(h.controller.entryFor('2026-10-01'), isNotNull);
    expect(h.controller.todayKey, '2026-10-09');
  });

  test('startup removes orphan files (F6f)', () async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    writeSourcePhoto(h.storage.directory, 'orphan.jpg');
    await h.controller.startup();
    expect(await h.storage.listFileNames(), ['2026-10-01_1.jpg']);
  });

  test('months cover 12 months or back to the oldest entry', () async {
    h = await TestHarness.create();
    await h.controller.startup();
    expect(h.controller.months, hasLength(12));

    h.repo.rows.clear();
    h.dispose();
    h = await TestHarness.create(photoDays: ['2024-10-15']);
    await h.controller.startup();
    expect(h.controller.months.last, const YearMonth(2024, 10));
    expect(h.controller.months.first, const YearMonth(2026, 10));
  });

  test('addPhoto stores the entry and notifies listeners', () async {
    h = await TestHarness.create();
    await h.controller.startup();
    var notified = 0;
    h.controller.addListener(() => notified++);
    h.picker.galleryResult = writeSourcePhoto(h.root);

    final entry = await h.controller.addPhoto(
      '2026-10-03',
      PhotoSource.gallery,
    );
    expect(entry!.dateKey, '2026-10-03');
    expect(h.controller.entryFor('2026-10-03'), entry);
    expect(notified, 1);
  });

  test('cancelled addPhoto neither changes nor notifies (F2c)', () async {
    h = await TestHarness.create();
    await h.controller.startup();
    var notified = 0;
    h.controller.addListener(() => notified++);
    expect(await h.controller.addPhoto('2026-10-09', PhotoSource.camera), null);
    expect(h.controller.isEmpty, isTrue);
    expect(notified, 0);
  });

  test('deleteEntry removes the entry', () async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    await h.controller.startup();
    await h.controller.deleteEntry('2026-10-01');
    expect(h.controller.entryFor('2026-10-01'), isNull);
    expect(h.repo.rows, isEmpty);
  });

  test('generateDemoData fills a year and reloads', () async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    await h.controller.startup();
    expect(await h.controller.generateDemoData(), 364);
    expect(h.controller.entryCount, 365);
  });

  test('generateDemoData without photos returns null', () async {
    h = await TestHarness.create();
    await h.controller.startup();
    expect(await h.controller.generateDemoData(), isNull);
    expect(h.controller.isEmpty, isTrue);
  });

  test('startup errors are kept for the UI and still load data', () async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    h.picker.lostResult = h.storage.resolve('missing.jpg');
    await h.controller.startup();
    expect(h.controller.isLoading, isFalse);
    expect(h.controller.takePendingError(), isA<PhotoSaveException>());
    expect(h.controller.takePendingError(), isNull);
  });

  test('updateNote stores the note and notifies once', () async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    await h.controller.startup();
    var notified = 0;
    h.controller.addListener(() => notified++);
    await h.controller.updateNote('2026-10-01', 'Merhaba');
    expect(h.controller.entryFor('2026-10-01')!.note, 'Merhaba');
    expect(notified, 1);
    await h.controller.updateNote('2026-10-01', 'Merhaba');
    expect(notified, 1, reason: 'unchanged note does not rebuild');
  });

  test('updateDetails stores category and notifies', () async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    await h.controller.startup();
    var notified = 0;
    h.controller.addListener(() => notified++);
    await h.controller.updateDetails(
      '2026-10-01',
      note: '',
      category: PhotoCategory.friends,
    );
    expect(
      h.controller.entryFor('2026-10-01')!.category,
      PhotoCategory.friends,
    );
    expect(notified, 1);
  });

  test('fileExists checks the disk once per file and resets on load', () async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    await h.controller.startup();
    final entry = h.controller.entryFor('2026-10-01')!;
    expect(h.controller.fileExists(entry), isTrue);
    h.controller.fileFor(entry).deleteSync();
    expect(h.controller.fileExists(entry), isTrue, reason: 'cached');
    await h.controller.load();
    expect(h.controller.fileExists(entry), isFalse);
  });
}
