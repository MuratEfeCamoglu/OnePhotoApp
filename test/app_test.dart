import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/app.dart';

void main() {
  testWidgets('app uses the Turkish locale', (tester) async {
    await tester.pumpWidget(const OnePhotoApp(home: Text('home')));
    final context = tester.element(find.text('home'));
    expect(Localizations.localeOf(context), const Locale('tr', 'TR'));
  });
}
