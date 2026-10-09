import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsStore> _store([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SettingsStore(await SharedPreferences.getInstance());
}

void main() {
  test('defaults: reminder off at 20:00, no pending day (F7a)', () async {
    final store = await _store();
    expect(store.reminderEnabled, isFalse);
    expect(store.reminderMinutes, 1200);
    expect(store.pendingDateKey, isNull);
  });

  test('reminder settings are saved and read back (F7e)', () async {
    final store = await _store();
    await store.setReminderEnabled(true);
    await store.setReminderMinutes(7 * 60 + 30);

    final prefs = await SharedPreferences.getInstance();
    final reloaded = SettingsStore(prefs);
    expect(reloaded.reminderEnabled, isTrue);
    expect(reloaded.reminderMinutes, 450);
    expect(prefs.getBool('reminder_enabled'), isTrue);
    expect(prefs.getInt('reminder_minutes'), 450);
  });

  test('pending day key can be set and cleared', () async {
    final store = await _store();
    await store.setPendingDateKey('2026-10-05');
    expect(store.pendingDateKey, '2026-10-05');
    await store.setPendingDateKey(null);
    expect(store.pendingDateKey, isNull);
  });

  test('reads existing stored values', () async {
    final store = await _store({
      'reminder_enabled': true,
      'reminder_minutes': 60,
      'pending_date_key': '2026-01-01',
    });
    expect(store.reminderEnabled, isTrue);
    expect(store.reminderMinutes, 60);
    expect(store.pendingDateKey, '2026-01-01');
  });
}
