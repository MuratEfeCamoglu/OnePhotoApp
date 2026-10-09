import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/services/settings_store.dart';
import 'package:one_photo_app/state/appearance_controller.dart';

import '../fakes.dart';

void main() {
  late TestHarness h;
  setUp(() async => h = await TestHarness.create());
  tearDown(() => h.dispose());

  test('defaults: system theme, Turkish', () {
    expect(h.appearance.themePreference, ThemePreference.system);
    expect(h.appearance.themeMode, ThemeMode.system);
    expect(h.appearance.language, AppLanguage.tr);
    expect(h.appearance.strings, same(Strings.tr));
    expect(h.appearance.locale, const Locale('tr', 'TR'));
  });

  test('theme change notifies and persists (F9)', () async {
    var notified = 0;
    h.appearance.addListener(() => notified++);
    await h.appearance.setThemePreference(ThemePreference.dark);
    expect(h.appearance.themeMode, ThemeMode.dark);
    expect(notified, 1);
    expect(h.settings.themePreference, ThemePreference.dark);

    final reloaded = AppearanceController(settings: h.settings);
    expect(reloaded.themeMode, ThemeMode.dark);
  });

  test('same value does not notify', () async {
    var notified = 0;
    h.appearance.addListener(() => notified++);
    await h.appearance.setThemePreference(ThemePreference.system);
    await h.appearance.setLanguage(AppLanguage.tr);
    expect(notified, 0);
  });

  test('language change persists and switches texts (F10)', () async {
    await h.appearance.setLanguage(AppLanguage.en);
    expect(h.appearance.strings, same(Strings.en));
    expect(h.appearance.locale, const Locale('en', 'US'));
    expect(h.settings.language, AppLanguage.en);
    expect(AppearanceController(settings: h.settings).language, AppLanguage.en);
  });

  test(
    'language change reschedules an active reminder in that language',
    () async {
      await h.reminders.enable();
      expect(h.scheduler.scheduledStrings, same(Strings.tr));
      await h.appearance.setLanguage(AppLanguage.en);
      expect(h.scheduler.scheduledStrings, same(Strings.en));
      expect(h.scheduler.scheduledMinutes, 1200);
    },
  );

  test('language change leaves a disabled reminder off', () async {
    await h.appearance.setLanguage(AppLanguage.en);
    expect(h.scheduler.scheduledMinutes, isNull);
  });
}
