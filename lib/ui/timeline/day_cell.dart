import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

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
    this.onTap,
  });

  /// Day of month shown on the cell.
  final int day;

  /// Accessible description such as "9 Ekim 2026".
  final String label;

  /// Draws the accent frame.
  final bool isToday;

  /// Future days are dimmed and cannot be tapped.
  final bool isFuture;

  /// The day's photo file, if the day has an entry.
  final File? photo;

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
      content = _PhotoContent(file: photo!, day: day);
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

    Widget cell = Semantics(
      label: label,
      button: !isFuture,
      selected: isToday,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: isFuture ? null : onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: missing ? AppColors.surface : null,
              borderRadius: radius,
            ),
            foregroundDecoration: isToday
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: AppColors.accent, width: 2),
                  )
                : null,
            child: content,
          ),
        ),
      ),
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
  const _PhotoContent({required this.file, required this.day});

  final File file;
  final int day;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Grid thumbnails decode small; full size only in the detail view.
        Image.file(
          file,
          cacheWidth: 200,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => _MissingContent(day: day),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 2, offset: Offset(0, 1))],
            ),
          ),
        ),
      ],
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
            alignment: Alignment(0, -0.3),
            child: Icon(
              Icons.broken_image_outlined,
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
              style: const TextStyle(fontSize: 11, color: AppColors.dayMuted),
            ),
          ),
        ],
      ),
    );
  }
}
