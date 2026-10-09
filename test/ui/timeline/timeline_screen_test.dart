import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/ui/settings/settings_screen.dart';
import 'package:one_photo_app/ui/timeline/day_cell.dart';

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
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
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
    expect(find.text(Strings.emptyTimeline), findsOneWidget);
    expect(find.text('Ekim 2026'), findsOneWidget);
    expect(
      tester.getCenter(find.text(Strings.emptyTimeline)).dy,
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
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
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
    expect(find.text(Strings.emptyTimeline), findsNothing);
  });

  testWidgets('entry whose file is gone shows a broken image icon (F6e)', (
    tester,
  ) async {
    h = await TestHarness.create(missingDays: ['2026-10-02']);
    await pumpTimeline(tester, h);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('day-2026-10-02')),
        matching: find.byIcon(Icons.broken_image_outlined),
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
      settingsBuilder: (_) => SettingsScreen(reminders: h.reminders),
    );
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text(Strings.storageInfo), findsOneWidget);
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

    await tester.tap(find.byIcon(Icons.photo_camera_outlined));
    await tester.pumpAndSettle();

    expect(h.picker.cameraCalls, 1);
    expect(thumbIn('2026-10-09'), findsOneWidget);
    expect(find.text(Strings.emptyTimeline), findsNothing);
  });

  testWidgets('cancelling the camera changes nothing (F2c)', (tester) async {
    h = await TestHarness.create();
    await pumpTimeline(tester, h);
    await tester.tap(find.byIcon(Icons.photo_camera_outlined));
    await tester.pumpAndSettle();
    expect(h.repo.rows, isEmpty);
    expect(find.text(Strings.emptyTimeline), findsOneWidget);
  });

  testWidgets('camera icon on a filled today asks before replacing (F4b)', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-09']);
    await pumpTimeline(tester, h);
    await tester.tap(find.byIcon(Icons.photo_camera_outlined));
    await tester.pumpAndSettle();
    expect(find.text(Strings.replaceQuestion), findsOneWidget);
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
    await tester.tap(find.text(Strings.pickFromGallery));
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
    expect(find.text(Strings.takePhoto), findsNothing);
  });

  testWidgets('startup error is shown as a SnackBar (F8b)', (tester) async {
    h = await TestHarness.create();
    h.picker.lostResult = h.storage.resolve('does-not-exist.jpg');
    await pumpTimeline(tester, h);
    expect(find.text(Strings.photoSaveFailed), findsOneWidget);
  });
}
