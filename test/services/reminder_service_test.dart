import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late TestHarness h;
  setUp(() async => h = await TestHarness.create());
  tearDown(() => h.dispose());

  test('defaults to off at 20:00 (F7a)', () {
    expect(h.reminders.enabled, isFalse);
    expect(h.reminders.minutes, 1200);
  });

  test('enable asks permission and schedules at the stored time', () async {
    expect(await h.reminders.enable(), isTrue);
    expect(h.scheduler.permissionRequests, 1);
    expect(h.scheduler.scheduledMinutes, 1200);
    expect(h.settings.reminderEnabled, isTrue);
  });

  test('refused permission keeps the reminder off (F7b)', () async {
    h.scheduler.grant = false;
    expect(await h.reminders.enable(), isFalse);
    expect(h.scheduler.scheduledMinutes, isNull);
    expect(h.settings.reminderEnabled, isFalse);
  });

  test('disable cancels and persists off', () async {
    await h.reminders.enable();
    await h.reminders.disable();
    expect(h.scheduler.cancels, 1);
    expect(h.scheduler.scheduledMinutes, isNull);
    expect(h.settings.reminderEnabled, isFalse);
  });

  test('setTime reschedules only while enabled', () async {
    await h.reminders.setTime(9 * 60);
    expect(h.scheduler.scheduledMinutes, isNull);
    expect(h.settings.reminderMinutes, 540);

    await h.reminders.enable();
    await h.reminders.setTime(21 * 60 + 15);
    expect(h.scheduler.scheduledMinutes, 1275);
  });

  test('restore reschedules a stored "on" setting (F7e)', () async {
    await h.reminders.restore();
    expect(h.scheduler.scheduledMinutes, isNull);

    await h.settings.setReminderEnabled(true);
    await h.settings.setReminderMinutes(480);
    await h.reminders.restore();
    expect(h.scheduler.scheduledMinutes, 480);
  });
}
