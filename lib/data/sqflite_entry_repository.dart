import 'package:sqflite/sqflite.dart';

import '../core/errors.dart';
import 'entry.dart';
import 'entry_repository.dart';

/// [EntryRepository] backed by the sqflite `entries` table (ISKELET §3).
class SqfliteEntryRepository implements EntryRepository {
  /// Wraps an already opened [Database] that has the `entries` table.
  SqfliteEntryRepository(this._db);

  /// Database file name inside the platform databases directory.
  static const fileName = 'one_photo.db';

  /// Schema version; bumping it requires a migration.
  static const schemaVersion = 1;

  static const _table = 'entries';

  final Database _db;

  /// Opens (and creates on first run) the database at [path].
  static Future<SqfliteEntryRepository> open(
    DatabaseFactory factory,
    String path,
  ) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE $_table (
            date_key TEXT PRIMARY KEY,
            file_name TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        '''),
      ),
    );
    return SqfliteEntryRepository(db);
  }

  /// Closes the underlying database.
  Future<void> close() => _db.close();

  @override
  Future<List<Entry>> getAll() async {
    final rows = await _db.query(_table);
    return rows.map(Entry.fromMap).toList();
  }

  @override
  Future<Entry?> getByDate(String dateKey) async {
    final rows = await _db.query(
      _table,
      where: 'date_key = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    return rows.isEmpty ? null : Entry.fromMap(rows.first);
  }

  @override
  Future<void> upsert(Entry entry) async {
    try {
      await _db.insert(
        _table,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      throw PhotoSaveException(e);
    }
  }

  @override
  Future<void> delete(String dateKey) async {
    try {
      await _db.delete(_table, where: 'date_key = ?', whereArgs: [dateKey]);
    } on DatabaseException catch (e) {
      throw PhotoSaveException(e);
    }
  }
}
