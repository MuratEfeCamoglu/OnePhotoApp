import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/services/photo_picker.dart';
import 'package:one_photo_app/ui/widgets/photo_source_sheet.dart';

void main() {
  Future<List<PhotoSource?>> pumpOpener(WidgetTester tester) async {
    final results = <PhotoSource?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  results.add(await showPhotoSourceSheet(context, title: 'T')),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('lists the three options under the day title (F3a)', (
    tester,
  ) async {
    await pumpOpener(tester);
    expect(find.text('T'), findsOneWidget);
    expect(find.text('Fotoğraf çek'), findsOneWidget);
    expect(find.text('Galeriden seç'), findsOneWidget);
    expect(find.text('Vazgeç'), findsOneWidget);
  });

  for (final (label, expected) in [
    (Strings.takePhoto, PhotoSource.camera),
    (Strings.pickFromGallery, PhotoSource.gallery),
    (Strings.cancel, null),
  ]) {
    testWidgets('"$label" resolves to $expected', (tester) async {
      final results = await pumpOpener(tester);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(results, [expected]);
      expect(find.byType(PhotoSourceSheet), findsNothing);
    });
  }
}
