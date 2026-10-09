import 'package:flutter/material.dart';

import '../../core/date_key.dart';
import '../../core/theme.dart';
import '../../data/entry.dart';
import '../../state/timeline_controller.dart';
import '../timeline/day_cell.dart';
import '../widgets/category_style.dart';
import '../widgets/l10n.dart';
import '../widgets/motion.dart';
import 'day_detail_screen.dart';

/// Opens the read-only preview card of [dateKey] (ISKELET F11).
///
/// A page route (not a dialog) so the grid thumbnail can Hero into it.
Future<void> showDayPreview(
  BuildContext context,
  TimelineController controller,
  String dateKey, {
  String? heroTag,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: AppMotion.medium,
      reverseTransitionDuration: AppMotion.short,
      pageBuilder: (_, _, _) => DayPreview(
        controller: controller,
        dateKey: dateKey,
        heroTag: heroTag,
      ),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.curve,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// Preview card: fixed-size photo, date, category and note as saved.
///
/// Nothing is edited here; "Tam ekran" leads to the editable detail.
class DayPreview extends StatelessWidget {
  /// Creates the preview of [dateKey].
  const DayPreview({
    super.key,
    required this.controller,
    required this.dateKey,
    this.heroTag,
  });

  /// Hero tag of the tapped thumbnail; the grid cell's tag by default.
  final String? heroTag;

  /// Source of the entry.
  final TimelineController controller;

  /// Day being previewed.
  final String dateKey;

  void _openFull(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            DayDetailScreen(controller: controller, dateKey: dateKey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = controller.entryFor(dateKey);
    final p = context.palette;
    final s = context.strings;
    final category = entry?.category;
    final hasNote = entry?.hasNote ?? false;
    return GestureDetector(
      // Taps on the dimmed area close the card; taps on it do not.
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Material(
                  color: p.surfaceHigh,
                  elevation: 12,
                  shadowColor: Colors.black54,
                  borderRadius: BorderRadius.circular(AppDimens.dialogRadius),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (entry != null) _photo(context, entry),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatLongDate(dateKey, strings: s),
                              style: AppText.headline.copyWith(
                                color: p.onSurface,
                              ),
                            ),
                            if (category != null) ...[
                              const SizedBox(height: 12),
                              CategoryChip(
                                key: const ValueKey('preview-category'),
                                category: category,
                                selected: true,
                              ),
                            ],
                            if (hasNote) ...[
                              const SizedBox(height: 12),
                              Text(
                                entry!.note!,
                                key: const ValueKey('preview-note'),
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body.copyWith(
                                  color: p.onSurface,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (category == null && !hasNote) ...[
                              const SizedBox(height: 8),
                              Text(
                                s.previewEmptyHint,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: p.dayMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: PressScale(
                                child: FilledButton.icon(
                                  key: const ValueKey('open-full'),
                                  onPressed: entry == null
                                      ? null
                                      : () => _openFull(context),
                                  icon: const Icon(
                                    Icons.open_in_full_rounded,
                                    size: 18,
                                  ),
                                  label: Text(s.fullScreen),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _photo(BuildContext context, Entry entry) {
    final file = controller.fileFor(entry);
    final p = context.palette;
    final broken = ColoredBox(
      color: p.surface,
      child: Center(
        child: Icon(Icons.broken_image, size: 48, color: p.dayMuted),
      ),
    );
    return AspectRatio(
      key: const ValueKey('preview-photo'),
      aspectRatio: 1,
      child: GestureDetector(
        onTap: () => _openFull(context),
        child: file.existsSync()
            ? Hero(
                tag: heroTag ?? photoHeroTag(dateKey),
                child: Image.file(
                  file,
                  key: ValueKey(entry.fileName),
                  fit: BoxFit.cover,
                  // Big enough for the card, far below full resolution.
                  cacheWidth: 1080,
                  errorBuilder: (context, error, stack) => broken,
                ),
              )
            : broken,
      ),
    );
  }
}
