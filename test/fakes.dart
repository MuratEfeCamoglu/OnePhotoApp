import 'dart:io';

import 'package:one_photo_app/core/errors.dart';
import 'package:one_photo_app/data/entry.dart';
import 'package:one_photo_app/data/entry_repository.dart';
import 'package:one_photo_app/services/photo_picker.dart';

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

/// Writes a small fake "photo" file into [dir].
File writeSourcePhoto(Directory dir, [String name = 'source.jpg']) {
  final file = File('${dir.path}/$name');
  file.writeAsBytesSync(List<int>.generate(64, (i) => i));
  return file;
}
