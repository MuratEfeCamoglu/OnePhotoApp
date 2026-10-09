import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/app.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/ui/settings/settings_screen.dart';

import '../../fakes.dart';
import '../pump.dart';

void main() {
  late TestHarness h;
  setUp(() async => h = await TestHarness.create());
  tearDown(() => h.dispose());

  Future<void> pumpSettings(
    WidgetTester tester, {
    Future<int?> Function()? demo,
  }) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      OnePhotoApp(
        home: SettingsScreen(reminders: h.reminders, onGenerateDemoData: demo),
      ),
    );
  }

  bool switchValue(WidgetTester tester) => tester
      .widget<Switch>(find.byKey(const ValueKey('reminder-switch')))
      .value;

  testWidgets('shows the storage notice (F6g)', (tester) async {
    await pumpSettings(tester);
    expect(find.text(Strings.settingsTitle), findsOneWidget);
    expect(
      find.text(
        'Fotoğraflar sadece bu cihazda saklanır; uygulamayı silersen kaybolur.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('reminder is off at 20:00 by default (F7a)', (tester) async {
    await pumpSettings(tester);
    expect(find.text(Strings.reminderTitle), findsOneWidget);
    expect(switchValue(tester), isFalse);
    expect(find.text('Saat: 20:00'), findsOneWidget);
  });

  testWidgets('turning on with permission schedules the reminder', (
    tester,
  ) async {
    await pumpSettings(tester);
    await tester.tap(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();
    expect(switchValue(tester), isTrue);
    expect(h.scheduler.scheduledMinutes, 1200);
  });

  testWidgets('refused permission flips back off with a message (F7b)', (
    tester,
  ) async {
    h.scheduler.grant = false;
    await pumpSettings(tester);
    await tester.tap(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();
    expect(switchValue(tester), isFalse);
    expect(find.text('Bildirim izni verilmedi'), findsOneWidget);
  });

  testWidgets('turning off cancels the reminder', (tester) async {
    await h.reminders.enable();
    await pumpSettings(tester);
    expect(switchValue(tester), isTrue);
    await tester.tap(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();
    expect(switchValue(tester), isFalse);
    expect(h.scheduler.cancels, 1);
  });

  testWidgets('scheduling failure shows a message instead of crashing', (
    tester,
  ) async {
    h.scheduler.error = Exception('platform');
    await pumpSettings(tester);
    await tester.tap(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();
    expect(find.text(Strings.reminderFailed), findsOneWidget);
  });

  testWidgets('time picker is Turkish and stores the chosen time (F7g)', (
    tester,
  ) async {
    await pumpSettings(tester);
    await tester.tap(find.byKey(const ValueKey('reminder-time')));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(find.text('Tamam'), findsOneWidget);
    expect(find.text('İptal'), findsOneWidget);

    // Switch to keyboard entry and type 07:30.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '07');
    await tester.enterText(fields.at(1), '30');
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    expect(h.settings.reminderMinutes, 450);
    expect(find.text('Saat: 07:30'), findsOneWidget);
  });

  testWidgets('settings survive a rebuild from stored values (F7e)', (
    tester,
  ) async {
    await h.settings.setReminderEnabled(true);
    await h.settings.setReminderMinutes(1305);
    await pumpSettings(tester);
    expect(switchValue(tester), isTrue);
    expect(find.text('Saat: 21:45'), findsOneWidget);
  });

  testWidgets('no demo tool without a generator', (tester) async {
    await pumpSettings(tester);
    expect(find.text(Strings.demoDataButton), findsNothing);
  });

  testWidgets('demo tool (debug builds) reports success', (tester) async {
    var calls = 0;
    await pumpSettings(tester, demo: () async => ++calls);
    await tester.tap(find.text('365 günlük demo veri üret'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text(Strings.demoDataDone), findsOneWidget);
  });

  testWidgets('demo tool asks for a first photo when there is none', (
    tester,
  ) async {
    await pumpSettings(tester, demo: () async => null);
    await tester.tap(find.text(Strings.demoDataButton));
    await tester.pumpAndSettle();
    expect(find.text(Strings.demoDataNeedsEntry), findsOneWidget);
  });
}
