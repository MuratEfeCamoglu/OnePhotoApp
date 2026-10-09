import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'state/appearance_controller.dart';
import 'ui/widgets/l10n.dart';

/// Root widget: theme mode and language follow [appearance].
class OnePhotoApp extends StatelessWidget {
  /// Creates the app with an already wired [home] screen.
  const OnePhotoApp({
    super.key,
    required this.home,
    this.appearance,
    this.navigatorKey,
  });

  /// First screen shown (the timeline in production).
  final Widget home;

  /// Theme and language source; light Turkish when `null` (tests).
  final AppearanceController? appearance;

  /// Lets non-widget code (notification taps) reach the navigator.
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final appearance = this.appearance;
    if (appearance == null) return _build(ThemeMode.light, null);
    return ListenableBuilder(
      listenable: appearance,
      builder: (context, _) => _build(appearance.themeMode, appearance.locale),
    );
  }

  Widget _build(ThemeMode mode, Locale? locale) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'OnePhoto',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      themeAnimationDuration: AppMotion.medium,
      themeAnimationCurve: AppMotion.curve,
      locale: locale ?? const Locale('tr', 'TR'),
      supportedLocales: StringsDelegate.supportedLocales,
      localizationsDelegates: const [
        StringsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: home,
    );
  }
}
