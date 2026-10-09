import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../services/photo_picker.dart';
import '../../state/timeline_controller.dart';
import '../day_detail/day_detail_screen.dart';
import '../widgets/add_photo_flow.dart';
import '../widgets/error_snackbar.dart';
import 'month_grid.dart';

/// Home screen: months newest first with day photos (ISKELET F1).
class TimelineScreen extends StatefulWidget {
  /// Creates the timeline; [settingsBuilder] builds the settings route.
  const TimelineScreen({
    super.key,
    required this.controller,
    required this.settingsBuilder,
  });

  /// Source of entries and actions.
  final TimelineController controller;

  /// Builds the settings screen opened from the app bar.
  final WidgetBuilder settingsBuilder;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  TimelineController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_showPendingError);
  }

  @override
  void dispose() {
    _controller.removeListener(_showPendingError);
    super.dispose();
  }

  void _showPendingError() {
    final error = _controller.takePendingError();
    if (error != null && mounted) showErrorSnackBar(context, error);
  }

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: widget.settingsBuilder));
  }

  // The camera icon is always for today (ISKELET F3c).
  void _onCameraPressed() {
    addPhotoFlow(
      context,
      _controller,
      _controller.todayKey,
      PhotoSource.camera,
    );
  }

  void _onDayTap(String dateKey) {
    if (_controller.entryFor(dateKey) == null) {
      chooseSourceAndAdd(context, _controller, dateKey);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DayDetailScreen(controller: _controller, dateKey: dateKey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.appTitle,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => IconButton(
              key: const ValueKey('camera-button'),
              tooltip: Strings.cameraTooltip,
              icon: const Icon(Icons.photo_camera_outlined),
              onPressed: _controller.isLoading ? null : _onCameraPressed,
            ),
          ),
          IconButton(
            key: const ValueKey('settings-button'),
            tooltip: Strings.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
        bottom: const _WeekdayHeader(),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final months = _controller.months;
          final today = _controller.todayKey;
          final offset = _controller.isEmpty ? 1 : 0;
          // Lazily built: only months near the viewport exist (ISKELET §5).
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: months.length + offset,
            itemBuilder: (context, index) {
              if (index < offset) return const _EmptyState();
              return MonthGrid(
                month: months[index - offset],
                todayKey: today,
                photoFor: (key) {
                  final entry = _controller.entryFor(key);
                  return entry == null ? null : _controller.fileFor(entry);
                },
                onDayTap: _onDayTap,
              );
            },
          );
        },
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget implements PreferredSizeWidget {
  const _WeekdayHeader();

  @override
  Size get preferredSize => const Size.fromHeight(28);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      child: Row(
        children: [
          for (final name in Strings.weekdaysShort)
            Expanded(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dayMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(AppDimens.gutter, 24, AppDimens.gutter, 0),
      child: Column(
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 40,
            color: AppColors.dayMuted,
          ),
          SizedBox(height: 8),
          Text(
            Strings.emptyTimeline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
