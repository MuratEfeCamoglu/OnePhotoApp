import 'package:flutter/material.dart';

/// Light-only palette from onephoto-mockup.html (ISKELET V12).
abstract final class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F4F5);
  static const outline = Color(0xFFE4E4E7);
  static const onSurface = Color(0xFF18181B);
  static const onSurfaceVariant = Color(0xFF52525B);
  static const dayMuted = Color(0xFF71717A);
  static const accent = Color(0xFFC2410C);
  static const onAccent = Color(0xFFFFFFFF);
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFFCE8E6);
  static const scrim = Color(0x52000000);
  static const photoScrim = Color(0x8C000000);
  static const snackbar = Color(0xFF27272A);
  static const onSnackbar = Color(0xFFFAFAFA);
  static const handle = Color(0xFFC4C4CA);
}

/// Radii, spacing and opacities shared by every screen.
abstract final class AppDimens {
  static const cellRadius = 10.0;
  static const cardRadius = 16.0;
  static const sheetRadius = 28.0;
  static const dialogRadius = 28.0;
  static const buttonRadius = 22.0;
  static const snackbarRadius = 8.0;
  static const cellGap = 6.0;
  static const gutter = 16.0;
  static const futureOpacity = 0.4;
}

/// Text sizes of the mockup's type scale.
abstract final class AppText {
  static const appTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.44,
    color: AppColors.onSurface,
  );
  static const screenTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );
  static const month = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.17,
    color: AppColors.onSurface,
  );
  static const headline = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.2,
    color: AppColors.onSurface,
  );
  static const body = TextStyle(fontSize: 16, color: AppColors.onSurface);
  static const label = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const weekday = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.22,
    color: AppColors.onSurfaceVariant,
  );
}

RoundedRectangleBorder _rounded(double radius) =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

/// Builds the app's only theme.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    surface: AppColors.background,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.dayMuted,
    outlineVariant: AppColors.outline,
    error: AppColors.error,
    errorContainer: AppColors.errorContainer,
    surfaceTint: Colors.transparent,
  );
  const buttonSize = Size(0, 44);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      titleTextStyle: AppText.screenTitle,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: AppColors.scrim,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.sheetRadius),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      insetPadding: const EdgeInsets.symmetric(horizontal: 39, vertical: 24),
      shape: _rounded(AppDimens.dialogRadius),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        minimumSize: buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: _rounded(AppDimens.buttonRadius),
        textStyle: AppText.label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onSurfaceVariant,
        minimumSize: buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: _rounded(AppDimens.buttonRadius),
        textStyle: AppText.label,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.onAccent
            : AppColors.dayMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.accent
            : AppColors.surface,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Colors.transparent
            : AppColors.dayMuted,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.snackbar,
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: _rounded(AppDimens.snackbarRadius),
      elevation: 6,
      contentTextStyle: const TextStyle(
        fontSize: 14,
        height: 1.43,
        color: AppColors.onSnackbar,
      ),
    ),
  );
}
