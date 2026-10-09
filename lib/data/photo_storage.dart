import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/errors.dart';

/// Owns the app's private `photos/` folder; only file names leave this class.
class PhotoStorage {
  /// Uses [directory] as the photos folder (a temp dir in tests).
  PhotoStorage(this.directory);

  /// Folder name under the documents directory.
  static const folderName = 'photos';

  /// The photos folder; resolved anew on every launch (ISKELET F6b).
  final Directory directory;

  /// Storage inside the app documents directory, created if missing.
  static Future<PhotoStorage> inDocuments() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, folderName));
    await dir.create(recursive: true);
    return PhotoStorage(dir);
  }

  /// Copies [source] in for [dateKey] and returns the new file name.
  ///
  /// The copy is independent from the gallery original (ISKELET F6a).
  Future<String> save(
    File source, {
    required String dateKey,
    required DateTime now,
  }) async {
    var stamp = now.millisecondsSinceEpoch;
    // A unique name guarantees a replace never overwrites the file the
    // database still points to.
    while (resolve(_name(dateKey, stamp)).existsSync()) {
      stamp++;
    }
    final name = _name(dateKey, stamp);
    final target = resolve(name);
    try {
      await directory.create(recursive: true);
      await source.copy(target.path);
    } on FileSystemException catch (e) {
      if (target.existsSync()) await target.delete();
      throw PhotoSaveException(e);
    }
    return name;
  }

  /// The file for [fileName]; it may not exist (ISKELET F6e).
  File resolve(String fileName) => File(p.join(directory.path, fileName));

  /// Deletes [fileName]; missing files are ignored.
  Future<void> delete(String fileName) async {
    final file = resolve(fileName);
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException catch (e) {
      throw PhotoSaveException(e);
    }
  }

  /// Names of all files currently in the photos folder.
  Future<List<String>> listFileNames() async {
    if (!directory.existsSync()) return const [];
    return [
      await for (final item in directory.list())
        if (item is File) p.basename(item.path),
    ];
  }

  static String _name(String dateKey, int stamp) => '${dateKey}_$stamp.jpg';
}
