/// Every user-visible text in the app (Turkish only, ISKELET §5).
abstract final class Strings {
  static const appTitle = 'OnePhoto';
  static const emptyTimeline = 'İlk fotoğrafını ekle';
  static const weekdaysShort = [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];

  static const takePhoto = 'Fotoğraf çek';
  static const pickFromGallery = 'Galeriden seç';
  static const cancel = 'Vazgeç';

  static const replaceQuestion = 'Bu günün fotoğrafı değiştirilsin mi?';
  static const replace = 'Değiştir';
  static const deleteQuestion = 'Bu günün fotoğrafı silinsin mi?';
  static const delete = 'Sil';

  static const cameraTooltip = 'Bugünün fotoğrafını çek';
  static const settingsTooltip = 'Ayarlar';
  static const settingsTitle = 'Ayarlar';
  static const reminderTitle = 'Günlük hatırlatma';
  static const reminderTimePrefix = 'Saat: ';
  static const storageInfo =
      'Fotoğraflar sadece bu cihazda saklanır; uygulamayı silersen kaybolur.';
  static const notificationPermissionDenied = 'Bildirim izni verilmedi';
  static const reminderFailed = 'Hatırlatma ayarlanamadı, tekrar dene.';

  /// "Saat: 20:00" for [minutes] after midnight.
  static String reminderTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$reminderTimePrefix$h:$m';
  }

  static const reminderNotificationTitle = 'OnePhoto';
  static const reminderNotificationBody = 'Bugünün fotoğrafını ekledin mi?';
  static const reminderChannelName = 'Günlük hatırlatma';
  static const reminderChannelDescription =
      'Her gün seçilen saatte fotoğraf hatırlatması';

  static const cameraPermissionDenied =
      'Kamera izni gerekli. Ayarlar > OnePhoto üzerinden izin verebilirsin.';
  static const photosPermissionDenied =
      'Galeri izni gerekli. Ayarlar > OnePhoto üzerinden izin verebilirsin.';
  static const photoSaveFailed = 'Fotoğraf kaydedilemedi, tekrar dene.';
  static const brokenPhoto = 'Fotoğraf bulunamadı';

  static const demoDataButton = '365 günlük demo veri üret';
  static const demoDataNeedsEntry = 'Önce en az bir fotoğraf ekle.';
  static const demoDataDone = 'Demo veri üretildi.';
}
