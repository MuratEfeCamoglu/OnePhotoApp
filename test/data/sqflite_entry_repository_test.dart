import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/data/entry.dart';
import 'package:one_photo_app/data/sqflite_entry_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Entry _entry(String key, String file, {int created = 1000, int? updated}) =>
    Entry(
      dateKey: key,
      fileName: file,
      createdAt: DateTime.fromMillisecondsSinceEpoch(created),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updated ?? created),
    );

void main() {
  sqfliteFfiInit();
  late SqfliteEntryRepository repo;

  setUp(() async {
    repo = await SqfliteEntryRepository.open(
      databaseFactoryFfi,
      inMemoryDatabasePath,
    );
  });

  tearDown(() => repo.close());

  test('starts empty', () async {
    expect(await repo.getAll(), isEmpty);
    expect(await repo.getByDate('2026-10-09'), isNull);
  });

  test('upsert then getByDate returns the entry', () async {
    final e = _entry('2026-10-09', 'a.jpg');
    await repo.upsert(e);
    expect(await repo.getByDate('2026-10-09'), e);
  });

  test('upsert on the same day keeps a single row (F4a)', () async {
    await repo.upsert(_entry('2026-10-09', 'a.jpg'));
    await repo.upsert(_entry('2026-10-09', 'b.jpg', updated: 2000));
    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.fileName, 'b.jpg');
  });

  test('delete removes only that day', () async {
    await repo.upsert(_entry('2026-10-08', 'a.jpg'));
    await repo.upsert(_entry('2026-10-09', 'b.jpg'));
    await repo.delete('2026-10-09');
    final all = await repo.getAll();
    expect(all.map((e) => e.dateKey), ['2026-10-08']);
  });

  test('entries survive closing and reopening the database (F6c)', () async {
    final dir = await Directory.systemTemp.createTemp('onephoto_db');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, SqfliteEntryRepository.fileName);
    final first = await SqfliteEntryRepository.open(databaseFactoryFfi, path);
    await first.upsert(_entry('2026-10-09', 'a.jpg'));
    await first.close();

    final second = await SqfliteEntryRepository.open(databaseFactoryFfi, path);
    expect((await second.getAll()).single.fileName, 'a.jpg');
    await second.close();
  });
}
