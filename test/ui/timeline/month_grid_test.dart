import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:one_photo_app/core/calendar.dart';
import 'package:one_photo_app/ui/timeline/day_cell.dart';
import 'package:one_photo_app/ui/timeline/month_grid.dart';

import '../pump.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  Future<List<String>> pumpOctober(
    WidgetTester tester, {
    File? Function(String)? photoFor,
  }) async {
    final taps = <String>[];
    usePhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthGrid(
              month: const YearMonth(2026, 10),
              todayKey: '2026-10-09',
              photoFor: photoFor ?? (_) => null,
              onDayTap: taps.add,
            ),
          ),
        ),
      ),
    );
    return taps;
  }

  DayCell cell(WidgetTester tester, String key) =>
      tester.widget<DayCell>(find.byKey(ValueKey('day-$key')));

  testWidgets('shows the Turkish month title and every day (F1c)', (
    tester,
  ) async {
    await pumpOctober(tester);
    expect(find.text('Ekim 2026'), findsOneWidget);
    expect(find.byType(DayCell), findsNWidgets(31));
  });

  testWidgets('day 1 is aligned to Thursday in a Monday-first grid (F1d)', (
    tester,
  ) async {
    await pumpOctober(tester);
    double x(String key) => tester.getTopLeft(find.byKey(ValueKey(key))).dx;
    final monday = x('day-2026-10-05');
    final thursday = x('day-2026-10-01');
    final sunday = x('day-2026-10-04');
    expect(x('day-2026-10-12'), monday);
    expect(x('day-2026-10-08'), thursday);
    expect(monday, lessThan(thursday));
    expect(thursday, lessThan(sunday));
    final width = tester.getSize(find.byKey(const ValueKey('day-2026-10-05')));
    // Thursday is the 4th column: three cells (+gaps) right of Monday.
    expect(thursday - monday, closeTo(3 * (width.width + 6), 0.5));
  });

  testWidgets('marks today and the future days (F1e)', (tester) async {
    await pumpOctober(tester);
    expect(cell(tester, '2026-10-09').isToday, isTrue);
    expect(cell(tester, '2026-10-09').isFuture, isFalse);
    expect(cell(tester, '2026-10-08').isFuture, isFalse);
    expect(cell(tester, '2026-10-10').isFuture, isTrue);
    expect(cell(tester, '2026-10-31').isFuture, isTrue);
  });

  testWidgets('tapping a past day reports its key, future days do not', (
    tester,
  ) async {
    final taps = await pumpOctober(tester);
    await tester.tap(find.byKey(const ValueKey('day-2026-10-03')));
    await tester.tap(
      find.byKey(const ValueKey('day-2026-10-20')),
      warnIfMissed: false,
    );
    expect(taps, ['2026-10-03']);
  });

  testWidgets('passes the photo of a day to its cell', (tester) async {
    final file = File('x.jpg');
    await pumpOctober(
      tester,
      photoFor: (key) => key == '2026-10-02' ? file : null,
    );
    expect(cell(tester, '2026-10-02').photo, file);
    expect(cell(tester, '2026-10-03').photo, isNull);
  });
}
