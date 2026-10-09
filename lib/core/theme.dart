import 'package:flutter/material.dart';

/// Light-only theme following onephoto-mockup.html (ISKELET V12).
abstract final class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F4F5);
  static const outline = Color(0xFFE4E4E7);
  static const onSurface = Color(0xFF18181B);
  static const onSurfaceVariant = Color(0xFF52525B);
  static const dayMuted = Color(0xFF71717A);
  static const accent = Color(0xFFC2410C);
  static const error = Color(0xFFB3261E);
  static const photoScrim = Color(0x8C000000);
  static const snackbar = Color(0xFF27272A);
}

/// Shared radii and opacities so widgets stay consistent.
abstract final class AppDimens {
  static const cellRadius = 10.0;
  static const cellGap = 6.0;
  static const gutter = 16.0;
  static const futureOpacity = 0.4;
}

/// Builds the app's only theme.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    primary: AppColors.accent,
    surface: AppColors.background,
    onSurface: AppColors.onSurface,
    error: AppColors.error,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.snackbar,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
