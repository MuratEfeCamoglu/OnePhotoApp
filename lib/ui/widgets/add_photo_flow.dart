import 'package:flutter/material.dart';

import '../../core/date_key.dart';
import '../../core/theme.dart';
import '../../data/entry.dart';
import '../../services/photo_picker.dart';
import '../../state/timeline_controller.dart';
import '../day_detail/details_editor.dart';
import 'error_snackbar.dart';
import 'l10n.dart';
import 'photo_source_sheet.dart';

/// Shows a yes/no dialog; resolves to `true` only on the confirm button.
Future<bool> confirmAction(
  BuildContext context, {
  required String question,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        question,
        style: AppText.headline.copyWith(color: context.palette.onSurface),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Adds a photo from [source] to [dateKey].
///
/// Asks before replacing an existing photo (ISKELET F4b) and turns
/// expected errors into SnackBars (F8). With [showDetails] the details
/// editor opens afterwards to pick a category and write a note (F11, F12).
/// Returns the saved entry or `null`.
Future<Entry?> addPhotoFlow(
  BuildContext context,
  TimelineController controller,
  String dateKey,
  PhotoSource source, {
  bool showDetails = true,
}) async {
  if (controller.entryFor(dateKey) != null) {
    final replace = await confirmAction(
      context,
      question: context.strings.replaceQuestion,
      confirmLabel: context.strings.replace,
    );
    if (!replace || !context.mounted) return null;
  }
  final Entry? entry;
  try {
    entry = await controller.addPhoto(dateKey, source);
  } on Exception catch (e) {
    if (context.mounted) showErrorSnackBar(context, e);
    return null;
  }
  if (entry != null && showDetails && context.mounted) {
    await showDetailsEditor(context, controller, dateKey);
  }
  return entry;
}

/// Opens the source sheet for [dateKey], then runs [addPhotoFlow].
Future<Entry?> chooseSourceAndAdd(
  BuildContext context,
  TimelineController controller,
  String dateKey, {
  bool showDetails = true,
}) async {
  final source = await showPhotoSourceSheet(
    context,
    title: formatShortDate(dateKey, strings: context.strings),
  );
  if (source == null || !context.mounted) return null;
  return addPhotoFlow(
    context,
    controller,
    dateKey,
    source,
    showDetails: showDetails,
  );
}
