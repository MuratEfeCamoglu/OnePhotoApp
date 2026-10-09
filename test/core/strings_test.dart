import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/strings.dart';

void main() {
  test('every language has seven weekdays starting on Monday', () {
    expect(Strings.tr.weekdaysShort, hasLength(7));
    expect(Strings.en.weekdaysShort, hasLength(7));
    expect(Strings.tr.weekdaysShort.first, 'Pzt');
    expect(Strings.en.weekdaysShort.first, 'Mon');
  });

  test('of() and fromCode() pick the language, Turkish by default', () {
    expect(Strings.of(AppLanguage.en).language, AppLanguage.en);
    expect(AppLanguage.fromCode('en'), AppLanguage.en);
    expect(AppLanguage.fromCode(null), AppLanguage.tr);
    expect(AppLanguage.fromCode('xx'), AppLanguage.tr);
    expect(AppLanguage.tr.localeName, 'tr_TR');
  });

  test('reminder time is zero padded in both languages', () {
    expect(Strings.tr.reminderTime(450), 'Saat: 07:30');
    expect(Strings.en.reminderTime(1200), 'Time: 20:00');
  });

  test('Turkish texts keep the ISKELET wording', () {
    expect(Strings.tr.emptyTimeline, 'İlk fotoğrafını ekle');
    expect(Strings.tr.photoSaveFailed, 'Fotoğraf kaydedilemedi, tekrar dene.');
    expect(
      Strings.tr.reminderNotificationBody,
      'Bugünün fotoğrafını ekledin mi?',
    );
  });
}
