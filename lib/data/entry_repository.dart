import 'entry.dart';

/// Persistence for [Entry] rows; at most one entry per day key.
abstract interface class EntryRepository {
  /// All entries, in no particular order.
  Future<List<Entry>> getAll();

  /// The entry for [dateKey], or `null`.
  Future<Entry?> getByDate(String dateKey);

  /// Inserts or replaces the entry for `entry.dateKey`.
  Future<void> upsert(Entry entry);

  /// Removes the entry for [dateKey] if present.
  Future<void> delete(String dateKey);
}
