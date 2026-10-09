import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'l10n.dart';
import 'motion.dart';

/// Frosted pill at the bottom: home, today's camera, settings (ISKELET F1g).
class FloatingNavBar extends StatelessWidget {
  /// Creates the bar; a `null` callback disables its button.
  const FloatingNavBar({
    super.key,
    required this.onHome,
    required this.onCamera,
    required this.onSettings,
  });

  /// Scrolls the timeline back to the current month.
  final VoidCallback? onHome;

  /// Takes today's photo.
  final VoidCallback? onCamera;

  /// Opens the settings screen.
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.strings;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Center(
        heightFactor: 1,
        child: EntranceAnimation(
          offset: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: p.navBar,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: p.outline, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NavButton(
                        key: const ValueKey('home-button'),
                        icon: Icons.home_rounded,
                        tooltip: s.homeTooltip,
                        selected: true,
                        onTap: onHome,
                      ),
                      const SizedBox(width: 10),
                      _CameraButton(tooltip: s.cameraTooltip, onTap: onCamera),
                      const SizedBox(width: 10),
                      _NavButton(
                        key: const ValueKey('settings-button'),
                        icon: Icons.settings_rounded,
                        tooltip: s.settingsTooltip,
                        onTap: onSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: PressScale(
        child: Material(
          color: selected ? p.surface : Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: 52,
              child: Icon(
                icon,
                size: 26,
                color: selected ? p.onSurface : p.dayMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: PressScale(
        scale: 0.9,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.5 : 1,
          duration: AppMotion.short,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(p.accent, Colors.white, 0.12)!, p.accent],
              ),
              boxShadow: [
                BoxShadow(
                  color: p.accent.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('camera-button'),
                onTap: onTap,
                child: SizedBox.square(
                  dimension: 60,
                  child: Icon(Icons.photo_camera, size: 28, color: p.onAccent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
