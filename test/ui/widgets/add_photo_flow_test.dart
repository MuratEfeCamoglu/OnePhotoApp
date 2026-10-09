import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:one_photo_app/core/errors.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/services/photo_picker.dart';
import 'package:one_photo_app/ui/widgets/add_photo_flow.dart';

import '../../fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  late TestHarness h;
  tearDown(() => h.dispose());

  Future<void> pumpButton(
    WidgetTester tester,
    Future<void> Function(BuildContext) onPressed,
  ) async {
    await h.controller.startup();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => onPressed(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('empty day saves without asking', (tester) async {
    h = await TestHarness.create();
    h.picker.cameraResult = writeSourcePhoto(h.root);
    await pumpButton(
      tester,
      (c) => addPhotoFlow(c, h.controller, '2026-10-09', PhotoSource.camera),
    );
    expect(find.text(Strings.replaceQuestion), findsNothing);
    expect(h.controller.entryFor('2026-10-09'), isNotNull);
  });

  testWidgets('filled day asks first; "Vazgeç" changes nothing (F4b)', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-09']);
    final before = h.repo.rows['2026-10-09'];
    h.picker.cameraResult = writeSourcePhoto(h.root);
    await pumpButton(
      tester,
      (c) => addPhotoFlow(c, h.controller, '2026-10-09', PhotoSource.camera),
    );
    expect(find.text(Strings.replaceQuestion), findsOneWidget);
    await tester.tap(find.text(Strings.cancel));
    await tester.pumpAndSettle();

    expect(h.picker.cameraCalls, 0);
    expect(h.repo.rows['2026-10-09'], before);
    expect(await h.storage.listFileNames(), [before!.fileName]);
  });

  testWidgets('"Değiştir" replaces and leaves a single file (F4c)', (
    tester,
  ) async {
    h = await TestHarness.create(photoDays: ['2026-10-09']);
    h.picker.cameraResult = writeSourcePhoto(h.root);
    await pumpButton(
      tester,
      (c) => addPhotoFlow(c, h.controller, '2026-10-09', PhotoSource.camera),
    );
    await tester.tap(find.text(Strings.replace));
    await tester.pumpAndSettle();

    final entry = h.repo.rows['2026-10-09']!;
    expect(entry.fileName, isNot('2026-10-09_1.jpg'));
    final files = await h.storage.listFileNames();
    expect(files, [entry.fileName]);
  });

  testWidgets('camera permission denial shows the F8a SnackBar', (
    tester,
  ) async {
    h = await TestHarness.create();
    h.picker.error = const PermissionDeniedException(PermissionKind.camera);
    await pumpButton(
      tester,
      (c) => addPhotoFlow(c, h.controller, '2026-10-09', PhotoSource.camera),
    );
    expect(
      find.text(
        'Kamera izni gerekli. Ayarlar > OnePhoto üzerinden izin verebilirsin.',
      ),
      findsOneWidget,
    );
    expect(h.controller.isEmpty, isTrue);
  });

  testWidgets('save failure shows the F8b SnackBar and leaves no file', (
    tester,
  ) async {
    h = await TestHarness.create();
    h.picker.galleryResult = h.storage.resolve('vanished.jpg');
    await pumpButton(
      tester,
      (c) => addPhotoFlow(c, h.controller, '2026-10-03', PhotoSource.gallery),
    );
    expect(find.text('Fotoğraf kaydedilemedi, tekrar dene.'), findsOneWidget);
    expect(await h.storage.listFileNames(), isEmpty);
    expect(h.repo.rows, isEmpty);
  });

  testWidgets('chooseSourceAndAdd: sheet → gallery saves to that day (F3)', (
    tester,
  ) async {
    h = await TestHarness.create();
    h.picker.galleryResult = writeSourcePhoto(h.root);
    await pumpButton(
      tester,
      (c) => chooseSourceAndAdd(c, h.controller, '2026-10-05'),
    );
    expect(find.text('5 Ekim 2026'), findsOneWidget);
    await tester.tap(find.text(Strings.pickFromGallery));
    await tester.pumpAndSettle();
    expect(h.controller.entryFor('2026-10-05'), isNotNull);
    expect(h.picker.galleryCalls, 1);
  });

  testWidgets('chooseSourceAndAdd: "Vazgeç" opens no picker', (tester) async {
    h = await TestHarness.create();
    await pumpButton(
      tester,
      (c) => chooseSourceAndAdd(c, h.controller, '2026-10-05'),
    );
    await tester.tap(find.text(Strings.cancel));
    await tester.pumpAndSettle();
    expect(h.picker.galleryCalls + h.picker.cameraCalls, 0);
  });

  testWidgets('confirmAction resolves true only on confirm', (tester) async {
    h = await TestHarness.create();
    bool? result;
    await pumpButton(tester, (c) async {
      result = await confirmAction(c, question: 'Q?', confirmLabel: 'OK');
    });
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
