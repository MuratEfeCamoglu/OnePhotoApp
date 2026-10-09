import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/strings.dart';

/// User-facing message for an expected error (ISKELET F8).
String errorMessage(Object error) => switch (error) {
  PermissionDeniedException(kind: PermissionKind.camera) =>
    Strings.cameraPermissionDenied,
  PermissionDeniedException(kind: PermissionKind.photos) =>
    Strings.photosPermissionDenied,
  _ => Strings.photoSaveFailed,
};

/// Shows [errorMessage] of [error] in a SnackBar.
void showErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(errorMessage(error))));
}
