import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/theme.dart';
import 'package:one_photo_app/ui/timeline/day_cell.dart';

import '../../fakes.dart';

Future<void> _pump(WidgetTester tester, DayCell cell) => tester.pumpWidget(
  MaterialApp(
    home: Center(child: SizedBox(width: 48, height: 48, child: cell)),
  ),
);

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('onephoto_cell'));
  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('empty day shows only its number', (tester) async {
    await _pump(
      tester,
      const DayCell(day: 7, label: '7', isToday: false, isFuture: false),
    );
    expect(find.text('7'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    final text = tester.widget<Text>(find.text('7'));
    expect(text.style!.color, AppPalette.light.dayMuted);
  });

  testWidgets('photo day decodes a 200px thumbnail with its number', (
    tester,
  ) async {
    final file = writeSourcePhoto(dir);
    await _pump(
      tester,
      DayCell(day: 3, label: '3', isToday: false, isFuture: false, photo: file),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).width, 200);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('missing file shows the broken image icon (F6e)', (tester) async {
    await _pump(
      tester,
      DayCell(
        day: 3,
        label: '3',
        isToday: false,
        isFuture: false,
        photo: File('${dir.path}/gone.jpg'),
      ),
    );
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('tapping a past day calls onTap', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      DayCell(
        day: 1,
        label: '1',
        isToday: false,
        isFuture: false,
        onTap: () => taps++,
      ),
    );
    await tester.tap(find.byType(DayCell));
    expect(taps, 1);
  });

  testWidgets('future day is 40% opaque and cannot be tapped (F1e)', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      DayCell(
        day: 20,
        label: '20',
        isToday: false,
        isFuture: true,
        onTap: () => taps++,
      ),
    );
    await tester.tap(find.byType(DayCell), warnIfMissed: false);
    expect(taps, 0);
    final opacity = tester.widget<Opacity>(
      find.descendant(of: find.byType(DayCell), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.4);
  });

  testWidgets('today has an accent ring just outside the cell', (tester) async {
    await _pump(
      tester,
      const DayCell(day: 9, label: '9', isToday: true, isFuture: false),
    );
    final ring = find.byKey(const ValueKey('today-ring'));
    final box = tester.widget<DecoratedBox>(ring);
    final decoration = box.decoration as BoxDecoration;
    expect((decoration.border! as Border).top.color, AppPalette.light.accent);
    expect((decoration.border! as Border).top.width, 2);
    // 48px cell + 3px on each side (2px ring, 1px offset as in the mockup).
    expect(tester.getSize(ring), const Size(54, 54));
    final text = tester.widget<Text>(find.text('9'));
    expect(text.style!.color, AppPalette.light.accent);
    expect(text.style!.fontWeight, FontWeight.w700);
  });

  testWidgets('non-today cells have no ring', (tester) async {
    await _pump(
      tester,
      const DayCell(day: 8, label: '8', isToday: false, isFuture: false),
    );
    expect(find.byKey(const ValueKey('today-ring')), findsNothing);
  });

  testWidgets('photo cell carries its hero tag', (tester) async {
    final file = writeSourcePhoto(dir);
    await _pump(
      tester,
      DayCell(
        day: 3,
        label: '3',
        isToday: false,
        isFuture: false,
        photo: file,
        heroTag: photoHeroTag('2026-10-03'),
      ),
    );
    expect(tester.widget<Hero>(find.byType(Hero)).tag, 'photo-2026-10-03');
  });

  testWidgets('note badge only on photo days with a note', (tester) async {
    final file = writeSourcePhoto(dir);
    await _pump(
      tester,
      DayCell(
        day: 3,
        label: '3',
        isToday: false,
        isFuture: false,
        photo: file,
        hasNote: true,
      ),
    );
    expect(find.byKey(const ValueKey('note-badge')), findsOneWidget);
    await _pump(
      tester,
      DayCell(day: 3, label: '3', isToday: false, isFuture: false, photo: file),
    );
    expect(find.byKey(const ValueKey('note-badge')), findsNothing);
  });
}
