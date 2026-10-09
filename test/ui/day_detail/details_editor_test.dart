import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:one_photo_app/core/categories.dart';
import 'package:one_photo_app/data/entry.dart';
import 'package:one_photo_app/ui/day_detail/details_editor.dart';
import 'package:one_photo_app/ui/widgets/category_style.dart';

import '../../fakes.dart';
import '../pump.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  late TestHarness h;
  tearDown(() => h.dispose());

  // Cell → preview → full screen → edit (ISKELET F11, F12).
  Future<void> openEditor(WidgetTester tester, String key) async {
    await pumpTimeline(tester, h);
    await tester.tap(find.byKey(ValueKey('day-$key')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-full')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-details')));
    await tester.pumpAndSettle();
  }

  Finder noteField() => find.byKey(const ValueKey('note-field'));

  Future<void> tapCategory(WidgetTester tester, String id) async {
    final chip = find.byKey(ValueKey('category-$id'));
    await tester.scrollUntilVisible(
      chip,
      120,
      scrollable: find.descendant(
        of: find.byType(CategoryPicker),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pump();
  }

  testWidgets('full screen edit opens the editor with current values', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    final e = h.repo.rows['2026-10-05']!;
    h.repo.rows['2026-10-05'] = e.withDetails(
      note: 'Eski not',
      category: PhotoCategory.food,
    );
    await openEditor(tester, '2026-10-05');

    expect(find.byType(DetailsEditor), findsOneWidget);
    expect(find.text('Eski not'), findsWidgets);
    final food = tester.widget<CategoryChip>(
      find.byKey(const ValueKey('category-food')),
    );
    expect(food.selected, isTrue);
  });

  testWidgets('saving updates note and category, panel reflects it', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openEditor(tester, '2026-10-05');
    await tapCategory(tester, 'travel');
    await tester.enterText(noteField(), '  Uzun yol  ');
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();

    expect(find.byType(DetailsEditor), findsNothing);
    final saved = h.repo.rows['2026-10-05']!;
    expect(saved.note, 'Uzun yol');
    expect(saved.category, PhotoCategory.travel);
    expect(find.byKey(const ValueKey('detail-category')), findsOneWidget);
    expect(find.text('Uzun yol'), findsOneWidget);
  });

  testWidgets('closing the editor with back also saves', (tester) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openEditor(tester, '2026-10-05');
    await tester.enterText(noteField(), 'Geri tuşuyla');
    tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(h.repo.rows['2026-10-05']!.note, 'Geri tuşuyla');
  });

  testWidgets('blank note and deselected category clear the details', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    final e = h.repo.rows['2026-10-05']!;
    h.repo.rows['2026-10-05'] = e.withDetails(
      note: 'x',
      category: PhotoCategory.food,
    );
    await openEditor(tester, '2026-10-05');
    await tapCategory(tester, 'food');
    await tester.enterText(noteField(), '   ');
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();
    expect(h.repo.rows['2026-10-05']!.note, isNull);
    expect(h.repo.rows['2026-10-05']!.category, isNull);
  });

  testWidgets('a saved note and category show badges on the grid cell', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openEditor(tester, '2026-10-05');
    await tapCategory(tester, 'pet');
    await tester.enterText(noteField(), 'Rozet');
    await tester.tap(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    for (final badge in ['note-badge', 'category-badge']) {
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('day-2026-10-05')),
          matching: find.byKey(ValueKey(badge)),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('note field is limited to ${Entry.maxNoteLength} characters', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openEditor(tester, '2026-10-05');
    expect(
      tester.widget<TextField>(noteField()).maxLength,
      Entry.maxNoteLength,
    );
  });

  testWidgets('save button stays reachable with the keyboard open', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await openEditor(tester, '2026-10-05');
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('save-note')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('save-note')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('empty details show an add prompt in full screen', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    await pumpTimeline(tester, h);
    await tester.tap(find.byKey(const ValueKey('day-2026-10-05')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-full')));
    await tester.pumpAndSettle();
    expect(find.text('Kategori ve not ekle'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_rounded), findsOneWidget);
  });

  testWidgets('a saved category at the end of the row is scrolled into view', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-05']);
    final last = PhotoCategory.values.last;
    final e = h.repo.rows['2026-10-05']!;
    h.repo.rows['2026-10-05'] = e.withDetails(note: null, category: last);
    await openEditor(tester, '2026-10-05');
    expect(
      find.byKey(ValueKey('category-${last.id}')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-food')).hitTestable(),
      findsNothing,
    );
  });
}
