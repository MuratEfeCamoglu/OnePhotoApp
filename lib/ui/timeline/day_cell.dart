import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Hero tag shared by a day's grid thumbnail and its detail photo.
String photoHeroTag(String dateKey) => 'photo-$dateKey';

/// One day square of the month grid (ISKELET F1e).
class DayCell extends StatelessWidget {
  /// Creates a cell; [photo] is `null` for a day without an entry.
  const DayCell({
    super.key,
    required this.day,
    required this.label,
    required this.isToday,
    required this.isFuture,
    this.photo,
    this.heroTag,
    this.onTap,
  });

  /// Day of month shown on the cell.
  final int day;

  /// Accessible description such as "9 Ekim 2026".
  final String label;

  /// Draws the accent ring.
  final bool isToday;

  /// Future days are dimmed and cannot be tapped.
  final bool isFuture;

  /// The day's photo file, if the day has an entry.
  final File? photo;

  /// Hero tag linking the thumbnail to the detail screen.
  final String? heroTag;

  /// Called on tap; ignored for future days.
  final VoidCallback? onTap;

  /// Whether the entry's file is gone from disk (ISKELET F6e).
  bool get isMissing => photo != null && !photo!.existsSync();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimens.cellRadius);
    final missing = isMissing;
    final Widget content;
    if (photo != null && !missing) {
      content = _PhotoContent(
        file: photo!,
        day: day,
        bold: isToday,
        heroTag: heroTag,
      );
    } else if (missing) {
      content = _MissingContent(day: day);
    } else {
      content = Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? AppColors.accent : AppColors.dayMuted,
          ),
        ),
      );
    }

    Widget cell = Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        hoverColor: AppColors.surface,
        onTap: isFuture ? null : onTap,
        child: ClipRRect(borderRadius: radius, child: content),
      ),
    );
    if (isToday) {
      // The mockup draws today's ring 1px outside the cell (outline-offset).
      cell = Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          cell,
          Positioned(
            left: -3,
            top: -3,
            right: -3,
            bottom: -3,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('today-ring'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.cellRadius + 3),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
              ),
            ),
          ),
        ],
      );
    }
    cell = Semantics(
      label: label,
      button: !isFuture,
      selected: isToday,
      child: cell,
    );
    if (isFuture) {
      cell = IgnorePointer(
        child: Opacity(opacity: AppDimens.futureOpacity, child: cell),
      );
    }
    return cell;
  }
}

class _PhotoContent extends StatelessWidget {
  const _PhotoContent({
    required this.file,
    required this.day,
    required this.bold,
    this.heroTag,
  });

  final File file;
  final int day;
  final bool bold;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    // Grid thumbnails decode small; full size only in the detail view.
    Widget image = Image.file(
      file,
      cacheWidth: 200,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stack) => _MissingContent(day: day),
    );
    if (heroTag != null) image = Hero(tag: heroTag!, child: image);
    return ColoredBox(
      color: AppColors.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0, 0.7],
                colors: [AppColors.photoScrim, Color(0x00000000)],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 3,
            child: Text(
              '$day',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Color(0x80000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingContent extends StatelessWidget {
  const _MissingContent({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Align(
            alignment: Alignment(0, -0.35),
            child: Icon(
              Icons.broken_image,
              size: 18,
              color: AppColors.dayMuted,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 3,
            child: Text(
              '$day',
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
