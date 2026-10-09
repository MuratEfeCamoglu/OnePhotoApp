import 'package:flutter/material.dart';

import '../../core/date_key.dart';
import '../../core/strings.dart';
import '../../data/entry.dart';
import '../../services/photo_picker.dart';
import '../../state/timeline_controller.dart';
import 'error_snackbar.dart';
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
      content: Text(question, style: const TextStyle(fontSize: 18)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(Strings.cancel),
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
/// expected errors into SnackBars (F8). Returns the saved entry or `null`.
Future<Entry?> addPhotoFlow(
  BuildContext context,
  TimelineController controller,
  String dateKey,
  PhotoSource source,
) async {
  if (controller.entryFor(dateKey) != null) {
    final replace = await confirmAction(
      context,
      question: Strings.replaceQuestion,
      confirmLabel: Strings.replace,
    );
    if (!replace || !context.mounted) return null;
  }
  try {
    return await controller.addPhoto(dateKey, source);
  } on Exception catch (e) {
    if (context.mounted) showErrorSnackBar(context, e);
    return null;
  }
}

/// Opens the source sheet for [dateKey], then runs [addPhotoFlow].
Future<Entry?> chooseSourceAndAdd(
  BuildContext context,
  TimelineController controller,
  String dateKey,
) async {
  final source = await showPhotoSourceSheet(
    context,
    title: formatShortDate(dateKey),
  );
  if (source == null || !context.mounted) return null;
  return addPhotoFlow(context, controller, dateKey, source);
}
