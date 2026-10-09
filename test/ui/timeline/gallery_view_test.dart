import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:one_photo_app/core/categories.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/ui/day_detail/day_preview.dart';
import 'package:one_photo_app/ui/timeline/gallery_view.dart';

import '../../fakes.dart';
import '../pump.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
    await initializeDateFormatting('en_US');
  });

  late TestHarness h;
  tearDown(() => h.dispose());

  Future<void> openGallery(WidgetTester tester) async {
    await pumpTimeline(tester, h);
    await tester.tap(find.byKey(const ValueKey('gallery-button')));
    await tester.pumpAndSettle();
  }

  Finder tiles() => find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('gallery-20'),
  );

  void setCategory(String key, PhotoCategory c) {
    final e = h.repo.rows[key]!;
    h.repo.rows[key] = e.withDetails(note: e.note, category: c);
  }

  testWidgets('gallery button opens the gallery tab (F13)', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    await openGallery(tester);
    expect(find.byType(GalleryView), findsOneWidget);
    expect(find.text('Galeri'), findsWidgets);
    expect(find.text('1 fotoğraf'), findsOneWidget);
    // The timeline is offstage, not gone.
    expect(find.text('Ekim 2026'), findsNothing);
  });

  testWidgets('shows every photo as a 3 column grid, newest first', (
    tester,
  ) async {
    h = await TestHarness.create(
      photoDays: ['2026-09-20', '2026-10-01', '2026-10-05', '2026-10-09'],
    );
    await openGallery(tester);
    expect(tiles(), findsNWidgets(4));
    double x(String k) => tester.getTopLeft(find.byKey(ValueKey(k))).dx;
    double y(String k) => tester.getTopLeft(find.byKey(ValueKey(k))).dy;
    // Row 1: 9, 5, 1 Oct; row 2: 20 Sep.
    expect(x('gallery-2026-10-09'), lessThan(x('gallery-2026-10-05')));
    expect(x('gallery-2026-10-05'), lessThan(x('gallery-2026-10-01')));
    expect(y('gallery-2026-09-20'), greaterThan(y('gallery-2026-10-09')));
    expect(x('gallery-2026-09-20'), x('gallery-2026-10-09'));
    final size = tester.getSize(
      find.byKey(const ValueKey('gallery-2026-10-09')),
    );
    expect(size.width, size.height);
    expect(find.text('9 Eki'), findsOneWidget);
  });

  testWidgets('tapping a tile opens the read-only preview', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openGallery(tester);
    await tester.tap(find.byKey(const ValueKey('gallery-2026-10-05')));
    await tester.pumpAndSettle();
    expect(find.byType(DayPreview), findsOneWidget);
    expect(find.text('5 Ekim 2026, Pazartesi'), findsOneWidget);
  });

  testWidgets('category filter shows only matching photos', (tester) async {
    h = await TestHarness.create(
      photoDays: ['2026-10-01', '2026-10-02', '2026-10-03'],
    );
    setCategory('2026-10-01', PhotoCategory.food);
    setCategory('2026-10-03', PhotoCategory.food);
    setCategory('2026-10-02', PhotoCategory.pet);
    await openGallery(tester);
    expect(find.byKey(const ValueKey('filter-food')), findsOneWidget);
    expect(find.byKey(const ValueKey('filter-pet')), findsOneWidget);
    expect(find.byKey(const ValueKey('filter-travel')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('filter-food')));
    await tester.pumpAndSettle();
    expect(tiles(), findsNWidgets(2));
    expect(find.text('2 fotoğraf'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('filter-all')));
    await tester.pumpAndSettle();
    expect(tiles(), findsNWidgets(3));
  });

  testWidgets('no categories → no filter row', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    await openGallery(tester);
    expect(find.byKey(const ValueKey('filter-all')), findsNothing);
  });

  testWidgets('empty gallery explains how to start', (tester) async {
    h = await TestHarness.create();
    await openGallery(tester);
    expect(find.text(Strings.tr.galleryEmpty), findsOneWidget);
    expect(find.text('0 fotoğraf'), findsOneWidget);
  });

  testWidgets('home button returns to the timeline', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    await openGallery(tester);
    await tester.tap(find.byKey(const ValueKey('home-button')));
    await tester.pumpAndSettle();
    expect(find.text('Ekim 2026'), findsOneWidget);
    expect(tiles(), findsNothing);
  });

  testWidgets('timeline keeps its scroll position across tabs', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-01']);
    await pumpTimeline(tester, h);
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ekim 2026'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('gallery-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-button')));
    await tester.pumpAndSettle();
    expect(find.text('Ekim 2026'), findsNothing, reason: 'still scrolled');
  });

  testWidgets('a photo added from the gallery tab shows up in the grid', (
    tester,
  ) async {
    h = await TestHarness.create();
    h.picker.cameraResult = writeSourcePhoto(h.root);
    await openGallery(tester);
    await tester.tap(find.byKey(const ValueKey('camera-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gallery-2026-10-09')), findsOneWidget);
  });

  testWidgets('English gallery texts (F10)', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-01', '2026-10-02']);
    await h.appearance.setLanguage(AppLanguage.en);
    await openGallery(tester);
    expect(find.text('Gallery'), findsWidgets);
    expect(find.text('2 photos'), findsOneWidget);
    expect(find.text('Oct 2'), findsOneWidget);
  });

  testWidgets('settings button in the gallery header opens settings', (
    tester,
  ) async {
    h = await TestHarness.create();
    await openGallery(tester);
    await tester.tap(find.byKey(const ValueKey('settings-button')));
    await tester.pumpAndSettle();
    expect(find.text(Strings.tr.storageInfo), findsOneWidget);
  });
}
