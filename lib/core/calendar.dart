/// A calendar month without a day component.
class YearMonth implements Comparable<YearMonth> {
  /// Creates a month; [month] is 1-based.
  const YearMonth(this.year, this.month);

  /// Month containing [date].
  factory YearMonth.fromDate(DateTime date) => YearMonth(date.year, date.month);

  /// Month part of a `YYYY-MM-DD` day key.
  factory YearMonth.fromDateKey(String key) =>
      YearMonth(int.parse(key.substring(0, 4)), int.parse(key.substring(5, 7)));

  /// Calendar year.
  final int year;

  /// Month number, 1–12.
  final int month;

  /// Shifts by [delta] months, wrapping across years.
  YearMonth addMonths(int delta) {
    final index = year * 12 + (month - 1) + delta;
    return YearMonth(index ~/ 12, index % 12 + 1);
  }

  @override
  int compareTo(YearMonth other) =>
      (year * 12 + month).compareTo(other.year * 12 + other.month);

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'YearMonth($year, $month)';
}

/// Number of days in [month] of [year].
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Grid cells for a Monday-first 7 column month: `null` for padding,
/// otherwise the day number. Trailing padding completes the last row.
List<int?> monthCells(int year, int month) {
  final leading = DateTime(year, month).weekday - DateTime.monday;
  final days = daysInMonth(year, month);
  final cells = <int?>[
    for (var i = 0; i < leading; i++) null,
    for (var d = 1; d <= days; d++) d,
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}

/// Months to show, newest first: from [current] back to
/// `min(earliest, current − 11)` (ISKELET F1b).
List<YearMonth> visibleMonths({
  required YearMonth current,
  YearMonth? earliest,
}) {
  var oldest = current.addMonths(-11);
  if (earliest != null && earliest.compareTo(oldest) < 0) oldest = earliest;
  return [
    for (var m = current; m.compareTo(oldest) >= 0; m = m.addMonths(-1)) m,
  ];
}
