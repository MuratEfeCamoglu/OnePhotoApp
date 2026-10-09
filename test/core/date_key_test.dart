import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:one_photo_app/core/date_key.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('dateKeyOf', () {
    test('pads month and day to YYYY-MM-DD', () {
      expect(dateKeyOf(DateTime(2026, 1, 5)), '2026-01-05');
      expect(dateKeyOf(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('23:59 stays on the same local day', () {
      expect(dateKeyOf(DateTime(2026, 10, 9, 23, 59, 59)), '2026-10-09');
    });

    test('00:00 belongs to the new local day', () {
      expect(dateKeyOf(DateTime(2026, 10, 10)), '2026-10-10');
    });

    test('a UTC instant is converted to the local day, never kept as UTC', () {
      final local = DateTime(2026, 3, 29, 0, 30);
      expect(dateKeyOf(local.toUtc()), dateKeyOf(local));
    });

    test('daylight saving transition days keep their local date', () {
      expect(dateKeyOf(DateTime(2026, 3, 29, 3, 30)), '2026-03-29');
      expect(dateKeyOf(DateTime(2026, 10, 25, 2, 30)), '2026-10-25');
    });

    test('pads years below 1000', () {
      expect(dateKeyOf(DateTime(999, 2, 3)), '0999-02-03');
    });
  });

  group('parseDateKey', () {
    test('round-trips with dateKeyOf', () {
      for (final key in ['2026-10-09', '2028-02-29', '2025-12-31']) {
        expect(dateKeyOf(parseDateKey(key)), key);
      }
    });

    test('returns local midnight', () {
      final d = parseDateKey('2026-10-09');
      expect(d.isUtc, isFalse);
      expect([d.hour, d.minute], [0, 0]);
    });

    test('rejects malformed keys', () {
      expect(() => parseDateKey('2026-1-9'), throwsFormatException);
      expect(() => parseDateKey('2026-13-01'), throwsFormatException);
      expect(() => parseDateKey('2026-02-30'), throwsFormatException);
    });
  });

  group('Turkish formatting', () {
    test('month titles use Turkish month names', () {
      expect(formatMonthTitle(2026, 1), 'Ocak 2026');
      expect(formatMonthTitle(2026, 2), 'Şubat 2026');
      expect(formatMonthTitle(2026, 8), 'Ağustos 2026');
      expect(formatMonthTitle(2026, 10), 'Ekim 2026');
    });

    test('long date includes the weekday', () {
      expect(formatLongDate('2026-10-09'), '9 Ekim 2026, Cuma');
      expect(formatLongDate('2026-10-05'), '5 Ekim 2026, Pazartesi');
    });

    test('short date has no weekday', () {
      expect(formatShortDate('2026-10-05'), '5 Ekim 2026');
    });
  });
}
