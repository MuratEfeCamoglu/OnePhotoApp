import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/ui/day_detail/day_detail_screen.dart';
import 'package:one_photo_app/ui/timeline/day_cell.dart';

import '../../fakes.dart';
import '../pump.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  late TestHarness h;
  tearDown(() => h.dispose());

  Future<void> openDetail(WidgetTester tester, String key) async {
    await pumpTimeline(tester, h);
    await tester.tap(find.byKey(ValueKey('day-$key')));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a photo cell opens the detail with the date (F5a)', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-09']);
    await openDetail(tester, '2026-10-09');
    expect(find.byType(DayDetailScreen), findsOneWidget);
    expect(find.text('9 Ekim 2026, Cuma'), findsOneWidget);
  });

  testWidgets('photo is fitted, full size and zoomable 1x–4x (F5a)', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-09']);
    await openDetail(tester, '2026-10-09');
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.minScale, 1);
    expect(viewer.maxScale, 4);
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(Image),
      ),
    );
    expect(image.fit, BoxFit.contain);
    expect(image.image, isA<FileImage>()); // no cacheWidth downscale
  });

  testWidgets('delete asks, then removes entry and file and returns (F5c)', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-09']);
    await openDetail(tester, '2026-10-09');

    await tester.tap(find.text(Strings.delete));
    await tester.pumpAndSettle();
    expect(find.text(Strings.deleteQuestion), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, Strings.delete));
    await tester.pumpAndSettle();

    expect(h.controller.entryFor('2026-10-09'), isNull);
    expect(h.repo.rows, isEmpty);
    expect(await h.storage.listFileNames(), isEmpty);
    expect(find.byType(DayDetailScreen), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('day-2026-10-09')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
  });

  testWidgets('cancelling delete keeps everything', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-09']);
    await openDetail(tester, '2026-10-09');
    await tester.tap(find.text(Strings.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.cancel));
    await tester.pumpAndSettle();
    expect(h.repo.rows, hasLength(1));
    expect(find.byType(DayDetailScreen), findsOneWidget);
  });

  testWidgets('replace opens the sheet, asks, then swaps the photo (F5b)', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    h.picker.galleryResult = writeSourcePhoto(h.root);
    await openDetail(tester, '2026-10-05');

    await tester.tap(find.text(Strings.replace));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.pickFromGallery));
    await tester.pumpAndSettle();
    expect(find.text(Strings.replaceQuestion), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, Strings.replace));
    await tester.pumpAndSettle();

    final entry = h.repo.rows['2026-10-05']!;
    expect(entry.fileName, isNot('2026-10-05_1.jpg'));
    expect(await h.storage.listFileNames(), [entry.fileName]);
    expect(find.byKey(ValueKey(entry.fileName)), findsOneWidget);
  });

  testWidgets('missing file shows a broken image icon instead of crashing', (
    tester,
  ) async {
    h = await TestHarness.create(missingDays: ['2026-10-02']);
    await openDetail(tester, '2026-10-02');
    expect(
      find.descendant(
        of: find.byType(DayDetailScreen),
        matching: find.byIcon(Icons.broken_image_outlined),
      ),
      findsOneWidget,
    );
    expect(find.byType(DayCell), findsNothing);
  });
}
