import 'package:flutter/material.dart';

import '../../core/categories.dart';
import '../../core/date_key.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/entry.dart';
import '../../state/timeline_controller.dart';
import '../timeline/day_cell.dart';
import '../widgets/category_style.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/l10n.dart';
import '../widgets/motion.dart';
import 'day_detail_screen.dart';

/// Opens the preview card of [dateKey]: photo plus the day's note (F11).
///
/// A page route (not a dialog) so the grid thumbnail can Hero into it.
Future<void> showDayPreview(
  BuildContext context,
  TimelineController controller,
  String dateKey,
) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: AppMotion.medium,
      reverseTransitionDuration: AppMotion.short,
      pageBuilder: (_, _, _) =>
          DayPreview(controller: controller, dateKey: dateKey),
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

/// Preview card: fixed-size photo, date, editable note.
class DayPreview extends StatefulWidget {
  /// Creates the preview of [dateKey].
  const DayPreview({
    super.key,
    required this.controller,
    required this.dateKey,
  });

  /// Source of the entry and note saving.
  final TimelineController controller;

  /// Day being previewed.
  final String dateKey;

  @override
  State<DayPreview> createState() => _DayPreviewState();
}

class _DayPreviewState extends State<DayPreview> {
  late final TextEditingController _note = TextEditingController(
    text: widget.controller.entryFor(widget.dateKey)?.note ?? '',
  );
  late PhotoCategory? _category = widget.controller
      .entryFor(widget.dateKey)
      ?.category;
  bool _saved = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _changed {
    final entry = widget.controller.entryFor(widget.dateKey);
    return _note.text.trim() != (entry?.note ?? '') ||
        _category != entry?.category;
  }

  /// Saves the note if it changed; closing the card saves too.
  Future<void> _save() async {
    if (_saved || !_changed) return;
    _saved = true;
    try {
      await widget.controller.updateDetails(
        widget.dateKey,
        note: _note.text,
        category: _category,
      );
    } on Exception catch (e) {
      _saved = false;
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _saveAndClose() async {
    final navigator = Navigator.of(context);
    await _save();
    if (mounted) navigator.pop();
  }

  void _openFull() {
    _save();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DayDetailScreen(
          controller: widget.controller,
          dateKey: widget.dateKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.controller.entryFor(widget.dateKey);
    final p = context.palette;
    final s = context.strings;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: GestureDetector(
        // Taps on the dimmed area close the card; taps on it do not.
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: SafeArea(
          child: AnimatedPadding(
            duration: AppMotion.short,
            padding: EdgeInsets.only(bottom: insets),
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
                      borderRadius: BorderRadius.circular(
                        AppDimens.dialogRadius,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (entry != null) _photo(entry),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Text(
                              formatLongDate(widget.dateKey, strings: s),
                              style: AppText.headline.copyWith(
                                color: p.onSurface,
                              ),
                            ),
                          ),
                          // Edge to edge so the chips scroll under the card
                          // padding.
                          CategoryPicker(
                            selected: _category,
                            onChanged: (c) => setState(() => _category = c),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _NoteField(controller: _note),
                                const SizedBox(height: 14),
                                _actions(entry, s),
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
        ),
      ),
    );
  }

  Widget _actions(Entry? entry, Strings s) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('open-full'),
              onPressed: entry == null ? null : _openFull,
              icon: const Icon(Icons.open_in_full_rounded, size: 18),
              label: Text(s.fullScreen, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PressScale(
          child: FilledButton(
            key: const ValueKey('save-note'),
            onPressed: _saveAndClose,
            child: Text(s.save),
          ),
        ),
      ],
    );
  }

  Widget _photo(Entry entry) {
    final file = widget.controller.fileFor(entry);
    final p = context.palette;
    final broken = ColoredBox(
      color: p.surface,
      child: Center(
        child: Icon(Icons.broken_image, size: 48, color: p.dayMuted),
      ),
    );
    // While typing, the photo shrinks so the note and buttons stay visible.
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedContainer(
        key: const ValueKey('preview-photo'),
        duration: AppMotion.medium,
        curve: AppMotion.curve,
        height: typing ? 120 : constraints.maxWidth,
        child: GestureDetector(
          onTap: _openFull,
          child: file.existsSync()
              ? Hero(
                  tag: photoHeroTag(widget.dateKey),
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
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.strings;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      borderSide: BorderSide.none,
    );
    return TextField(
      key: const ValueKey('note-field'),
      controller: controller,
      minLines: 3,
      maxLines: 6,
      maxLength: Entry.maxNoteLength,
      textCapitalization: TextCapitalization.sentences,
      style: AppText.body.copyWith(color: p.onSurface, height: 1.4),
      decoration: InputDecoration(
        labelText: s.noteLabel,
        hintText: s.noteHint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: p.surface,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
        counterStyle: TextStyle(color: p.dayMuted, fontSize: 12),
      ),
    );
  }
}
