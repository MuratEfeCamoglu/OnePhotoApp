import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/categories.dart';
import '../../core/theme.dart';
import '../widgets/category_style.dart';
import '../widgets/motion.dart';

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
    this.hasNote = false,
    this.category,
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

  /// Shows a small note badge on the photo (ISKELET F11).
  final bool hasNote;

  /// Category badge shown on the photo (ISKELET F12).
  final PhotoCategory? category;

  /// Called on tap; ignored for future days.
  final VoidCallback? onTap;

  /// Whether the entry's file is gone from disk (ISKELET F6e).
  bool get isMissing => photo != null && !photo!.existsSync();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppDimens.cellRadius);
    final missing = isMissing;
    final Widget content;
    if (photo != null && !missing) {
      content = _PhotoContent(
        key: ValueKey(photo!.path),
        file: photo!,
        day: day,
        bold: isToday,
        heroTag: heroTag,
        hasNote: hasNote,
        category: category,
      );
    } else if (missing) {
      content = _MissingContent(key: const ValueKey('missing'), day: day);
    } else {
      content = Center(
        key: const ValueKey('empty'),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? p.accent : p.dayMuted,
          ),
        ),
      );
    }

    Widget cell = Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        hoverColor: p.surface,
        onTap: isFuture ? null : onTap,
        child: ClipRRect(
          borderRadius: radius,
          // A new or replaced photo pops in instead of just appearing.
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.8, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, ?current]),
            child: content,
          ),
        ),
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
                  border: Border.all(color: p.accent, width: 2),
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
      child: PressScale(enabled: !isFuture, child: cell),
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
    super.key,
    required this.file,
    required this.day,
    required this.bold,
    this.heroTag,
    this.hasNote = false,
    this.category,
  });

  final File file;
  final int day;
  final bool bold;
  final String? heroTag;
  final bool hasNote;
  final PhotoCategory? category;

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
      color: context.palette.surface,
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
          if (category != null)
            Positioned(
              top: 3,
              left: 3,
              child: CategoryBadge(
                key: const ValueKey('category-badge'),
                category: category!,
                size: 14,
              ),
            ),
          if (hasNote)
            const Positioned(
              top: 3,
              right: 3,
              child: Icon(
                Icons.sticky_note_2_rounded,
                key: ValueKey('note-badge'),
                size: 12,
                color: Colors.white,
                shadows: [Shadow(color: Color(0x99000000), blurRadius: 3)],
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
  const _MissingContent({super.key, required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(0, -0.35),
            child: Icon(Icons.broken_image, size: 18, color: p.dayMuted),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 3,
            child: Text(
              '$day',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: p.dayMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
