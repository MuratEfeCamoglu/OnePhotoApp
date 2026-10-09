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
        titleSpacing: AppDimens.gutter,
        title: const Text(Strings.appTitle, style: AppText.appTitle),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => IconButton(
              key: const ValueKey('camera-button'),
              tooltip: Strings.cameraTooltip,
              icon: const Icon(Icons.photo_camera),
              onPressed: _controller.isLoading ? null : _onCameraPressed,
            ),
          ),
          IconButton(
            key: const ValueKey('settings-button'),
            tooltip: Strings.settingsTooltip,
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
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
            padding: EdgeInsets.only(
              bottom: 24 + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: months.length + offset,
            itemBuilder: (context, index) {
              if (index < offset) {
                return _EmptyCard(
                  onTap: _controller.isLoading ? null : _onCameraPressed,
                );
              }
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
  Size get preferredSize => const Size.fromHeight(29);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 29,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          for (final (i, name) in Strings.weekdaysShort.indexed) ...[
            if (i > 0) const SizedBox(width: AppDimens.cellGap),
            Expanded(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: AppText.weekday,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dashed "add your first photo" card shown while there are no entries.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimens.cardRadius);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gutter,
        AppDimens.gutter,
        0,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: CustomPaint(
            painter: const _DashedBorderPainter(),
            child: const SizedBox(
              height: 120,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    child: Icon(Icons.photo_camera, size: 24),
                  ),
                  SizedBox(height: 12),
                  Text(
                    Strings.emptyTimeline,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1.5px dashed rounded border; Flutter has no dashed BoxBorder.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.75);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(AppDimens.cardRadius),
        ),
      );
    final paint = Paint()
      ..color = AppColors.handle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
