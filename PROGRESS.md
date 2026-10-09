# PROGRESS — OnePhoto MVP

Ortam: Windows 11, Flutter 3.47.5 (stable) / Dart 3.13.4, Android SDK 36. Bağlı Android cihaz/emülatör **yok** → manuel kontrol listesi maddeleri "doğrulanmadı (cihaz yok)". iOS build macOS gerektirir → doğrulanmadı.

| Aşama | Durum | Commit |
|---|---|---|
| 1. Kurulum | ✅ | (bu commit) |
| 2. Çekirdek mantık | ⏳ | |
| 3. Veri katmanı | ⏳ | |
| 4. Zaman çizelgesi UI | ⏳ | |
| 5. Ekleme akışları | ⏳ | |
| 6. Gün detayı | ⏳ | |
| 7. Hatırlatma | ⏳ | |
| 8. Cila ve teslim | ⏳ | |

## Aşama 1 — Kurulum
Kriterler:
- `flutter create --org com.muratefecamoglu --project-name one_photo_app --platforms android,ios .`
- `.gitignore` içinden `*.lock` kaldırıldı → `pubspec.lock` izleniyor.
- Onaylı paketler eklendi (image_picker, path_provider, path, sqflite, shared_preferences, flutter_local_notifications, timezone, flutter_timezone, intl, flutter_localizations; dev: flutter_lints, sqflite_common_ffi). `cupertino_icons` kaldırıldı (V15).
- `analysis_options.yaml` = `flutter_lints`.
- §4 klasörleri oluşturuldu; uygulama adı "OnePhoto" (Android label, iOS CFBundleName/DisplayName).
- Platform ayarları: minSdk 24, desugaring + bildirim alıcıları (flutter_local_notifications dokümanı), `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, iOS izin metinleri (F8c), AppDelegate bildirim delegesi, dikey yön (V16). iOS hedefi 15.0 (V14).
Test: `test/app_test.dart` (Türkçe locale). `flutter run` → cihaz yok, doğrulanmadı; yerine `flutter build apk --debug`.

Doğrulama: format ✅, analyze "No issues found" ✅, test 1/1 ✅, `flutter build apk --debug` ✅.
