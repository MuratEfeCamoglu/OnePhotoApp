import 'package:intl/intl.dart';

import 'strings.dart';

final _keyPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Day key (`YYYY-MM-DD`) of [time] in the device's local time zone.
String dateKeyOf(DateTime time) {
  // A UTC instant must be shifted to local first, otherwise late-evening
  // photos land on the wrong day (ISKELET §7).
  final local = time.isUtc ? time.toLocal() : time;
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Local midnight of the day identified by [key].
DateTime parseDateKey(String key) {
  final match = _keyPattern.firstMatch(key);
  if (match == null) throw FormatException('Invalid day key', key);
  final y = int.parse(match[1]!);
  final m = int.parse(match[2]!);
  final d = int.parse(match[3]!);
  final date = DateTime(y, m, d);
  // DateTime silently rolls invalid dates over (2026-02-30 → March 2).
  if (date.year != y || date.month != m || date.day != d) {
    throw FormatException('Invalid day key', key);
  }
  return date;
}

DateFormat _format(String pattern, Strings strings) =>
    DateFormat(pattern, strings.language.localeName);

/// Month header such as "Ocak 2026" / "October 2026".
String formatMonthTitle(int year, int month, {Strings strings = Strings.tr}) =>
    _format(strings.monthPattern, strings).format(DateTime(year, month));

/// Detail title such as "9 Ekim 2026, Cuma".
String formatLongDate(String key, {Strings strings = Strings.tr}) =>
    _format(strings.longDatePattern, strings).format(parseDateKey(key));

/// Compact label such as "9 Eki" / "Oct 9".
String formatDayMonth(String key, {Strings strings = Strings.tr}) =>
    _format(strings.dayMonthPattern, strings).format(parseDateKey(key));

/// Sheet title such as "9 Ekim 2026".
String formatShortDate(String key, {Strings strings = Strings.tr}) =>
    _format(strings.shortDatePattern, strings).format(parseDateKey(key));
