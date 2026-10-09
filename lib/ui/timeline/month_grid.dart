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

  /// Called with the day key of a tapped (non-future) cell.
  final ValueChanged<String> onDayTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
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
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            // Today's ring sits just outside its cell.
            clipBehavior: Clip.none,
            mainAxisSpacing: AppDimens.cellGap,
            crossAxisSpacing: AppDimens.cellGap,
            children: [
              for (final day in monthCells(month.year, month.month))
                if (day == null)
                  const SizedBox.shrink()
                else
                  _cell(day, strings),
            ],
          ),
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
      onTap: () => onDayTap(key),
    );
  }
}
