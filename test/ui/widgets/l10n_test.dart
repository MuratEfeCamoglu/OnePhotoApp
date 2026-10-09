import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/strings.dart';
import 'package:one_photo_app/ui/widgets/l10n.dart';

void main() {
  const delegate = StringsDelegate();

  test('supports Turkish and English only', () {
    expect(delegate.isSupported(const Locale('tr')), isTrue);
    expect(delegate.isSupported(const Locale('en', 'GB')), isTrue);
    expect(delegate.isSupported(const Locale('de')), isFalse);
  });

  test('loads the matching texts', () async {
    expect(await delegate.load(const Locale('en')), same(Strings.en));
    expect(await delegate.load(const Locale('tr')), same(Strings.tr));
  });

  for (final (locale, expected) in [
    (const Locale('tr', 'TR'), 'Ayarlar'),
    (const Locale('en', 'US'), 'Settings'),
  ]) {
    testWidgets('context.strings follows the app locale $locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: StringsDelegate.supportedLocales,
          localizationsDelegates: const [
            delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Builder(
            builder: (context) => Text(context.strings.settingsTitle),
          ),
        ),
      );
      expect(find.text(expected), findsOneWidget);
    });
  }

  testWidgets('falls back to Turkish without the delegate', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) => Text(context.strings.delete)),
      ),
    );
    expect(find.text('Sil'), findsOneWidget);
  });
}
