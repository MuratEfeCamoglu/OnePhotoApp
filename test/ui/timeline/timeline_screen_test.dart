import 'package:one_photo_app/services/settings_store.dart';
import 'package:one_photo_app/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:one_photo_app/core/date_key.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/ui/settings/settings_screen.dart';
import 'package:one_photo_app/ui/timeline/day_cell.dart';
import 'package:one_photo_app/ui/timeline/month_grid.dart';

import '../../fakes.dart';
import '../pump.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  late TestHarness h;
  tearDown(() => h.dispose());

  testWidgets('app bar has title, camera and settings icons (F1g)', (
    tester,
  ) async {
    h = await TestHarness.create();
    await pumpTimeline(tester, h);
    expect(find.text('OnePhoto'), findsOneWidget);
    expect(find.byKey(const ValueKey('camera-button')), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });

  testWidgets('weekday header starts on Monday (F1d)', (tester) async {
    h = await TestHarness.create();
    await pumpTimeline(tester, h);
    final pzt = tester.getCenter(find.text('Pzt'));
    final paz = tester.getCenter(find.text('Paz'));
    expect(pzt.dx, lessThan(paz.dx));
  });

  testWidgets('no entries → empty message above the grid (F1f)', (
    tester,
  ) async {
    h = await TestHarness.create();
    await pumpTimeline(tester, h);
    expect(find.text(Strings.tr.emptyTimeline), findsOneWidget);
    expect(find.text('Ekim 2026'), findsOneWidget);
    expect(
      tester.getCenter(find.text(Strings.tr.emptyTimeline)).dy,
      lessThan(tester.getCenter(find.text('Ekim 2026')).dy),
    );
    expect(h.controller.months, hasLength(12));
  });

  testWidgets('the 12 month range reaches back to November 2025 (F1b)', (
    tester,
  ) async {
    h = await TestHarness.create();
    await pumpTimeline(tester, h);
    expect(find.text('Kasım 2025'), findsNothing); // lazily built
    await tester.scrollUntilVisible(
      find.text('Kasım 2025'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kasım 2025'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(find.text('Kasım 2025'), findsOneWidget);
    expect(find.text('Ekim 2025'), findsNothing);
  });

  testWidgets('3 entries → 3 thumbnail cells, no empty message', (
    tester,
  ) async {
    h = await TestHarness.create(
      photoDays: ['2026-10-01', '2026-10-05', '2026-10-09'],
    );
    await pumpTimeline(tester, h);
    final thumbs = find.descendant(
      of: find.byType(DayCell),
      matching: find.byType(Image),
    );
    expect(thumbs, findsNWidgets(3));
    expect(find.text(Strings.tr.emptyTimeline), findsNothing);
  });

  testWidgets('entry whose file is gone shows a broken image icon (F6e)', (
    tester,
  ) async {
    h = await TestHarness.create(missingDays: ['2026-10-02']);
    await pumpTimeline(tester, h);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('day-2026-10-02')),
        matching: find.byIcon(Icons.broken_image),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings icon opens settings with the storage notice (F6g)', (
    tester,
  ) async {
    h = await TestHarness.create();
    await pumpTimeline(
      tester,
      h,
      settingsBuilder: (_) =>
          SettingsScreen(reminders: h.reminders, appearance: h.appearance),
    );
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    expect(find.text(Strings.tr.storageInfo), findsOneWidget);
  });

  Finder thumbIn(String key) => find.descendant(
    of: find.byKey(ValueKey('day-$key')),
    matching: find.byType(Image),
  );

  testWidgets('camera icon → photo lands in today\'s cell (F2a, F2b)', (
    tester,
  ) async {
    h = await TestHarness.create();
    h.picker.cameraResult = writeSourcePhoto(h.root);
    await pumpTimeline(tester, h);
    expect(thumbIn('2026-10-09'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('camera-button')));
    await tester.pumpAndSettle();

    expect(h.picker.cameraCalls, 1);
    expect(thumbIn('2026-10-09'), findsOneWidget);
    expect(find.text(Strings.tr.emptyTimeline), findsNothing);
  });

  testWidgets('tapping the empty card opens the camera for today', (
    tester,
  ) async {
    h = await TestHarness.create();
    h.picker.cameraResult = writeSourcePhoto(h.root);
    await pumpTimeline(tester, h);
    await tester.tap(find.text(Strings.tr.emptyTimeline));
    await tester.pumpAndSettle();
    expect(h.picker.cameraCalls, 1);
    expect(h.repo.rows.keys, ['2026-10-09']);
  });

  testWidgets('cancelling the camera changes nothing (F2c)', (tester) async {
    h = await TestHarness.create();
    await pumpTimeline(tester, h);
    await tester.tap(find.byKey(const ValueKey('camera-button')));
    await tester.pumpAndSettle();
    expect(h.repo.rows, isEmpty);
    expect(find.text(Strings.tr.emptyTimeline), findsOneWidget);
  });

  testWidgets('camera icon on a filled today asks before replacing (F4b)', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-09']);
    await pumpTimeline(tester, h);
    await tester.tap(find.byKey(const ValueKey('camera-button')));
    await tester.pumpAndSettle();
    expect(find.text(Strings.tr.replaceQuestion), findsOneWidget);
  });

  testWidgets('empty past cell → sheet → gallery fills that day (F3)', (
    tester,
  ) async {
    h = await TestHarness.create();
    h.picker.galleryResult = writeSourcePhoto(h.root);
    await pumpTimeline(tester, h);

    await tester.tap(find.byKey(const ValueKey('day-2026-10-05')));
    await tester.pumpAndSettle();
    expect(find.text('5 Ekim 2026'), findsOneWidget);
    await tester.tap(find.text(Strings.tr.pickFromGallery));
    await tester.pumpAndSettle();

    expect(thumbIn('2026-10-05'), findsOneWidget);
    expect(h.repo.rows.keys, ['2026-10-05']);
  });

  testWidgets('tapping a future cell opens nothing (F1e)', (tester) async {
    h = await TestHarness.create();
    await pumpTimeline(tester, h);
    await tester.tap(
      find.byKey(const ValueKey('day-2026-10-20')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text(Strings.tr.takePhoto), findsNothing);
  });

  testWidgets('365 entries: only months near the viewport are built (§5)', (
    tester,
  ) async {
    final days = [
      for (var i = 0; i < 365; i++) dateKeyOf(DateTime(2026, 10, 9 - i)),
    ];
    h = await TestHarness.create(photoDays: days);
    await pumpTimeline(tester, h);
    expect(h.controller.entryCount, 365);
    expect(find.byType(MonthGrid).evaluate().length, lessThan(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup error is shown as a SnackBar (F8b)', (tester) async {
    h = await TestHarness.create();
    h.picker.lostResult = h.storage.resolve('does-not-exist.jpg');
    await pumpTimeline(tester, h);
    expect(find.text(Strings.tr.photoSaveFailed), findsOneWidget);
  });

  testWidgets('English: month titles, weekdays and empty card (F10)', (
    tester,
  ) async {
    h = await TestHarness.create();
    await h.appearance.setLanguage(AppLanguage.en);
    await pumpTimeline(tester, h);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Add your first photo'), findsOneWidget);
    expect(find.text('Your life, one photo at a time.'), findsOneWidget);
  });

  testWidgets('dark theme paints the timeline dark (F9)', (tester) async {
    h = await TestHarness.create();
    await h.appearance.setThemePreference(ThemePreference.dark);
    await pumpTimeline(tester, h);
    final context = tester.element(find.text('Ekim 2026'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(context.palette.background, AppPalette.dark.background);
  });

  testWidgets('home button scrolls back to the current month', (tester) async {
    h = await TestHarness.create();
    await pumpTimeline(tester, h);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text('Ekim 2026'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('home-button')));
    await tester.pumpAndSettle();
    expect(find.text('Ekim 2026'), findsOneWidget);
  });

  testWidgets('title shrinks and the subtitle folds away on scroll', (
    tester,
  ) async {
    h = await TestHarness.create();
    await pumpTimeline(tester, h);
    double titleSize() =>
        tester.widget<Text>(find.text('OnePhoto')).style!.fontSize!;
    expect(titleSize(), 32);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(titleSize(), 22);
  });
}
