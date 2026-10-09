import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/app.dart';
import 'package:one_photo_app/ui/settings/settings_screen.dart';
import 'package:one_photo_app/ui/timeline/timeline_screen.dart';

import '../fakes.dart';

/// Phone-sized surface (360×780 logical) so a whole month is visible.
void usePhoneSurface(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Pumps the timeline wired to [h] and runs the controller startup.
Future<void> pumpTimeline(
  WidgetTester tester,
  TestHarness h, {
  WidgetBuilder? settingsBuilder,
}) async {
  usePhoneSurface(tester);
  await tester.pumpWidget(
    OnePhotoApp(
      appearance: h.appearance,
      home: TimelineScreen(
        controller: h.controller,
        settingsBuilder:
            settingsBuilder ??
            (_) => SettingsScreen(
              reminders: h.reminders,
              appearance: h.appearance,
            ),
      ),
    ),
  );
  await h.controller.startup();
  await tester.pumpAndSettle();
}
