import 'package:flutter/material.dart';

import '../../core/categories.dart';
import '../../core/date_key.dart';
import '../../core/theme.dart';
import '../../data/entry.dart';
import '../../state/timeline_controller.dart';
import '../widgets/category_style.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/l10n.dart';
import '../widgets/motion.dart';

/// Opens the bottom sheet that edits [dateKey]'s category and note
/// (ISKELET F11, F12). Used after adding a photo and from the full screen.
Future<void> showDetailsEditor(
  BuildContext context,
  TimelineController controller,
  String dateKey,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DetailsEditor(controller: controller, dateKey: dateKey),
  );
}

/// Category chips and note field for one day; saves on "Kaydet" or close.
class DetailsEditor extends StatefulWidget {
  /// Creates the editor of [dateKey].
  const DetailsEditor({
    super.key,
    required this.controller,
    required this.dateKey,
  });

  /// Source of the entry and saving.
  final TimelineController controller;

  /// Day being edited.
  final String dateKey;

  @override
  State<DetailsEditor> createState() => _DetailsEditorState();
}

class _DetailsEditorState extends State<DetailsEditor> {
  late final Entry? _initial = widget.controller.entryFor(widget.dateKey);
  late final TextEditingController _note = TextEditingController(
    text: _initial?.note ?? '',
  );
  late PhotoCategory? _category = _initial?.category;
  bool _saved = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _changed =>
      _note.text.trim() != (_initial?.note ?? '') ||
      _category != _initial?.category;

  /// Saves if anything changed; closing the sheet saves too.
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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.strings;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12, bottom: 16),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  formatLongDate(widget.dateKey, strings: s),
                  style: AppText.headline.copyWith(color: p.onSurface),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  s.categoryLabel,
                  style: AppText.section.copyWith(color: p.dayMuted),
                ),
              ),
              CategoryPicker(
                selected: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: NoteField(controller: _note),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: PressScale(
                  child: FilledButton(
                    key: const ValueKey('save-note'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _saveAndClose,
                    child: Text(s.save),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Multi-line note input limited to [Entry.maxNoteLength] characters.
class NoteField extends StatelessWidget {
  /// Creates the field bound to [controller].
  const NoteField({super.key, required this.controller});

  /// Text being edited.
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
