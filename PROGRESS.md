# PROGRESS — OnePhoto MVP

Ortam: Windows 11, Flutter 3.47.5 (stable) / Dart 3.13.4, Android SDK 36. Bağlı Android cihaz/emülatör **yok** → manuel kontrol listesi maddeleri "doğrulanmadı (cihaz yok)". iOS build macOS gerektirir → doğrulanmadı.

| Aşama | Durum | Commit |
|---|---|---|
| 1. Kurulum | ✅ | 29a3b78 |
| 2. Çekirdek mantık | ✅ | b1b0c45 |
| 3. Veri katmanı | ✅ | (bu commit) |
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

## Aşama 2 — Çekirdek mantık
Kriterler → testler:
- Ay başı hafta günü hizası (≥3 ay): `calendar_test` Ekim 2026 (Per, 3 boşluk), Haziran 2026 (Pzt), Mart 2026 (Paz, 6 boşluk), 2026'nın 12 ayının tamamı.
- Artık yıl: 2028-02 = 29 gün (+2100 değil, 2000 artık).
- Ay aralığı: kayıt yok → 12 ay; 2 yıl önceki kayıt → 25 ay, yeniden eskiye.
- Gün anahtarı biçimi `YYYY-MM-DD`, 23:59/00:00 sınırları, UTC girişi yerel güne çevrilir.
- Türkçe ay adları ("Ocak 2026", "Şubat 2026"), uzun tarih "9 Ekim 2026, Cuma".
Dosyalar: `lib/core/date_key.dart`, `lib/core/calendar.dart`, `lib/data/entry.dart` + testleri.
Doğrulama: format ✅, analyze ✅, test 32/32 ✅.

## Aşama 3 — Veri katmanı
Kriterler → testler:
- upsert aynı gün için tek satır (F4a): `sqflite_entry_repository_test` (ffi, in-memory).
- Değiştirme sonrası eski dosya silinir, sıra yeni dosya → DB → eski (F4c): `photo_service_test` "replacing deletes the old file…".
- DB hatasında yeni dosya silinir, eski kayıt/dosya korunur (F8b): "DB failure deletes the new file…"; kopyalama hatası: "file copy failure…".
- delete satırı ve dosyayı kaldırır (F5c).
- Yetim temizliği sadece referanssız dosyaları siler (F6f).
- 23:59 / 00:00 `Clock` değerleri doğru güne yazılır.
- Ek: iptal hiçbir şeyi değiştirmez (F2c), galeri dokunulan güne yazar (F3b), `pending_date_key` picker açıkken saklanır ve kurtarma bu güne yazar (§7), izin reddi veri değiştirmez (F8a), DB kapat-aç sonrası kayıtlar korunur (F6c), kopya orijinal silinince de durur (F6a).
Dosyalar: `entry_repository.dart`, `sqflite_entry_repository.dart`, `photo_storage.dart`, `services/photo_picker.dart` (muaf, sahtesi `test/fakes.dart`), `services/settings_store.dart` (pending anahtarı burada gerektiği için Aşama 3'te eklendi), `services/photo_service.dart`.
Doğrulama: format ✅, analyze ✅, tüm testler ✅.
