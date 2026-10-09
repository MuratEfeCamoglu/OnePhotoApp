import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/errors.dart';

/// Where a new photo comes from.
enum PhotoSource { camera, gallery }

/// Platform photo picker; the only abstraction over `image_picker`.
abstract interface class PhotoPicker {
  /// Opens the system camera; `null` when the user cancels.
  Future<File?> pickFromCamera();

  /// Opens the gallery; `null` when the user cancels.
  Future<File?> pickFromGallery();

  /// Photo from a picker session whose activity Android killed, if any.
  Future<File?> retrieveLost();
}

/// [PhotoPicker] using `image_picker` with the storage limits of F6d.
class ImagePickerPhotoPicker implements PhotoPicker {
  /// Creates a picker; [picker] is injectable for completeness.
  ImagePickerPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  /// Longest edge in pixels (ISKELET F6d).
  static const maxSide = 2048.0;

  /// JPEG quality (ISKELET F6d).
  static const quality = 85;

  final ImagePicker _picker;

  @override
  Future<File?> pickFromCamera() =>
      _pick(ImageSource.camera, PermissionKind.camera);

  @override
  Future<File?> pickFromGallery() =>
      _pick(ImageSource.gallery, PermissionKind.photos);

  @override
  Future<File?> retrieveLost() async {
    // Only Android can kill the activity while the picker is open.
    if (!Platform.isAndroid) return null;
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return null;
    final error = response.exception;
    if (error != null) throw _translate(error, PermissionKind.camera);
    final file = response.file;
    return file == null ? null : File(file.path);
  }

  Future<File?> _pick(ImageSource source, PermissionKind kind) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: quality,
        requestFullMetadata: false,
      );
      return file == null ? null : File(file.path);
    } on PlatformException catch (e) {
      throw _translate(e, kind);
    }
  }

  Exception _translate(PlatformException e, PermissionKind kind) {
    // image_picker reports refusals as `camera_access_denied` /
    // `photo_access_denied`.
    return e.code.contains('access_denied')
        ? PermissionDeniedException(kind)
        : PhotoSaveException(e);
  }
}
