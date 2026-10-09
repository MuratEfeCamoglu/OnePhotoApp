import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/calendar.dart';

void main() {
  group('daysInMonth', () {
    test('handles 30/31 day months', () {
      expect(daysInMonth(2026, 1), 31);
      expect(daysInMonth(2026, 4), 30);
      expect(daysInMonth(2026, 12), 31);
    });

    test('leap year February 2028 has 29 days', () {
      expect(daysInMonth(2028, 2), 29);
      expect(monthCells(2028, 2).whereType<int>().last, 29);
    });

    test('non-leap February has 28 days, 2100 is not leap, 2000 is', () {
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2100, 2), 28);
      expect(daysInMonth(2000, 2), 29);
    });
  });

  group('monthCells (week starts Monday)', () {
    test('October 2026 starts on Thursday → 3 leading blanks', () {
      final cells = monthCells(2026, 10);
      expect(cells.take(3), [null, null, null]);
      expect(cells[3], 1);
      expect(cells.whereType<int>().length, 31);
    });

    test('June 2026 starts on Monday → no leading blanks', () {
      expect(monthCells(2026, 6).first, 1);
    });

    test('March 2026 starts on Sunday → 6 leading blanks', () {
      expect(monthCells(2026, 3).indexOf(1), 6);
    });

    test('February 2027 starts Monday and fills exactly 4 rows', () {
      final cells = monthCells(2027, 2);
      expect(cells.first, 1);
      expect(cells.length, 28);
    });

    test('day 1 column matches DateTime.weekday for every month of 2026', () {
      for (var m = 1; m <= 12; m++) {
        final cells = monthCells(2026, m);
        expect(cells.indexOf(1), DateTime(2026, m).weekday - 1, reason: '$m');
        expect(cells.length % 7, 0, reason: 'complete rows for month $m');
      }
    });
  });

  group('YearMonth', () {
    test('addMonths crosses year boundaries', () {
      expect(
        const YearMonth(2026, 10).addMonths(-11),
        const YearMonth(2025, 11),
      );
      expect(const YearMonth(2026, 1).addMonths(-1), const YearMonth(2025, 12));
      expect(const YearMonth(2025, 12).addMonths(1), const YearMonth(2026, 1));
    });

    test('compares chronologically', () {
      expect(const YearMonth(2025, 12).compareTo(const YearMonth(2026, 1)), -1);
      expect(const YearMonth(2026, 1).compareTo(const YearMonth(2026, 1)), 0);
    });

    test('fromDateKey parses the month part', () {
      expect(YearMonth.fromDateKey('2024-03-15'), const YearMonth(2024, 3));
    });
  });

  group('visibleMonths', () {
    const current = YearMonth(2026, 10);

    test('no entries → last 12 months, newest first', () {
      final months = visibleMonths(current: current);
      expect(months.length, 12);
      expect(months.first, current);
      expect(months.last, const YearMonth(2025, 11));
    });

    test('recent entry does not shrink the 12 month window', () {
      final months = visibleMonths(
        current: current,
        earliest: const YearMonth(2026, 9),
      );
      expect(months.length, 12);
    });

    test('entry from two years ago extends the range to its month', () {
      final months = visibleMonths(
        current: current,
        earliest: const YearMonth(2024, 10),
      );
      expect(months.length, 25);
      expect(months.first, current);
      expect(months.last, const YearMonth(2024, 10));
    });

    test('months are strictly descending', () {
      final months = visibleMonths(
        current: current,
        earliest: const YearMonth(2023, 1),
      );
      for (var i = 1; i < months.length; i++) {
        expect(months[i - 1].compareTo(months[i]), 1);
      }
    });
  });
}
