import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/categories.dart';
import '../core/clock.dart';
import '../core/date_key.dart';
import '../core/errors.dart';
import '../data/entry.dart';
import '../data/entry_repository.dart';
import '../data/photo_storage.dart';
import 'photo_picker.dart';
import 'settings_store.dart';

/// Orchestrates picking, copying, persisting and deleting day photos.
class PhotoService {
  /// Wires the service; [clock] decides what "today" is.
  PhotoService({
    required this._repository,
    required this._storage,
    required this._picker,
    required this._settings,
    required this._clock,
  });

  final EntryRepository _repository;
  final PhotoStorage _storage;
  final PhotoPicker _picker;
  final SettingsStore _settings;
  final Clock _clock;

  /// Day key of the current local day.
  String todayKey() => dateKeyOf(_clock());

  /// Every stored entry.
  Future<List<Entry>> loadAll() => _repository.getAll();

  /// File holding [entry]'s photo; may be missing on disk.
  File fileFor(Entry entry) => _storage.resolve(entry.fileName);

  /// Opens the picker and stores the result as [dateKey]'s photo.
  ///
  /// Returns `null` (and changes nothing) when the user cancels.
  Future<Entry?> pickAndSave(String dateKey, PhotoSource source) async {
    // Saved first so a photo survives Android killing the activity.
    await _settings.setPendingDateKey(dateKey);
    try {
      final file = switch (source) {
        PhotoSource.camera => await _picker.pickFromCamera(),
        PhotoSource.gallery => await _picker.pickFromGallery(),
      };
      if (file == null) return null;
      return await savePhoto(dateKey, file);
    } finally {
      await _settings.setPendingDateKey(null);
    }
  }

  /// Copies [source] in as the photo of [dateKey], replacing any old one.
  ///
  /// Order matters (ISKELET F4c): write new file → update DB → delete old.
  Future<Entry> savePhoto(String dateKey, File source) async {
    final now = _clock();
    final existing = await _guard(() => _repository.getByDate(dateKey));
    final fileName = await _storage.save(source, dateKey: dateKey, now: now);
    final entry = Entry(
      dateKey: dateKey,
      fileName: fileName,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      // A new photo does not erase what the user wrote about the day.
      note: existing?.note,
      category: existing?.category,
    );
    try {
      await _repository.upsert(entry);
    } on Exception catch (e) {
      // The DB still points to the old file, so only the new copy goes.
      await _storage.delete(fileName);
      throw e is PhotoSaveException ? e : PhotoSaveException(e);
    }
    if (existing != null) await _deleteFileLater(existing.fileName);
    return entry;
  }

  /// Stores [note] for the photo of [dateKey], keeping its category.
  Future<Entry?> saveNote(String dateKey, String note) async {
    final existing = await _guard(() => _repository.getByDate(dateKey));
    if (existing == null) return null;
    return saveDetails(dateKey, note: note, category: existing.category);
  }

  /// Stores [note] and [category] for the photo of [dateKey]
  /// (ISKELET F11, F12).
  ///
  /// Blank notes are removed. Returns the updated entry, or `null` when the
  /// day has no photo.
  Future<Entry?> saveDetails(
    String dateKey, {
    required String note,
    required PhotoCategory? category,
  }) async {
    final existing = await _guard(() => _repository.getByDate(dateKey));
    if (existing == null) return null;
    final trimmed = note.trim();
    final clipped = trimmed.length > Entry.maxNoteLength
        ? trimmed.substring(0, Entry.maxNoteLength)
        : trimmed;
    final updated = existing.withDetails(
      note: clipped.isEmpty ? null : clipped,
      category: category,
      updatedAt: _clock(),
    );
    if (updated.note == existing.note &&
        updated.category == existing.category) {
      return existing;
    }
    await _repository.upsert(updated);
    return updated;
  }

  /// Removes the entry of [dateKey] and then its file.
  Future<void> deleteEntry(String dateKey) async {
    final existing = await _guard(() => _repository.getByDate(dateKey));
    if (existing == null) return;
    await _repository.delete(dateKey);
    await _deleteFileLater(existing.fileName);
  }

  /// Deletes files in `photos/` no entry refers to (ISKELET F6f).
  Future<int> cleanOrphans() async {
    final referenced = {
      for (final entry in await _repository.getAll()) entry.fileName,
    };
    var removed = 0;
    for (final name in await _storage.listFileNames()) {
      if (referenced.contains(name)) continue;
      await _storage.delete(name);
      removed++;
    }
    return removed;
  }

  /// Saves a photo whose picker session Android interrupted, if any.
  ///
  /// It goes to the day stored before the picker opened, else today.
  Future<Entry?> recoverLostPhoto() async {
    final pending = _settings.pendingDateKey;
    try {
      final file = await _picker.retrieveLost();
      if (file == null) return null;
      return await savePhoto(pending ?? todayKey(), file);
    } finally {
      if (pending != null) await _settings.setPendingDateKey(null);
    }
  }

  /// Debug helper (ISKELET §6 stage 8): fills every empty day of the last
  /// [days] days with a copy of the newest existing photo.
  ///
  /// Returns how many days were filled, or `null` without a usable photo.
  Future<int?> fillDemoDays(int days) async {
    final entries = await _repository.getAll()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    File? source;
    for (final entry in entries) {
      final file = fileFor(entry);
      if (file.existsSync()) {
        source = file;
        break;
      }
    }
    if (source == null) return null;
    final taken = {for (final e in entries) e.dateKey};
    final today = _clock();
    var filled = 0;
    for (var i = 0; i < days; i++) {
      // Calendar arithmetic instead of Duration keeps DST days intact.
      final key = dateKeyOf(DateTime(today.year, today.month, today.day - i));
      if (taken.contains(key)) continue;
      await savePhoto(key, source);
      filled++;
    }
    return filled;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PhotoSaveException {
      rethrow;
    } on Exception catch (e) {
      throw PhotoSaveException(e);
    }
  }

  Future<void> _deleteFileLater(String fileName) async {
    try {
      await _storage.delete(fileName);
    } on PhotoSaveException catch (e) {
      // The entry is already consistent; the leftover file is removed by
      // the next launch's orphan cleanup.
      if (kDebugMode) debugPrint('Old photo not deleted: $e');
    }
  }
}
