/// Languages the UI can be shown in (ISKELET F10).
enum AppLanguage {
  tr('tr', 'TR', 'Türkçe'),
  en('en', 'US', 'English');

  const AppLanguage(this.code, this.country, this.nativeName);

  /// ISO 639-1 language code.
  final String code;

  /// Country used for date formatting.
  final String country;

  /// Name of the language in itself; shown the same in every UI language.
  final String nativeName;

  /// `intl` locale name, e.g. `tr_TR`.
  String get localeName => '${code}_$country';

  /// Language for a stored [code]; Turkish when unknown.
  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.tr);
}

/// Every user-visible text in the app, one implementation per language.
abstract class Strings {
  const Strings();

  /// Turkish texts (default).
  static const Strings tr = _TrStrings();

  /// English texts.
  static const Strings en = _EnStrings();

  /// Texts of [language].
  static Strings of(AppLanguage language) => switch (language) {
    AppLanguage.tr => tr,
    AppLanguage.en => en,
  };

  /// Language these texts belong to.
  AppLanguage get language;

  // Date patterns for `intl` (ISKELET F1c, F5a).
  String get monthPattern;
  String get longDatePattern;
  String get shortDatePattern;

  String get appTitle => 'OnePhoto';
  String get appSubtitle;
  String get emptyTimeline;
  List<String> get weekdaysShort;

  String get takePhoto;
  String get pickFromGallery;
  String get cancel;

  String get replaceQuestion;
  String get replace;
  String get deleteQuestion;
  String get delete;

  String get homeTooltip;
  String get cameraTooltip;
  String get settingsTooltip;
  String get settingsTitle;

  String get appearanceSection;
  String get themeSystem;
  String get themeLight;
  String get themeDark;
  String get languageSection;

  String get reminderSection;
  String get reminderTitle;
  String get reminderTimePrefix;
  String get storageInfo;
  String get notificationPermissionDenied;
  String get reminderFailed;
  String get reminderNotificationTitle => appTitle;
  String get reminderNotificationBody;
  String get reminderChannelName;
  String get reminderChannelDescription;

  String get cameraPermissionDenied;
  String get photosPermissionDenied;
  String get photoSaveFailed;

  String get demoDataButton;
  String get demoDataNeedsEntry;
  String get demoDataDone;

  /// "Saat: 20:00" for [minutes] after midnight.
  String reminderTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$reminderTimePrefix$h:$m';
  }
}

class _TrStrings extends Strings {
  const _TrStrings();

  @override
  AppLanguage get language => AppLanguage.tr;
  @override
  String get monthPattern => 'MMMM y';
  @override
  String get longDatePattern => 'd MMMM y, EEEE';
  @override
  String get shortDatePattern => 'd MMMM y';

  @override
  String get appSubtitle => 'Hayatın, günde tek kare.';
  @override
  String get emptyTimeline => 'İlk fotoğrafını ekle';
  @override
  List<String> get weekdaysShort => const [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];

  @override
  String get takePhoto => 'Fotoğraf çek';
  @override
  String get pickFromGallery => 'Galeriden seç';
  @override
  String get cancel => 'Vazgeç';

  @override
  String get replaceQuestion => 'Bu günün fotoğrafı değiştirilsin mi?';
  @override
  String get replace => 'Değiştir';
  @override
  String get deleteQuestion => 'Bu günün fotoğrafı silinsin mi?';
  @override
  String get delete => 'Sil';

  @override
  String get homeTooltip => 'Ana sayfa';
  @override
  String get cameraTooltip => 'Bugünün fotoğrafını çek';
  @override
  String get settingsTooltip => 'Ayarlar';
  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get appearanceSection => 'Görünüm';
  @override
  String get themeSystem => 'Sistem';
  @override
  String get themeLight => 'Açık';
  @override
  String get themeDark => 'Koyu';
  @override
  String get languageSection => 'Dil';

  @override
  String get reminderSection => 'Hatırlatma';
  @override
  String get reminderTitle => 'Günlük hatırlatma';
  @override
  String get reminderTimePrefix => 'Saat: ';
  @override
  String get storageInfo =>
      'Fotoğraflar sadece bu cihazda saklanır; uygulamayı silersen kaybolur.';
  @override
  String get notificationPermissionDenied => 'Bildirim izni verilmedi';
  @override
  String get reminderFailed => 'Hatırlatma ayarlanamadı, tekrar dene.';
  @override
  String get reminderNotificationBody => 'Bugünün fotoğrafını ekledin mi?';
  @override
  String get reminderChannelName => 'Günlük hatırlatma';
  @override
  String get reminderChannelDescription =>
      'Her gün seçilen saatte fotoğraf hatırlatması';

  @override
  String get cameraPermissionDenied =>
      'Kamera izni gerekli. Ayarlar > OnePhoto üzerinden izin verebilirsin.';
  @override
  String get photosPermissionDenied =>
      'Galeri izni gerekli. Ayarlar > OnePhoto üzerinden izin verebilirsin.';
  @override
  String get photoSaveFailed => 'Fotoğraf kaydedilemedi, tekrar dene.';

  @override
  String get demoDataButton => '365 günlük demo veri üret';
  @override
  String get demoDataNeedsEntry => 'Önce en az bir fotoğraf ekle.';
  @override
  String get demoDataDone => 'Demo veri üretildi.';
}

class _EnStrings extends Strings {
  const _EnStrings();

  @override
  AppLanguage get language => AppLanguage.en;
  @override
  String get monthPattern => 'MMMM y';
  @override
  String get longDatePattern => 'EEEE, MMMM d, y';
  @override
  String get shortDatePattern => 'MMMM d, y';

  @override
  String get appSubtitle => 'Your life, one photo at a time.';
  @override
  String get emptyTimeline => 'Add your first photo';
  @override
  List<String> get weekdaysShort => const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  String get takePhoto => 'Take photo';
  @override
  String get pickFromGallery => 'Choose from gallery';
  @override
  String get cancel => 'Cancel';

  @override
  String get replaceQuestion => 'Replace this day\'s photo?';
  @override
  String get replace => 'Replace';
  @override
  String get deleteQuestion => 'Delete this day\'s photo?';
  @override
  String get delete => 'Delete';

  @override
  String get homeTooltip => 'Home';
  @override
  String get cameraTooltip => 'Take today\'s photo';
  @override
  String get settingsTooltip => 'Settings';
  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSection => 'Appearance';
  @override
  String get themeSystem => 'System';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get languageSection => 'Language';

  @override
  String get reminderSection => 'Reminder';
  @override
  String get reminderTitle => 'Daily reminder';
  @override
  String get reminderTimePrefix => 'Time: ';
  @override
  String get storageInfo =>
      'Photos are stored only on this device; they are lost if you delete '
      'the app.';
  @override
  String get notificationPermissionDenied => 'Notification permission denied';
  @override
  String get reminderFailed => 'Could not set the reminder, try again.';
  @override
  String get reminderNotificationBody => 'Did you add today\'s photo?';
  @override
  String get reminderChannelName => 'Daily reminder';
  @override
  String get reminderChannelDescription =>
      'Photo reminder every day at the chosen time';

  @override
  String get cameraPermissionDenied =>
      'Camera access is needed. You can allow it in Settings > OnePhoto.';
  @override
  String get photosPermissionDenied =>
      'Photo access is needed. You can allow it in Settings > OnePhoto.';
  @override
  String get photoSaveFailed => 'Photo could not be saved, try again.';

  @override
  String get demoDataButton => 'Generate 365 days of demo data';
  @override
  String get demoDataNeedsEntry => 'Add at least one photo first.';
  @override
  String get demoDataDone => 'Demo data generated.';
}
