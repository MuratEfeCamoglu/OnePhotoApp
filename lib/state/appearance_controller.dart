import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../services/reminder_service.dart';
import '../services/settings_store.dart';

/// Theme and language choices; the app rebuilds when they change.
class AppearanceController extends ChangeNotifier {
  /// Loads the stored choices; [reminders] follows the language.
  AppearanceController({required this._settings, this._reminders})
    : _theme = _settings.themePreference,
      _language = _settings.language;

  final SettingsStore _settings;
  final ReminderService? _reminders;
  ThemePreference _theme;
  AppLanguage _language;

  /// Selected theme preference (ISKELET F9).
  ThemePreference get themePreference => _theme;

  /// [themePreference] as a Flutter [ThemeMode].
  ThemeMode get themeMode => switch (_theme) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  /// Selected UI language (ISKELET F10).
  AppLanguage get language => _language;

  /// Texts of [language].
  Strings get strings => Strings.of(_language);

  /// Locale for [language].
  Locale get locale => Locale(_language.code, _language.country);

  /// Changes and stores the theme.
  Future<void> setThemePreference(ThemePreference value) async {
    if (value == _theme) return;
    _theme = value;
    notifyListeners();
    await _settings.setThemePreference(value);
  }

  /// Changes and stores the language; reminder texts follow.
  Future<void> setLanguage(AppLanguage value) async {
    if (value == _language) return;
    _language = value;
    notifyListeners();
    await _settings.setLanguage(value);
    await _reminders?.setStrings(strings);
  }
}
