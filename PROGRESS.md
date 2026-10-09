# PROGRESS — OnePhoto MVP

Ortam: Windows 11, Flutter 3.47.5 (stable) / Dart 3.13.4, Android SDK 36. Bağlı Android cihaz/emülatör **yok** → manuel kontrol listesi maddeleri "doğrulanmadı (cihaz yok)". iOS build macOS gerektirir → doğrulanmadı.

| Aşama | Durum | Commit |
|---|---|---|
| 1. Kurulum | ✅ | 29a3b78 |
| 2. Çekirdek mantık | ✅ | b1b0c45 |
| 3. Veri katmanı | ✅ | b5e8aaa |
| 4. Zaman çizelgesi UI | ✅ | 6476121 |
| 5. Ekleme akışları | ✅ | 8ee82f9 |
| 6. Gün detayı | ✅ | (bu commit) |
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

## Aşama 4 — Zaman çizelgesi UI (F1, F6e, F6g)
Kriterler → kanıt:
- F1a aylar yeniden eskiye: `timeline_controller_test` (months.first = bugünün ayı), `timeline_screen_test` kaydırma.
- F1b aralık: 12 ay / eski kayda kadar → `calendar_test`, `timeline_controller_test`, ekranda Kasım 2025 son ay.
- F1c "Ekim 2026" başlığı → `month_grid_test`.
- F1d 7 sütun, Pazartesi başlangıç, 1'i doğru sütun → `month_grid_test` x-konum kontrolü, haftalık başlık Pzt→Paz.
- F1e küçük resim + gün no; boş gün gri no; gelecek %40 ve dokunulamaz; bugün çerçeve → `day_cell_test`, `month_grid_test`.
- F1f boş durum mesajı ızgaranın üstünde, 12 ay yine var → `timeline_screen_test`.
- F1g başlık "OnePhoto", kamera ve ayarlar ikonları; ayarlar ekranı açılır → `timeline_screen_test`.
- 3 kayıt → 3 küçük resim hücresi; dosyası olmayan kayıt kırık-resim ikonu (F6e) → `timeline_screen_test`, `day_cell_test`.
- F6g bilgi metni → `settings_screen_test`.
- Performans: `Image.file(cacheWidth: 200)` (test ile kontrol), `ListView.builder` ile tembel aylar.
Ek dosya: `ui/widgets/error_snackbar.dart` (F8 mesaj eşlemesi; açılış hataları SnackBar ile gösterilir).
Doğrulama: format ✅, analyze ✅, 94/94 test ✅. Manuel: doğrulanmadı (cihaz yok).

## Aşama 5 — Ekleme akışları (F2, F3, F4, F8)
Kriterler → kanıt:
- F2a kamera ikonu sistem kamerasını açar → `timeline_screen_test` (FakePhotoPicker.cameraCalls).
- F2b onaylanan fotoğraf bugünün hücresinde küçük resim → `timeline_screen_test` (aynı frame'de görünür; gerçek cihazda 1 sn süresi: doğrulanmadı, cihaz yok).
- F2c iptal → veri değişmez → `photo_service_test`, `timeline_controller_test`, `timeline_screen_test`.
- F3a boş hücre → "Fotoğraf çek / Galeriden seç / Vazgeç" sayfası → `photo_source_sheet_test`, `timeline_screen_test`.
- F3b seçilen fotoğraf dokunulan güne yazılır (EXIF yok sayılır) → `timeline_screen_test`, `photo_service_test`.
- F3c kamera ikonu her zaman bugün → `timeline_screen_test` (2026-10-09).
- F4b dolu güne ekleme onay sorar, "Vazgeç" hiçbir şey değiştirmez → `add_photo_flow_test`, `timeline_screen_test`.
- F4c değiştirme sonrası tek dosya kalır → `add_photo_flow_test`, `photo_service_test`.
- F8a izin reddi SnackBar, çökme yok → `add_photo_flow_test`, `error_snackbar_test`.
- F8b kayıt hatası SnackBar + yarım dosya silinir → `add_photo_flow_test`, `photo_service_test`.
- F8c Info.plist Türkçe izin metinleri → Aşama 1'de eklendi (`ios/Runner/Info.plist`).
Karar: Onay, picker açılmadan **önce** sorulur (kamera ikonu: onay → kamera; hücre/Değiştir: sayfa → onay → picker). Böylece "Vazgeç" hiçbir dosya üretmez (V17).
Not: Android'de manifestte `CAMERA` izni olmadığı için sistem kamerası izin istemez; izin reddi pratikte iOS'ta oluşur.
Ek dosya: `ui/widgets/add_photo_flow.dart` (+ test).
Doğrulama: format ✅, analyze ✅, 111/111 test ✅. Manuel kontrol: doğrulanmadı (cihaz yok).

## Aşama 6 — Gün detayı (F5)
Kriterler → kanıt (`day_detail_screen_test`):
- F5a fotoğraflı hücre → tam ekran detay, "9 Ekim 2026, Cuma" başlığı, `BoxFit.contain`, `InteractiveViewer` 1x–4x, tam boy decode (cacheWidth yok).
- F5b "Değiştir" → seçenek sayfası → F4b onayı → fotoğraf değişir, tek dosya kalır.
- F5c "Sil" onay ister; onayda kayıt + dosya silinir, ana ekrana dönülür, hücre boş. "Vazgeç" hiçbir şeyi değiştirmez.
- Ek: dosyası olmayan kayıtta detay kırık-resim ikonu gösterir (F6e).
Doğrulama: format ✅, analyze ✅, 117/117 test ✅. Manuel (iki parmak yakınlaştırma): doğrulanmadı (cihaz yok).
