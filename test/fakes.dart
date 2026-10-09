import 'dart:io';

import 'package:one_photo_app/core/errors.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/data/entry.dart';
import 'package:one_photo_app/data/entry_repository.dart';
import 'package:one_photo_app/data/photo_storage.dart';
import 'package:one_photo_app/services/photo_picker.dart';
import 'package:one_photo_app/services/photo_service.dart';
import 'package:one_photo_app/services/reminder_service.dart';
import 'package:one_photo_app/services/settings_store.dart';
import 'package:one_photo_app/state/appearance_controller.dart';
import 'package:one_photo_app/state/timeline_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Map based [EntryRepository] that can simulate database failures.
class FakeEntryRepository implements EntryRepository {
  FakeEntryRepository([Iterable<Entry> entries = const []])
    : rows = {for (final e in entries) e.dateKey: e};

  final Map<String, Entry> rows;
  bool failUpserts = false;

  @override
  Future<List<Entry>> getAll() async => rows.values.toList();

  @override
  Future<Entry?> getByDate(String dateKey) async => rows[dateKey];

  @override
  Future<void> upsert(Entry entry) async {
    if (failUpserts) throw const PhotoSaveException('db down');
    rows[entry.dateKey] = entry;
  }

  @override
  Future<void> delete(String dateKey) async => rows.remove(dateKey);
}

/// [PhotoPicker] returning preset files or errors.
class FakePhotoPicker implements PhotoPicker {
  File? cameraResult;
  File? galleryResult;
  File? lostResult;
  Exception? error;
  int cameraCalls = 0;
  int galleryCalls = 0;

  /// Called while the picker is "open", e.g. to inspect pending state.
  void Function()? onOpen;

  @override
  Future<File?> pickFromCamera() async {
    cameraCalls++;
    onOpen?.call();
    if (error != null) throw error!;
    return cameraResult;
  }

  @override
  Future<File?> pickFromGallery() async {
    galleryCalls++;
    onOpen?.call();
    if (error != null) throw error!;
    return galleryResult;
  }

  @override
  Future<File?> retrieveLost() async => lostResult;
}

/// [PhotoStorage] using synchronous I/O so widget tests (fake async) work.
class SyncPhotoStorage extends PhotoStorage {
  SyncPhotoStorage(super.directory) {
    directory.createSync(recursive: true);
  }

  @override
  Future<String> save(
    File source, {
    required String dateKey,
    required DateTime now,
  }) async {
    if (!source.existsSync()) throw const PhotoSaveException('no source');
    var stamp = now.millisecondsSinceEpoch;
    while (resolve('${dateKey}_$stamp.jpg').existsSync()) {
      stamp++;
    }
    final name = '${dateKey}_$stamp.jpg';
    source.copySync(resolve(name).path);
    return name;
  }

  @override
  Future<void> delete(String fileName) async {
    final file = resolve(fileName);
    if (file.existsSync()) file.deleteSync();
  }

  @override
  Future<List<String>> listFileNames() async => [
    for (final f in directory.listSync().whereType<File>())
      f.uri.pathSegments.last,
  ];
}

/// Everything a widget test needs to drive a real [TimelineController].
class TestHarness {
  TestHarness._(this.root, this.repo, this.picker, this.storage, this.settings);

  /// Builds a harness with [entries] whose files exist unless listed in
  /// [missingFiles].
  static Future<TestHarness> create({
    Iterable<String> photoDays = const [],
    Iterable<String> missingDays = const [],
  }) async {
    final root = Directory.systemTemp.createTempSync('onephoto_ui');
    final storage = SyncPhotoStorage(Directory('${root.path}/photos'));
    final now = DateTime(2026, 1, 1);
    final entries = <Entry>[];
    for (final day in [...photoDays, ...missingDays]) {
      final name = '${day}_1.jpg';
      if (!missingDays.contains(day)) {
        writeSourcePhoto(storage.directory, name);
      }
      entries.add(
        Entry(dateKey: day, fileName: name, createdAt: now, updatedAt: now),
      );
    }
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsStore(await SharedPreferences.getInstance());
    return TestHarness._(
      root,
      FakeEntryRepository(entries),
      FakePhotoPicker(),
      storage,
      settings,
    );
  }

  final Directory root;
  final FakeEntryRepository repo;
  final FakePhotoPicker picker;
  final SyncPhotoStorage storage;
  final SettingsStore settings;

  /// The fixed "now" of UI tests: Friday 9 October 2026, noon.
  DateTime now = DateTime(2026, 10, 9, 12);

  late final PhotoService service = PhotoService(
    repository: repo,
    storage: storage,
    picker: picker,
    settings: settings,
    clock: () => now,
  );

  late final TimelineController controller = TimelineController(
    service: service,
    clock: () => now,
  );

  final FakeReminderScheduler scheduler = FakeReminderScheduler();

  late final ReminderService reminders = ReminderService(
    settings: settings,
    scheduler: scheduler,
  );

  late final AppearanceController appearance = AppearanceController(
    settings: settings,
    reminders: reminders,
  );

  void dispose() => root.deleteSync(recursive: true);
}

/// [ReminderScheduler] recording calls instead of touching the platform.
class FakeReminderScheduler implements ReminderScheduler {
  bool grant = true;
  Exception? error;
  int? scheduledMinutes;
  Strings? scheduledStrings;
  int permissionRequests = 0;
  int cancels = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<void> scheduleDaily(int minutes, Strings strings) async {
    if (error != null) throw error!;
    scheduledMinutes = minutes;
    scheduledStrings = strings;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    scheduledMinutes = null;
  }
}

/// Writes a small fake "photo" file into [dir].
File writeSourcePhoto(Directory dir, [String name = 'source.jpg']) {
  final file = File('${dir.path}/$name');
  file.writeAsBytesSync(List<int>.generate(64, (i) => i));
  return file;
}
