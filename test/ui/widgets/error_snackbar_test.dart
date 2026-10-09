import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/errors.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/ui/widgets/error_snackbar.dart';

void main() {
  test('maps errors to the F8 messages', () {
    expect(
      errorMessage(const PermissionDeniedException(PermissionKind.camera)),
      Strings.cameraPermissionDenied,
    );
    expect(
      errorMessage(const PermissionDeniedException(PermissionKind.photos)),
      Strings.photosPermissionDenied,
    );
    expect(errorMessage(const PhotoSaveException()), Strings.photoSaveFailed);
    expect(errorMessage(Exception('x')), Strings.photoSaveFailed);
  });

  testWidgets('shows the message in a SnackBar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showErrorSnackBar(
                context,
                const PermissionDeniedException(PermissionKind.camera),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.text(Strings.cameraPermissionDenied), findsOneWidget);
  });
}
