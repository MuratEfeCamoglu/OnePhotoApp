import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Theme-dependent colours; light values follow onephoto-mockup.html.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Creates a palette.
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.dayMuted,
    required this.accent,
    required this.onAccent,
    required this.error,
    required this.errorContainer,
    required this.snackbar,
    required this.onSnackbar,
    required this.handle,
    required this.navBar,
  });

  /// Mockup colours.
  static const light = AppPalette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF4F4F5),
    surfaceHigh: Color(0xFFFFFFFF),
    outline: Color(0xFFE4E4E7),
    onSurface: Color(0xFF18181B),
    onSurfaceVariant: Color(0xFF52525B),
    dayMuted: Color(0xFF71717A),
    accent: Color(0xFFC2410C),
    onAccent: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    errorContainer: Color(0xFFFCE8E6),
    snackbar: Color(0xFF27272A),
    onSnackbar: Color(0xFFFAFAFA),
    handle: Color(0xFFC4C4CA),
    navBar: Color(0xE6FFFFFF),
  );

  /// Dark counterpart with the same hierarchy.
  static const dark = AppPalette(
    background: Color(0xFF0E0E10),
    surface: Color(0xFF1C1C1F),
    surfaceHigh: Color(0xFF232327),
    outline: Color(0xFF2C2C31),
    onSurface: Color(0xFFF4F4F5),
    onSurfaceVariant: Color(0xFFB4B4BC),
    dayMuted: Color(0xFF8E8E98),
    accent: Color(0xFFF06A2B),
    onAccent: Color(0xFFFFFFFF),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF3A1714),
    snackbar: Color(0xFFE4E4E7),
    onSnackbar: Color(0xFF18181B),
    handle: Color(0xFF4A4A52),
    navBar: Color(0xD9232327),
  );

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color outline;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color dayMuted;
  final Color accent;
  final Color onAccent;
  final Color error;
  final Color errorContainer;
  final Color snackbar;
  final Color onSnackbar;
  final Color handle;

  /// Translucent fill of the floating bottom bar.
  final Color navBar;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      outline: c(outline, other.outline),
      onSurface: c(onSurface, other.onSurface),
      onSurfaceVariant: c(onSurfaceVariant, other.onSurfaceVariant),
      dayMuted: c(dayMuted, other.dayMuted),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      error: c(error, other.error),
      errorContainer: c(errorContainer, other.errorContainer),
      snackbar: c(snackbar, other.snackbar),
      onSnackbar: c(onSnackbar, other.onSnackbar),
      handle: c(handle, other.handle),
      navBar: c(navBar, other.navBar),
    );
  }
}

/// Theme-independent colours.
abstract final class AppColors {
  static const photoScrim = Color(0x8C000000);
  static const scrim = Color(0x52000000);
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

  /// Height of the floating bottom bar plus its margin.
  static const navBarClearance = 96.0;
}

/// Shared animation timings.
abstract final class AppMotion {
  static const short = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const long = Duration(milliseconds: 520);
  static const curve = Curves.easeOutCubic;
}

/// Text sizes of the mockup's type scale; colour comes from the theme.
abstract final class AppText {
  static const appTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );
  static const screenTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );
  static const month = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const headline = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.2,
  );
  static const body = TextStyle(fontSize: 16);
  static const label = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const section = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );
  static const weekday = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.22,
  );
}

/// Palette of the current theme; the light palette outside an app theme.
extension AppPaletteContext on BuildContext {
  /// Colours for the active brightness.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

RoundedRectangleBorder _rounded(double radius) =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

/// Builds the light or dark theme.
ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    surface: p.background,
    onSurface: p.onSurface,
    onSurfaceVariant: p.onSurfaceVariant,
    surfaceContainerHighest: p.surface,
    secondaryContainer: p.accent.withValues(alpha: 0.16),
    onSecondaryContainer: p.onSurface,
    outline: p.dayMuted,
    outlineVariant: p.outline,
    error: p.error,
    errorContainer: p.errorContainer,
    surfaceTint: Colors.transparent,
  );
  const buttonSize = Size(0, 44);
  // Root styles (app bar title, buttons, SnackBar) are not merged with the
  // ambient text style, so they take the platform font from the typography.
  final type = Typography.material2021(platform: defaultTargetPlatform);
  final base = brightness == Brightness.dark ? type.white : type.black;
  final label = base.labelLarge!.merge(AppText.label);
  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    extensions: [p],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(
          allowEnterRouteSnapshotting: false,
        ),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      titleTextStyle: base.titleMedium!
          .merge(AppText.screenTitle)
          .copyWith(color: p.onSurface),
    ),
    dividerTheme: DividerThemeData(color: p.outline, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surfaceHigh,
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
      backgroundColor: p.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      insetPadding: const EdgeInsets.symmetric(horizontal: 39, vertical: 24),
      shape: _rounded(AppDimens.dialogRadius),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        minimumSize: buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: _rounded(AppDimens.buttonRadius),
        textStyle: label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.onSurfaceVariant,
        minimumSize: buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: _rounded(AppDimens.buttonRadius),
        textStyle: label,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: p.accent,
        selectedForegroundColor: p.onAccent,
        foregroundColor: p.onSurface,
        backgroundColor: p.surface,
        side: BorderSide(color: p.outline),
        textStyle: label,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onAccent : p.dayMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.surface,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? Colors.transparent : p.dayMuted,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.snackbar,
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: _rounded(AppDimens.snackbarRadius),
      elevation: 6,
      contentTextStyle: base.bodyMedium!.merge(
        TextStyle(fontSize: 14, height: 1.43, color: p.onSnackbar),
      ),
    ),
  );
}
