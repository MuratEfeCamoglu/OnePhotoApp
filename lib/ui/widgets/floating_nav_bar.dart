import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'l10n.dart';
import 'motion.dart';

/// Tabs of the home screen reachable from the bottom bar.
enum HomeTab { timeline, gallery }

/// Floating pill at the bottom: home, today's camera, gallery
/// (ISKELET F1g, F13). Settings live in the top-right corner instead.
class FloatingNavBar extends StatelessWidget {
  /// Creates the bar; a `null` callback disables its button.
  const FloatingNavBar({
    super.key,
    required this.selected,
    required this.onHome,
    required this.onGallery,
    required this.onCamera,
  });

  /// Highlighted tab.
  final HomeTab selected;

  /// Shows the timeline, or scrolls it back to the current month.
  final VoidCallback? onHome;

  /// Shows the photo gallery.
  final VoidCallback? onGallery;

  /// Takes today's photo.
  final VoidCallback? onCamera;

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
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // No BackdropFilter: re-blurring the scrolling grid every frame
            // made mid-range GPUs drop frames; a near-opaque fill looks the
            // same.
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
                    selected: selected == HomeTab.timeline,
                    onTap: onHome,
                  ),
                  const SizedBox(width: 10),
                  _CameraButton(tooltip: s.cameraTooltip, onTap: onCamera),
                  const SizedBox(width: 10),
                  _NavButton(
                    key: const ValueKey('gallery-button'),
                    icon: Icons.photo_library_rounded,
                    tooltip: s.galleryTitle,
                    selected: selected == HomeTab.gallery,
                    onTap: onGallery,
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
      child: Semantics(
        selected: selected,
        button: true,
        child: PressScale(
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.curve,
            decoration: BoxDecoration(
              color: selected ? p.surface : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox.square(
                  dimension: 52,
                  child: AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: AppMotion.medium,
                    curve: Curves.easeOutBack,
                    child: Icon(
                      icon,
                      size: 26,
                      color: selected ? p.onSurface : p.dayMuted,
                    ),
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

/// Round settings button for the top-right corner of the home tabs.
class SettingsButton extends StatelessWidget {
  /// Creates the button; [onPressed] opens the settings screen.
  const SettingsButton({super.key, required this.onPressed});

  /// Opens the settings screen.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: context.strings.settingsTooltip,
      child: PressScale(
        child: Material(
          color: p.surface,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('settings-button'),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 44,
              child: Icon(Icons.settings_rounded, size: 24, color: p.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
