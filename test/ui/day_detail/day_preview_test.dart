import 'package:one_photo_app/core/categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/data/entry.dart';
import 'package:one_photo_app/ui/widgets/category_style.dart';
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

  Finder noteField() => find.byKey(const ValueKey('note-field'));

  testWidgets('tapping a photo day opens a sized preview card (F11)', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');

    expect(find.byType(DayPreview), findsOneWidget);
    expect(find.text('5 Ekim 2026, Pazartesi'), findsOneWidget);
    final photo = find.descendant(
      of: find.byType(DayPreview),
      matching: find.byType(Image),
    );
    final size = tester.getSize(photo);
    expect(size.width, size.height, reason: 'square photo');
    expect(size.width, lessThan(360), reason: 'card, not full screen');
    expect(noteField(), findsOneWidget);
    expect(find.text(Strings.tr.noteLabel), findsOneWidget);
  });

  testWidgets('"Kaydet" stores the note and closes the card', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    await tester.enterText(noteField(), '  Sahilde uzun yürüyüş  ');
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();

    expect(find.byType(DayPreview), findsNothing);
    expect(h.repo.rows['2026-10-05']!.note, 'Sahilde uzun yürüyüş');
    expect(h.controller.entryFor('2026-10-05')!.note, 'Sahilde uzun yürüyüş');
  });

  testWidgets('closing with back also saves the note', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    await tester.enterText(noteField(), 'Geri tuşuyla kaydedildi');
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.maybePop();
    await tester.pumpAndSettle();
    expect(h.repo.rows['2026-10-05']!.note, 'Geri tuşuyla kaydedildi');
  });

  testWidgets('tapping outside the card closes it', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(DayPreview), findsNothing);
  });

  testWidgets('existing note is shown and can be cleared', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    final e = h.repo.rows['2026-10-05']!;
    h.repo.rows['2026-10-05'] = e.withNote('Eski not');
    await openPreview(tester, '2026-10-05');
    expect(find.text('Eski not'), findsOneWidget);

    await tester.enterText(noteField(), '   ');
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();
    expect(h.repo.rows['2026-10-05']!.note, isNull);
  });

  testWidgets('note field is limited to ${Entry.maxNoteLength} characters', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    final field = tester.widget<TextField>(noteField());
    expect(field.maxLength, Entry.maxNoteLength);
  });

  testWidgets('"Tam ekran" opens the zoomable detail with the note', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    await tester.enterText(noteField(), 'Detayda da görünür');
    await tester.tap(find.byKey(const ValueKey('open-full')));
    await tester.pumpAndSettle();

    expect(find.byType(DayDetailScreen), findsOneWidget);
    expect(find.byType(DayPreview), findsNothing);
    expect(find.byKey(const ValueKey('detail-note')), findsOneWidget);
    expect(find.text('Detayda da görünür'), findsOneWidget);
  });

  testWidgets('empty day still opens the source sheet, not the preview', (
    tester,
  ) async {
    h = await TestHarness.create();
    await openPreview(tester, '2026-10-05');
    expect(find.byType(DayPreview), findsNothing);
    expect(find.text(Strings.tr.takePhoto), findsOneWidget);
  });

  testWidgets('a saved note shows a badge on the grid cell', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    expect(find.byKey(const ValueKey('note-badge')), findsNothing);
    await tester.enterText(noteField(), 'Rozet');
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('day-2026-10-05')),
        matching: find.byKey(const ValueKey('note-badge')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('English preview uses English texts (F10)', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await initializeDateFormatting('en_US');
    await h.appearance.setLanguage(AppLanguage.en);
    await openPreview(tester, '2026-10-05');
    expect(find.text('Monday, October 5, 2026'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Full screen'), findsOneWidget);
  });

  testWidgets('photo shrinks while the keyboard is open', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    Size photoSize() =>
        tester.getSize(find.byKey(const ValueKey('preview-photo')));
    expect(photoSize().height, greaterThan(250));

    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(photoSize().height, 120);
    expect(
      find.byKey(const ValueKey('save-note')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('choosing a category and saving stores it (F12)', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    expect(find.text('Yemek'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('category-travel')),
      120,
      scrollable: find.descendant(
        of: find.byType(CategoryPicker),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-travel')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();

    expect(h.repo.rows['2026-10-05']!.category, PhotoCategory.travel);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('day-2026-10-05')),
        matching: find.byKey(const ValueKey('category-badge')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('changing only the category counts as a change', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openPreview(tester, '2026-10-05');
    await tester.tap(find.byKey(const ValueKey('category-food')));
    await tester.pump();
    tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(h.repo.rows['2026-10-05']!.category, PhotoCategory.food);
  });

  testWidgets('full screen detail shows the category', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    final e = h.repo.rows['2026-10-05']!;
    h.repo.rows['2026-10-05'] = e.withDetails(
      note: null,
      category: PhotoCategory.pet,
    );
    await openPreview(tester, '2026-10-05');
    await tester.tap(find.byKey(const ValueKey('open-full')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('detail-category')), findsOneWidget);
    expect(find.text('Evcil hayvan'), findsOneWidget);
  });
}
