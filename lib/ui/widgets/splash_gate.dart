import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'l10n.dart';

/// Shows the branded intro over [child] on a cold start, then reveals it.
///
/// It continues the native splash (same colour and grid, see
/// `launch_background.xml`). [child] is built and laid out under the intro
/// from the first frame but not painted, so its heavy first build happens
/// while the native splash is still up and the animation itself only
/// scales a few shapes: nothing new is built while it runs.
class SplashGate extends StatefulWidget {
  /// Wraps [child]; [enabled] false shows it immediately.
  const SplashGate({
    super.key,
    required this.child,
    this.enabled = true,
    this.waitFor,
  });

  /// Screen revealed after the intro.
  final Widget child;

  /// Plays the intro when true.
  final bool enabled;

  /// Work (e.g. loading entries) to finish before the animation starts;
  /// the intro stays on the static splash picture meanwhile.
  final Future<void>? waitFor;

  /// Native splash colour (`@color/splash_background`).
  static const background = Color(0xFFC2410C);

  /// Total intro length.
  static const duration = Duration(milliseconds: 950);

  /// Side of the grid: the 288dp splash icon box × the icon's 0.44 motif.
  static const gridSize = 288 * 0.44;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashGate.duration,
  );
  bool _done = false;

  // From this point the overlay fades out and the screen below shows.
  static const _revealAt = 0.55;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _done = true;
      return;
    }
    _controller.addListener(_onTick);
    _start();
  }

  // Waits for [SplashGate.waitFor], then lets the child build and paint
  // once behind the opaque intro (warming images and glyphs), and only then
  // starts animating. Every heavy frame thus lands on the static picture.
  Future<void> _start() async {
    try {
      await widget.waitFor;
    } on Object {
      // Errors are reported by whoever owns the work; the intro must go on.
    }
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _finish();
      return;
    }
    setState(() => _started = true);
    await _controller.forward();
    _finish();
  }

  bool _started = false;

  bool _revealed = false;

  void _onTick() {
    final reveal = _controller.value >= _revealAt;
    if (reveal != _revealed) setState(() => _revealed = reveal);
  }

  void _finish() {
    if (mounted && !_done) setState(() => _done = true);
  }

  /// Tapping skips straight to the reveal.
  void _skip() {
    if (_controller.value < _revealAt) _controller.value = _revealAt;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The child keeps the same place in the tree before and after the
    // intro, so it is built exactly once.
    return Stack(
      fit: StackFit.expand,
      children: [
        // Painted once behind the opaque intro while waiting (warm-up), then
        // skipped while the animation runs: repainting the whole timeline
        // under the intro every frame costs too much on a freshly installed
        // app. Shown again from the reveal on.
        Offstage(
          offstage: _started && !_done && !_revealed,
          child: widget.child,
        ),
        if (!_done)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _skip,
            // Without a Material ancestor Text falls back to the yellow,
            // double-underlined "missing Material" style.
            child: Material(
              type: MaterialType.transparency,
              child: _Intro(animation: _controller, revealAt: _revealAt),
            ),
          ),
      ],
    );
  }
}

class _Intro extends AnimatedWidget {
  const _Intro({required Animation<double> animation, required this.revealAt})
    : super(listenable: animation);

  final double revealAt;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    final out = ((t - revealAt) / (1 - revealAt)).clamp(0.0, 1.0);
    final fade = Curves.easeIn.transform(out);
    final title = Curves.easeOutCubic.transform(
      ((t - 0.2) / 0.35).clamp(0.0, 1.0),
    );
    final alpha = 1 - fade;
    // Alpha is applied to the colours, not via Opacity, so fading the
    // full-screen intro never allocates an offscreen layer.
    return ColoredBox(
      color: SplashGate.background.withValues(alpha: alpha),
      child: Stack(
        children: [
          Center(
            child: Transform.scale(
              scale: 1 + 0.35 * Curves.easeInCubic.transform(out),
              child: CustomPaint(
                size: const Size.square(SplashGate.gridSize),
                painter: _GridPainter(t, alpha),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.32),
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - title)),
              child: Text(
                context.strings.appTitle,
                style: AppText.appTitle.copyWith(
                  color: Colors.white.withValues(alpha: title * alpha),
                  fontSize: 34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The launcher icon's 3×3 calendar grid, with a diagonal ripple.
class _GridPainter extends CustomPainter {
  _GridPainter(this.t, this.alpha);

  final double t;
  final double alpha;

  static const _accent = Color(0xFFC2410C);
  static const _accentDark = Color(0xFF9A3412);

  @override
  void paint(Canvas canvas, Size size) {
    final box = size.width;
    final gap = box * 0.07;
    final cell = (box - 2 * gap) / 3;
    final radius = Radius.circular(cell * 0.22);
    final dim = Paint()..color = Colors.white.withValues(alpha: 0.28 * alpha);
    final white = Paint()..color = Colors.white.withValues(alpha: alpha);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        // Each cell bumps once, top-left to bottom-right.
        final start = 0.05 * (row + col);
        final p = ((t - start) / 0.3).clamp(0.0, 1.0);
        final bump =
            1 + 0.14 * Curves.easeInOut.transform(1 - (2 * p - 1).abs());
        final center = Offset(
          col * (cell + gap) + cell / 2,
          row * (cell + gap) + cell / 2,
        );
        final rect = Rect.fromCenter(
          center: center,
          width: cell * bump,
          height: cell * bump,
        );
        final isToday = row == 1 && col == 1;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius * bump),
          isToday ? white : dim,
        );
        if (isToday) _photo(canvas, rect);
      }
    }
  }

  // Sun and mountains, as in the launcher icon.
  void _photo(Canvas canvas, Rect r) {
    final s = r.width;
    canvas.drawCircle(
      Offset(r.left + s * 0.68, r.top + s * 0.32),
      s * 0.11,
      Paint()..color = _accent.withValues(alpha: alpha),
    );
    final base = r.top + s * 0.80;
    canvas.drawPath(
      Path()
        ..moveTo(r.left + s * 0.14, base)
        ..lineTo(r.left + s * 0.40, r.top + s * 0.40)
        ..lineTo(r.left + s * 0.66, base)
        ..close(),
      Paint()..color = _accent.withValues(alpha: alpha),
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.left + s * 0.46, base)
        ..lineTo(r.left + s * 0.66, r.top + s * 0.54)
        ..lineTo(r.left + s * 0.86, base)
        ..close(),
      Paint()..color = _accentDark.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.t != t || old.alpha != alpha;
}
