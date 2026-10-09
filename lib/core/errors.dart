/// Which permission the user refused.
enum PermissionKind { camera, photos }

/// Thrown when the user has denied camera or photo library access.
class PermissionDeniedException implements Exception {
  /// Creates an exception for the refused [kind].
  const PermissionDeniedException(this.kind);

  /// The refused permission.
  final PermissionKind kind;

  @override
  String toString() => 'PermissionDeniedException($kind)';
}

/// Thrown when a photo could not be written to disk or to the database.
class PhotoSaveException implements Exception {
  /// Creates an exception wrapping the underlying [cause].
  const PhotoSaveException([this.cause]);

  /// The original error, kept for debugging.
  final Object? cause;

  @override
  String toString() => 'PhotoSaveException($cause)';
}
