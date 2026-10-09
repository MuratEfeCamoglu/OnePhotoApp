import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/strings.dart';
import 'core/theme.dart';

/// Root widget: Turkish locale, light theme and the given [home] screen.
class OnePhotoApp extends StatelessWidget {
  /// Creates the app with an already wired [home] screen.
  const OnePhotoApp({super.key, required this.home, this.navigatorKey});

  /// First screen shown (the timeline in production).
  final Widget home;

  /// Lets non-widget code (notification taps) reach the navigator.
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: Strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );
  }
}
