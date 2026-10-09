import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/photo_picker.dart';
import '../../state/timeline_controller.dart';
import '../day_detail/day_preview.dart';
import '../widgets/add_photo_flow.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/l10n.dart';
import '../widgets/motion.dart';
import 'gallery_view.dart';
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

  /// Builds the settings screen opened from the bottom bar.
  final WidgetBuilder settingsBuilder;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _scroll = ScrollController();
  final _galleryScroll = ScrollController();
  HomeTab _tab = HomeTab.timeline;

  // Months animate in only on the first screenful; months scrolled in later
  // appear directly so fast scrolling never stacks opacity layers.
  bool _introDone = false;

  TimelineController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_showPendingError);
  }

  @override
  void dispose() {
    _controller.removeListener(_showPendingError);
    _scroll.dispose();
    _galleryScroll.dispose();
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

  void _scrollToTop(ScrollController scroll) {
    if (!scroll.hasClients) return;
    scroll.animateTo(0, duration: AppMotion.long, curve: AppMotion.curve);
  }

  /// Switches to [tab]; tapping the current tab scrolls it to the top.
  void _selectTab(HomeTab tab) {
    if (tab == _tab) {
      _scrollToTop(tab == HomeTab.timeline ? _scroll : _galleryScroll);
      return;
    }
    setState(() => _tab = tab);
  }

  // The camera button is always for today (ISKELET F3c).
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
    showDayPreview(context, _controller, dateKey);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      extendBody: true,
      // Both tabs stay alive so the timeline keeps its scroll position.
      body: _TabSwitcher(
        index: _tab.index,
        children: [
          _timeline(p),
          GalleryView(
            controller: _controller,
            scroll: _galleryScroll,
            onSettings: _openSettings,
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => FloatingNavBar(
          selected: _tab,
          onHome: () => _selectTab(HomeTab.timeline),
          onGallery: () => _selectTab(HomeTab.gallery),
          onCamera: _controller.isLoading ? null : _onCameraPressed,
        ),
      ),
    );
  }

  Widget _timeline(AppPalette p) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final slivers = <Widget>[
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              topPadding: MediaQuery.paddingOf(context).top,
              title: context.strings.appTitle,
              subtitle: context.strings.appSubtitle,
              weekdays: context.strings.weekdaysShort,
              palette: p,
              onSettings: _openSettings,
            ),
          ),
        ];
        if (_controller.isLoading) {
          slivers.add(
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        } else {
          final months = _controller.months;
          final today = _controller.todayKey;
          final offset = _controller.isEmpty ? 1 : 0;
          // Lazily built: only months near the viewport exist (ISKELET §5).
          slivers.add(
            SliverList.builder(
              itemCount: months.length + offset,
              itemBuilder: (context, index) {
                if (!_introDone) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _introDone = true,
                  );
                }
                final animate = !_introDone;
                final delay = Duration(milliseconds: 70 * math.min(index, 4));
                if (index < offset) {
                  return EntranceAnimation(
                    enabled: animate,
                    child: _EmptyCard(onTap: _onCameraPressed),
                  );
                }
                final month = months[index - offset];
                return EntranceAnimation(
                  key: ValueKey(month),
                  enabled: animate,
                  delay: delay,
                  child: MonthGrid(
                    month: month,
                    todayKey: today,
                    photoFor: (key) {
                      final entry = _controller.entryFor(key);
                      return entry == null ? null : _controller.fileFor(entry);
                    },
                    hasNote: (key) =>
                        _controller.entryFor(key)?.hasNote ?? false,
                    categoryFor: (key) => _controller.entryFor(key)?.category,
                    missingFor: (key) {
                      final entry = _controller.entryFor(key);
                      return entry != null && !_controller.fileExists(entry);
                    },
                    onDayTap: _onDayTap,
                  ),
                );
              },
            ),
          );
        }
        slivers.add(
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  AppDimens.navBarClearance +
                  MediaQuery.paddingOf(context).bottom,
            ),
          ),
        );
        return CustomScrollView(controller: _scroll, slivers: slivers);
      },
    );
  }
}

/// Cross-fades between tabs while keeping every tab's state.
///
/// Only the current tab, and the previous one while it fades out, are
/// onstage; the rest is offstage so it neither paints nor ticks.
class _TabSwitcher extends StatefulWidget {
  const _TabSwitcher({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_TabSwitcher> createState() => _TabSwitcherState();
}

class _TabSwitcherState extends State<_TabSwitcher> {
  int? _leaving;

  @override
  void didUpdateWidget(_TabSwitcher old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _leaving = old.index;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (i, child) in widget.children.indexed)
          Offstage(
            offstage: i != widget.index && i != _leaving,
            child: TickerMode(
              enabled: i == widget.index || i == _leaving,
              child: IgnorePointer(
                ignoring: i != widget.index,
                child: AnimatedOpacity(
                  opacity: i == widget.index ? 1 : 0,
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  onEnd: () {
                    if (i == _leaving && mounted) {
                      setState(() => _leaving = null);
                    }
                  },
                  child: child,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Large title that shrinks on scroll, with the pinned weekday row.
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.topPadding,
    required this.title,
    required this.subtitle,
    required this.weekdays,
    required this.palette,
    required this.onSettings,
  });

  final double topPadding;
  final String title;
  final String subtitle;
  final List<String> weekdays;
  final AppPalette palette;
  final VoidCallback onSettings;

  static const _weekdayHeight = 29.0;
  static const _collapsed = 56.0;
  static const _expanded = 104.0;

  @override
  double get minExtent => topPadding + _collapsed + _weekdayHeight;

  @override
  double get maxExtent => topPadding + _expanded + _weekdayHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final t = (shrinkOffset / (_expanded - _collapsed)).clamp(0.0, 1.0);
    return Material(
      color: palette.background,
      elevation: overlaps ? 0.5 : 0,
      shadowColor: Colors.black26,
      child: Stack(
        children: [
          Positioned.fill(child: _content(t)),
          Positioned(
            top: topPadding + 6,
            right: 12,
            child: SettingsButton(onPressed: onSettings),
          ),
        ],
      ),
    );
  }

  Widget _content(double t) {
    final titleSize = 32 - 10 * t;
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.appTitle.copyWith(
                      fontSize: titleSize,
                      color: palette.onSurface,
                    ),
                  ),
                  // Subtitle fades and folds away as the title shrinks.
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topLeft,
                      heightFactor: 1 - t,
                      child: Opacity(
                        opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.dayMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10 - 4 * t),
                ],
              ),
            ),
          ),
          Container(
            height: _weekdayHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.outline)),
            ),
            child: Row(
              children: [
                for (final (i, name) in weekdays.indexed) ...[
                  if (i > 0) const SizedBox(width: AppDimens.cellGap),
                  Expanded(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: AppText.weekday.copyWith(
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) =>
      old.topPadding != topPadding ||
      old.title != title ||
      old.subtitle != subtitle ||
      old.palette != palette;
}

/// Dashed "add your first photo" card shown while there are no entries.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppDimens.cardRadius);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gutter,
        AppDimens.gutter,
        0,
      ),
      child: PressScale(
        scale: 0.97,
        child: Material(
          color: p.surface,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: CustomPaint(
              painter: _DashedBorderPainter(p.handle),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: p.accent,
                      foregroundColor: p.onAccent,
                      child: const Icon(Icons.photo_camera, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.strings.emptyTimeline,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: p.onSurface,
                      ),
                    ),
                  ],
                ),
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
  const _DashedBorderPainter(this.color);

  final Color color;

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
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
