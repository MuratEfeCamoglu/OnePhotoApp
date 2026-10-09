import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/strings.dart';
import 'l10n.dart';

/// User-facing message for an expected error (ISKELET F8).
String errorMessage(Object error, [Strings strings = Strings.tr]) =>
    switch (error) {
      PermissionDeniedException(kind: PermissionKind.camera) =>
        strings.cameraPermissionDenied,
      PermissionDeniedException(kind: PermissionKind.photos) =>
        strings.photosPermissionDenied,
      _ => strings.photoSaveFailed,
    };

/// Shows [text] in a floating SnackBar, replacing the current one.
void showMessageSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Shows [errorMessage] of [error] in a SnackBar.
void showErrorSnackBar(BuildContext context, Object error) =>
    showMessageSnackBar(context, errorMessage(error, context.strings));
