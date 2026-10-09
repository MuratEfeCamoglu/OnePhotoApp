import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/errors.dart';
import 'package:one_photo_app/data/photo_storage.dart';
import 'package:path/path.dart' as p;

import '../fakes.dart';

void main() {
  late Directory root;
  late PhotoStorage storage;
  late File source;
  final now = DateTime.fromMillisecondsSinceEpoch(1760000000000);

  setUp(() {
    root = Directory.systemTemp.createTempSync('onephoto_storage');
    storage = PhotoStorage(Directory(p.join(root.path, 'photos')));
    source = writeSourcePhoto(root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('save copies the file and returns only a file name', () async {
    final name = await storage.save(source, dateKey: '2026-10-09', now: now);
    expect(name, '2026-10-09_1760000000000.jpg');
    expect(p.basename(name), name);
    expect(storage.resolve(name).readAsBytesSync(), source.readAsBytesSync());
  });

  test('the copy survives deleting the original (F6a)', () async {
    final name = await storage.save(source, dateKey: '2026-10-09', now: now);
    source.deleteSync();
    expect(storage.resolve(name).existsSync(), isTrue);
  });

  test('save never reuses an existing name', () async {
    final a = await storage.save(source, dateKey: '2026-10-09', now: now);
    final b = await storage.save(source, dateKey: '2026-10-09', now: now);
    expect(a, isNot(b));
    expect(storage.resolve(a).existsSync(), isTrue);
  });

  test('missing source throws PhotoSaveException and leaves no file', () async {
    source.deleteSync();
    await expectLater(
      storage.save(source, dateKey: '2026-10-09', now: now),
      throwsA(isA<PhotoSaveException>()),
    );
    expect(await storage.listFileNames(), isEmpty);
  });

  test('delete removes a file and ignores missing ones', () async {
    final name = await storage.save(source, dateKey: '2026-10-09', now: now);
    await storage.delete(name);
    expect(storage.resolve(name).existsSync(), isFalse);
    await storage.delete('nope.jpg');
  });

  test('listFileNames returns base names', () async {
    final name = await storage.save(source, dateKey: '2026-10-09', now: now);
    expect(await storage.listFileNames(), [name]);
  });
}
