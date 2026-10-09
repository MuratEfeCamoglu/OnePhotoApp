import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/photo_picker.dart';
import 'l10n.dart';

/// Opens the "Fotoğraf çek / Galeriden seç / Vazgeç" sheet (ISKELET F3a).
///
/// Resolves to the chosen source, or `null` when cancelled.
Future<PhotoSource?> showPhotoSourceSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<PhotoSource>(
    context: context,
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
    final p = context.palette;
    final s = context.strings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: p.handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: p.onSurface,
                ),
              ),
            ),
            _SourceTile(
              icon: Icons.photo_camera,
              label: s.takePhoto,
              onTap: () => navigator.pop(PhotoSource.camera),
            ),
            _SourceTile(
              icon: Icons.photo_library,
              label: s.pickFromGallery,
              onTap: () => navigator.pop(PhotoSource.gallery),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  textStyle: Theme.of(context).textTheme.labelLarge!
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onPressed: () => navigator.pop(),
                child: Text(s.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(icon, size: 24, color: context.palette.onSurfaceVariant),
              const SizedBox(width: 16),
              Text(
                label,
                style: AppText.body.copyWith(color: context.palette.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
