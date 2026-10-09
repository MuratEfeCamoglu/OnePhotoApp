import 'package:shared_preferences/shared_preferences.dart';

import '../core/strings.dart';

/// Light/dark choice; `system` follows the device (ISKELET F9).
enum ThemePreference { system, light, dark }

/// Typed access to the app's shared_preferences keys (ISKELET §3).
class SettingsStore {
  /// Wraps an initialised [SharedPreferences].
  SettingsStore(this._prefs);

  /// Default reminder time: 20:00 as minutes after midnight.
  static const defaultReminderMinutes = 20 * 60;

  static const _reminderEnabled = 'reminder_enabled';
  static const _reminderMinutes = 'reminder_minutes';
  static const _pendingDateKey = 'pending_date_key';
  static const _theme = 'theme';
  static const _language = 'language';

  final SharedPreferences _prefs;

  /// Whether the daily reminder is on; off by default.
  bool get reminderEnabled => _prefs.getBool(_reminderEnabled) ?? false;

  /// Persists [value] for [reminderEnabled].
  Future<void> setReminderEnabled(bool value) =>
      _prefs.setBool(_reminderEnabled, value);

  /// Reminder time as minutes after midnight.
  int get reminderMinutes =>
      _prefs.getInt(_reminderMinutes) ?? defaultReminderMinutes;

  /// Persists [minutes] for [reminderMinutes].
  Future<void> setReminderMinutes(int minutes) =>
      _prefs.setInt(_reminderMinutes, minutes);

  /// Target day of a picker session that has not finished yet.
  String? get pendingDateKey => _prefs.getString(_pendingDateKey);

  /// Stores [dateKey], or removes the key when `null`.
  Future<void> setPendingDateKey(String? dateKey) => dateKey == null
      ? _prefs.remove(_pendingDateKey)
      : _prefs.setString(_pendingDateKey, dateKey);

  /// Theme choice; follows the system by default.
  ThemePreference get themePreference => ThemePreference.values.firstWhere(
    (t) => t.name == _prefs.getString(_theme),
    orElse: () => ThemePreference.system,
  );

  /// Persists [value] for [themePreference].
  Future<void> setThemePreference(ThemePreference value) =>
      _prefs.setString(_theme, value.name);

  /// UI language; Turkish by default.
  AppLanguage get language => AppLanguage.fromCode(_prefs.getString(_language));

  /// Persists [value] for [language].
  Future<void> setLanguage(AppLanguage value) =>
      _prefs.setString(_language, value.code);
}
