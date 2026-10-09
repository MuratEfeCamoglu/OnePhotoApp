import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/ui/settings/settings_screen.dart';

void main() {
  testWidgets('shows the title and the storage notice (F6g)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    expect(find.text(Strings.settingsTitle), findsOneWidget);
    expect(
      find.text(
        'Fotoğraflar sadece bu cihazda saklanır; uygulamayı silersen kaybolur.',
      ),
      findsOneWidget,
    );
  });
}
