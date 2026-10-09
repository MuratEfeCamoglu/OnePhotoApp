import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Shrinks its child slightly while pressed, for tactile feedback.
class PressScale extends StatefulWidget {
  /// Wraps [child]; [scale] is the pressed size.
  const PressScale({
    super.key,
    required this.child,
    this.scale = 0.94,
    this.enabled = true,
  });

  /// Pressable content.
  final Widget child;

  /// Size factor while pressed.
  final double scale;

  /// No feedback when false (e.g. future days).
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (widget.enabled && down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: AppMotion.short,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}

/// Fades and slides its child up once when first shown.
///
/// [delay] staggers siblings without timers, so tests can settle.
class EntranceAnimation extends StatefulWidget {
  /// Animates [child] in after [delay].
  const EntranceAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 24,
    this.enabled = true,
  });

  /// Content to reveal.
  final Widget child;

  /// Wait before this child starts moving.
  final Duration delay;

  /// Starting vertical offset in logical pixels.
  final double offset;

  /// Shows [child] immediately when false (e.g. items scrolled in later).
  final bool enabled;

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + AppMotion.long;
    _controller = AnimationController(
      vsync: this,
      duration: total,
      value: widget.enabled ? 0 : 1,
    );
    final start = widget.delay.inMicroseconds / total.inMicroseconds;
    _t = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: AppMotion.curve),
    );
    if (widget.enabled) {
      _controller.forward().whenComplete(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Finished animations add no layers, so scrolling stays cheap.
    if (_controller.isCompleted) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
