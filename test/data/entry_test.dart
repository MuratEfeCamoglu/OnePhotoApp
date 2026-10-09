import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/data/entry.dart';

void main() {
  final created = DateTime.fromMillisecondsSinceEpoch(1760000000000);
  final updated = DateTime.fromMillisecondsSinceEpoch(1760000005000);
  final entry = Entry(
    dateKey: '2026-10-09',
    fileName: '2026-10-09_1760000000000.jpg',
    createdAt: created,
    updatedAt: updated,
  );

  test('toMap uses the entries table column names and epoch ms', () {
    expect(entry.toMap(), {
      'date_key': '2026-10-09',
      'file_name': '2026-10-09_1760000000000.jpg',
      'created_at': 1760000000000,
      'updated_at': 1760000005000,
      'note': null,
    });
  });

  test('fromMap round-trips', () {
    expect(Entry.fromMap(entry.toMap()), entry);
  });

  test('copyWith replaces only given fields', () {
    final copy = entry.copyWith(fileName: 'x.jpg');
    expect(copy.fileName, 'x.jpg');
    expect(copy.dateKey, entry.dateKey);
    expect(copy.createdAt, entry.createdAt);
  });

  test('equality is value based', () {
    expect(entry.copyWith(), entry);
    expect(entry.hashCode, entry.copyWith().hashCode);
    expect(entry == entry.copyWith(dateKey: '2026-10-10'), isFalse);
  });

  test('note round-trips and withNote can clear it', () {
    final noted = entry.withNote('Sahilde gün batımı');
    expect(noted.hasNote, isTrue);
    expect(Entry.fromMap(noted.toMap()), noted);
    expect(noted.withNote(null).hasNote, isFalse);
    expect(noted == entry, isFalse);
  });

  test('copyWith keeps the note', () {
    expect(entry.withNote('x').copyWith(fileName: 'y.jpg').note, 'x');
  });

  test('rows written before notes existed read as no note', () {
    final legacy = Map.of(entry.toMap())..remove('note');
    expect(Entry.fromMap(legacy).note, isNull);
  });
}
