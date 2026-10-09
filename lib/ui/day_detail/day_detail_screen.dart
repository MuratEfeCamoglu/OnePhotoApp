import 'package:flutter/material.dart';

import '../../core/date_key.dart';
import '../../core/strings.dart';
import '../../state/timeline_controller.dart';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(formatLongDate(dateKey)),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final entry = controller.entryFor(dateKey);
          if (entry == null) return const SizedBox.expand();
          final file = controller.fileFor(entry);
          const broken = Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Colors.white54,
            ),
          );
          if (!file.existsSync()) return broken;
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: SizedBox.expand(
              // Full-size decode only here; the grid uses thumbnails.
              child: Image.file(
                file,
                key: ValueKey(entry.fileName),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => broken,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () =>
                      chooseSourceAndAdd(context, controller, dateKey),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text(Strings.replace),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFB4AB),
                  ),
                  onPressed: () => _delete(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(Strings.delete),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
