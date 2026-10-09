import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/calendar.dart';
import '../../core/categories.dart';
import '../../core/date_key.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../widgets/l10n.dart';
import 'day_cell.dart';

/// Title plus Monday-first 7 column grid for one month (ISKELET F1c–e).
class MonthGrid extends StatelessWidget {
  /// Creates the grid of [month].
  const MonthGrid({
    super.key,
    required this.month,
    required this.todayKey,
    required this.photoFor,
    required this.onDayTap,
    this.hasNote,
    this.categoryFor,
    this.missingFor,
  });

  /// Month to render.
  final YearMonth month;

  /// Days after this key are future days.
  final String todayKey;

  /// Photo file of a day key, or `null` if the day is empty.
  final File? Function(String dateKey) photoFor;

  /// Whether a day has a note (ISKELET F11); none when `null`.
  final bool Function(String dateKey)? hasNote;

  /// Category of a day (ISKELET F12); none when `null`.
  final PhotoCategory? Function(String dateKey)? categoryFor;

  /// Whether a day's photo file is gone; checked by the cell when `null`.
  final bool Function(String dateKey)? missingFor;

  /// Called with the day key of a tapped (non-future) cell.
  final ValueChanged<String> onDayTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final cells = monthCells(month.year, month.month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        24,
        AppDimens.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              formatMonthTitle(month.year, month.month, strings: strings),
              style: AppText.month.copyWith(color: context.palette.onSurface),
            ),
          ),
          // Plain rows instead of a shrink-wrapped GridView: a month is
          // built in one go while scrolling, so it must be cheap.
          for (var row = 0; row < cells.length ~/ 7; row++) ...[
            if (row > 0) const SizedBox(height: AppDimens.cellGap),
            Row(
              children: [
                for (var col = 0; col < 7; col++) ...[
                  if (col > 0) const SizedBox(width: AppDimens.cellGap),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: cells[row * 7 + col] == null
                          ? const SizedBox.shrink()
                          : _cell(cells[row * 7 + col]!, strings),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(int day, Strings strings) {
    final key = dateKeyOf(DateTime(month.year, month.month, day));
    // Day keys sort chronologically as plain strings.
    final compare = key.compareTo(todayKey);
    final photo = photoFor(key);
    return DayCell(
      key: ValueKey('day-$key'),
      day: day,
      label: formatShortDate(key, strings: strings),
      isToday: compare == 0,
      isFuture: compare > 0,
      photo: photo,
      heroTag: photo == null ? null : photoHeroTag(key),
      hasNote: hasNote?.call(key) ?? false,
      category: categoryFor?.call(key),
      missing: photo == null ? null : missingFor?.call(key),
      onTap: () => onDayTap(key),
    );
  }
}
