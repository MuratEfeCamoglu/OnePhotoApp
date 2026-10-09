import 'package:flutter/material.dart';

import '../../core/date_key.dart';
import '../../core/theme.dart';
import '../../data/entry.dart';
import '../../state/timeline_controller.dart';
import '../timeline/day_cell.dart';
import '../widgets/add_photo_flow.dart';
import '../widgets/category_style.dart';
import 'details_editor.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/l10n.dart';
import '../widgets/motion.dart';

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
      question: context.strings.deleteQuestion,
      confirmLabel: context.strings.delete,
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
    final p = context.palette;
    final s = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(formatLongDate(dateKey, strings: s))),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final entry = controller.entryFor(dateKey);
          if (entry == null) return const SizedBox.expand();
          final file = controller.fileFor(entry);
          final broken = ColoredBox(
            color: p.surface,
            child: Center(
              child: Icon(Icons.broken_image, size: 48, color: p.dayMuted),
            ),
          );
          if (!file.existsSync()) return SizedBox.expand(child: broken);
          final viewer = InteractiveViewer(
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
          return Column(
            children: [
              Expanded(child: viewer),
              _DetailsPanel(
                entry: entry,
                onEdit: () => showDetailsEditor(context, controller, dateKey),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8),
        child: EntranceAnimation(
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
                    label: s.replace,
                    background: p.surface,
                    foreground: p.onSurface,
                    onPressed: () => chooseSourceAndAdd(
                      context,
                      controller,
                      dateKey,
                      showDetails: false,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.delete,
                    label: s.delete,
                    background: p.errorContainer,
                    foreground: p.error,
                    onPressed: () => _delete(context),
                  ),
                ),
              ],
            ),
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
    return PressScale(
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}

/// Category and note of the day with an edit button (ISKELET F11, F12).
class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.entry, required this.onEdit});

  final Entry entry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.strings;
    final category = entry.category;
    final empty = category == null && !entry.hasNote;
    return Container(
      key: const ValueKey('detail-note'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (empty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            s.addDetails,
                            style: AppText.body.copyWith(color: p.dayMuted),
                          ),
                        ),
                      if (category != null)
                        CategoryChip(
                          key: const ValueKey('detail-category'),
                          category: category,
                          selected: true,
                        ),
                      if (category != null && entry.hasNote)
                        const SizedBox(height: 12),
                      if (entry.hasNote)
                        ConstrainedBox(
                          // Long notes scroll instead of squeezing the photo.
                          constraints: const BoxConstraints(maxHeight: 140),
                          child: SingleChildScrollView(
                            child: Text(
                              entry.note!,
                              style: AppText.body.copyWith(
                                color: p.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('edit-details'),
                  tooltip: s.editDetails,
                  onPressed: onEdit,
                  icon: Icon(
                    empty ? Icons.add_circle_rounded : Icons.edit_rounded,
                    color: p.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
