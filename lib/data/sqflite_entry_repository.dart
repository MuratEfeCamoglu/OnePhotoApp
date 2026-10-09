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

  /// Schema version; bumping it requires a migration in [_upgrade].
  ///
  /// 1: initial table. 2: nullable `note` column (ISKELET F11).
  /// 3: nullable `category` column (ISKELET F12).
  static const schemaVersion = 3;

  static const _table = 'entries';

  final Database _db;

  /// Opens (and creates or migrates) the database at [path].
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
            updated_at INTEGER NOT NULL,
            note TEXT,
            category TEXT
          )
        '''),
        onUpgrade: _upgrade,
      ),
    );
    return SqfliteEntryRepository(db);
  }

  // Additive steps only, so existing photos stay reachable after updates.
  static Future<void> _upgrade(Database db, int from, int to) async {
    if (from < 2) await db.execute('ALTER TABLE $_table ADD COLUMN note TEXT');
    if (from < 3) {
      await db.execute('ALTER TABLE $_table ADD COLUMN category TEXT');
    }
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
