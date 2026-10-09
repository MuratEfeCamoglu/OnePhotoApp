import 'package:flutter/material.dart';

import '../../core/date_key.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/timeline_controller.dart';
import '../timeline/day_cell.dart';
import '../widgets/add_photo_flow.dart';
import '../widgets/error_snackbar.dart';

/// Full-screen photo of one day with replace and delete (ISKELET F5).
class DayDetailScreen extends StatelessWidget {
  /// Creates the detail view of [dateKey].
  const DayDetailScreen({
    super.key,
    required this.controller,
    required this.dateKey,
  });

  /// Source of the entry and actions.
  final TimelineController controller;

  /// Day being shown.
  final String dateKey;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      question: Strings.deleteQuestion,
      confirmLabel: Strings.delete,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await controller.deleteEntry(dateKey);
      if (context.mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(formatLongDate(dateKey))),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final entry = controller.entryFor(dateKey);
          if (entry == null) return const SizedBox.expand();
          final file = controller.fileFor(entry);
          const broken = ColoredBox(
            color: AppColors.surface,
            child: Center(
              child: Icon(
                Icons.broken_image,
                size: 48,
                color: AppColors.dayMuted,
              ),
            ),
          );
          if (!file.existsSync()) return const SizedBox.expand(child: broken);
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: SizedBox.expand(
              child: Hero(
                tag: photoHeroTag(dateKey),
                // Full-size decode only here; the grid uses thumbnails.
                child: Image.file(
                  file,
                  key: ValueKey(entry.fileName),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => broken,
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gutter,
            AppDimens.gutter,
            AppDimens.gutter,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.autorenew,
                  label: Strings.replace,
                  background: AppColors.surface,
                  foreground: AppColors.onSurface,
                  onPressed: () =>
                      chooseSourceAndAdd(context, controller, dateKey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.delete,
                  label: Strings.delete,
                  background: AppColors.errorContainer,
                  foreground: AppColors.error,
                  onPressed: () => _delete(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
