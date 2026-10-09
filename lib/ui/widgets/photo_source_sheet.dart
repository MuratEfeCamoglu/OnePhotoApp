import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../services/photo_picker.dart';

/// Opens the "Fotoğraf çek / Galeriden seç / Vazgeç" sheet (ISKELET F3a).
///
/// Resolves to the chosen source, or `null` when cancelled.
Future<PhotoSource?> showPhotoSourceSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<PhotoSource>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.background,
    builder: (_) => PhotoSourceSheet(title: title),
  );
}

/// Bottom sheet content listing the photo sources for one day.
class PhotoSourceSheet extends StatelessWidget {
  /// Creates the sheet with the day's [title], e.g. "5 Ekim 2026".
  const PhotoSourceSheet({super.key, required this.title});

  /// Day shown above the options.
  final String title;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text(Strings.takePhoto),
            onTap: () => navigator.pop(PhotoSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text(Strings.pickFromGallery),
            onTap: () => navigator.pop(PhotoSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text(Strings.cancel),
            onTap: () => navigator.pop(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
