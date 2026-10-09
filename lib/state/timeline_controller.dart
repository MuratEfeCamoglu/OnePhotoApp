import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/calendar.dart';
import '../core/categories.dart';
import '../core/clock.dart';
import '../core/date_key.dart';
import '../data/entry.dart';
import '../services/photo_picker.dart';
import '../services/photo_service.dart';

/// Holds every entry keyed by day and notifies the timeline on changes.
class TimelineController extends ChangeNotifier {
  /// Creates a controller; call [startup] once before showing data.
  TimelineController({required this._service, required this._clock});

  final PhotoService _service;
  final Clock _clock;
  final Map<String, Entry> _entries = {};
  bool _loading = true;
  Exception? _pendingError;

  /// True until the first [load] finishes.
  bool get isLoading => _loading;

  /// Whether no day has a photo yet.
  bool get isEmpty => _entries.isEmpty;

  /// Number of stored entries.
  int get entryCount => _entries.length;

  /// Day key of the current local day.
  String get todayKey => dateKeyOf(_clock());

  /// Entry of [dateKey], if any.
  Entry? entryFor(String dateKey) => _entries[dateKey];

  /// Photo file of [entry]; it may be missing on disk.
  File fileFor(Entry entry) => _service.fileFor(entry);

  /// Months to render, newest first (ISKELET F1b).
  List<YearMonth> get months {
    String? oldest;
    for (final key in _entries.keys) {
      if (oldest == null || key.compareTo(oldest) < 0) oldest = key;
    }
    return visibleMonths(
      current: YearMonth.fromDate(_clock()),
      earliest: oldest == null ? null : YearMonth.fromDateKey(oldest),
    );
  }

  /// Returns and clears an error raised outside a user action.
  Exception? takePendingError() {
    final error = _pendingError;
    _pendingError = null;
    return error;
  }

  /// Launch work: orphan cleanup, lost photo recovery, then [load].
  Future<void> startup() async {
    try {
      await _service.cleanOrphans();
      await _service.recoverLostPhoto();
    } on Exception catch (e) {
      // Startup has no caller that can show UI, so the screen picks the
      // error up through takePendingError after the next notification.
      _pendingError = e;
    }
    await load();
  }

  /// Reloads every entry from storage.
  Future<void> load() async {
    final all = await _service.loadAll();
    _entries
      ..clear()
      ..addEntries(all.map((e) => MapEntry(e.dateKey, e)));
    _loading = false;
    notifyListeners();
  }

  /// Picks a photo from [source] for [dateKey]; `null` if cancelled.
  Future<Entry?> addPhoto(String dateKey, PhotoSource source) async {
    final entry = await _service.pickAndSave(dateKey, source);
    if (entry != null) {
      _entries[dateKey] = entry;
      notifyListeners();
    }
    return entry;
  }

  /// Debug only: fills the last 365 days with copies of an existing photo.
  ///
  /// Returns the number of filled days, or `null` when there is no photo.
  Future<int?> generateDemoData() async {
    final filled = await _service.fillDemoDays(365);
    if (filled != null) await load();
    return filled;
  }

  /// Saves the note of [dateKey]'s photo; blank text removes it.
  Future<void> updateNote(String dateKey, String note) async {
    final entry = _entries[dateKey];
    if (entry == null) return;
    await updateDetails(dateKey, note: note, category: entry.category);
  }

  /// Saves note and category of [dateKey]'s photo (ISKELET F11, F12).
  Future<void> updateDetails(
    String dateKey, {
    required String note,
    required PhotoCategory? category,
  }) async {
    final updated = await _service.saveDetails(
      dateKey,
      note: note,
      category: category,
    );
    if (updated == null || updated == _entries[dateKey]) return;
    _entries[dateKey] = updated;
    notifyListeners();
  }

  /// Deletes the photo of [dateKey].
  Future<void> deleteEntry(String dateKey) async {
    await _service.deleteEntry(dateKey);
    _entries.remove(dateKey);
    notifyListeners();
  }
}
