import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:one_photo_app/core/categories.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/ui/day_detail/day_detail_screen.dart';
import 'package:one_photo_app/ui/day_detail/day_preview.dart';

import '../../fakes.dart';
import '../pump.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  late TestHarness h;
  tearDown(() => h.dispose());

  Future<void> openPreview(WidgetTester tester, String key) async {
    await pumpTimeline(tester, h);
    await tester.tap(find.byKey(ValueKey('day-$key')));
    await tester.pumpAndSettle();
  }

  void setDetails(String key, {String? note, PhotoCategory? category}) {
    final e = h.repo.rows[key]!;
    h.repo.rows[key] = e.withDetails(note: note, category: category);
  }

  testWidgets('tapping a photo day opens a sized preview card (F11)', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');

    expect(find.byType(DayPreview), findsOneWidget);
    expect(find.text('5 Ekim 2026, Pazartesi'), findsOneWidget);
    final size = tester.getSize(find.byKey(const ValueKey('preview-photo')));
    expect(size.width, size.height, reason: 'square photo');
    expect(size.width, lessThan(360), reason: 'card, not full screen');
  });

  testWidgets('shows the saved category and note read-only', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    setDetails('2026-10-05', note: 'Sahilde gün', category: PhotoCategory.view);
    await openPreview(tester, '2026-10-05');

    expect(find.byKey(const ValueKey('preview-category')), findsOneWidget);
    expect(find.text('Manzara'), findsOneWidget);
    expect(find.text('Sahilde gün'), findsOneWidget);
    // Nothing to edit in the preview.
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('save-note')), findsNothing);
    expect(find.byKey(const ValueKey('category-food')), findsNothing);
  });

  testWidgets('tapping the category chip in the preview changes nothing', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    setDetails('2026-10-05', category: PhotoCategory.view);
    await openPreview(tester, '2026-10-05');
    await tester.tap(find.byKey(const ValueKey('preview-category')));
    await tester.pumpAndSettle();
    expect(h.repo.rows['2026-10-05']!.category, PhotoCategory.view);
    expect(find.byType(DayPreview), findsOneWidget);
  });

  testWidgets('without details it points to full screen', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    expect(find.text(Strings.tr.previewEmptyHint), findsOneWidget);
  });

  testWidgets('tapping outside the card closes it', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(DayPreview), findsNothing);
  });

  testWidgets('"Tam ekran" replaces the card with the detail', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    await tester.tap(find.byKey(const ValueKey('open-full')));
    await tester.pumpAndSettle();
    expect(find.byType(DayDetailScreen), findsOneWidget);
    expect(find.byType(DayPreview), findsNothing);
  });

  testWidgets('tapping the photo also opens full screen', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    await tester.tap(find.byKey(const ValueKey('preview-photo')));
    await tester.pumpAndSettle();
    expect(find.byType(DayDetailScreen), findsOneWidget);
  });

  testWidgets('empty day still opens the source sheet, not the preview', (
    tester,
  ) async {
    h = await TestHarness.create();
    await openPreview(tester, '2026-10-05');
    expect(find.byType(DayPreview), findsNothing);
    expect(find.text(Strings.tr.takePhoto), findsOneWidget);
  });

  testWidgets('English preview uses English texts (F10)', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await initializeDateFormatting('en_US');
    await h.appearance.setLanguage(AppLanguage.en);
    setDetails('2026-10-05', category: PhotoCategory.pet);
    await openPreview(tester, '2026-10-05');
    expect(find.text('Monday, October 5, 2026'), findsOneWidget);
    expect(find.text('Pet'), findsOneWidget);
    expect(find.text('Full screen'), findsOneWidget);
  });
}
