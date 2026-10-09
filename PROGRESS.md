# PROGRESS — OnePhoto MVP

Ortam: Windows 11, Flutter 3.47.5 (stable) / Dart 3.13.4, Android SDK 36. Bağlı Android cihaz/emülatör **yok** → manuel kontrol listesi maddeleri "doğrulanmadı (cihaz yok)". iOS build macOS gerektirir → doğrulanmadı.

| Aşama | Durum | Commit |
|---|---|---|
| 1. Kurulum | ✅ | 29a3b78 |
| 2. Çekirdek mantık | ✅ | b1b0c45 |
| 3. Veri katmanı | ✅ | b5e8aaa |
| 4. Zaman çizelgesi UI | ✅ | 6476121 |
| 5. Ekleme akışları | ✅ | 8ee82f9 |
| 6. Gün detayı | ✅ | e1825df |
| 7. Hatırlatma | ✅ | cd94bcc |
| 8. Cila ve teslim | ✅ | 584ab9a |

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

## Aşama 7 — Hatırlatma (F7)
Kriterler → kanıt:
- F7a anahtar + saat seçici, varsayılan kapalı / 20:00 → `settings_screen_test`, `settings_store_test`, `reminder_service_test`.
- F7b açınca izin istenir; red → anahtar kapalıya döner + "Bildirim izni verilmedi" → `settings_screen_test`, `reminder_service_test`.
- F7c her gün seçilen saatte "Bugünün fotoğrafını ekledin mi?" → `LocalNotificationScheduler.scheduleDaily` (`zonedSchedule`, `DateTimeComponents.time`, `inexactAllowWhileIdle`). Gerçek teslim: doğrulanmadı (cihaz yok).
- F7d bildirime dokununca ana ekran → uygulama açılışı zaman çizelgesidir; açıkken dokunulursa `navigatorKey.popUntil(isFirst)`. Doğrulanmadı (cihaz yok).
- F7e ayar yeniden başlatmada korunur → `settings_store_test`, `settings_screen_test` ("settings survive…"), açılışta `ReminderService.restore()`.
- F7f yeniden başlatma sonrası → `RECEIVE_BOOT_COMPLETED` + `ScheduledNotificationBootReceiver` (Aşama 1). Doğrulanmadı (cihaz yok).
- F7g saat seçici Türkçe ("Tamam/İptal"), 24 saat → `settings_screen_test`. Test, klavye modunda "07"nin 19 okunduğu bir Flutter tutarsızlığını yakaladı; seçici `alwaysUse24HourFormat: true` ile sarıldı.
Hata durumu: zamanlama hatası "Hatırlatma ayarlanamadı, tekrar dene." SnackBar'ı.
Doğrulama: format ✅, analyze ✅, 131/131 test ✅.

## Aşama 8 — Cila ve teslim
- Uygulama ikonu: varsayılan Flutter ikonu (ISKELET izin veriyor).
- Demo veri: Ayarlar'da `!kReleaseMode` iken "365 günlük demo veri üret" → `PhotoService.fillDemoDays` en yeni mevcut fotoğrafı kopyalayarak son 365 günün boşlarını doldurur. Testler: `photo_service_test` (364 gün doldurur, mevcut kaydı korur, fotoğraf yoksa null), `timeline_controller_test`, `settings_screen_test`.
- 365 kayıtta tembel oluşturma: `timeline_screen_test` (< 4 MonthGrid oluşturulur).
- Açılış iyileştirmesi: saat dilimi veritabanı + bildirim eklentisi başlatması `runApp` sonrasına alındı; zamanlayıcı çağrıları hazır olmayı bekler.
- `flutter build apk --release` ✅; birleştirilmiş release manifestinde `INTERNET` yok ✅.
- README: §1 ölçütleri ölçüm yöntemi ve sonuçlarıyla yazıldı.

### Cihazda yapılan elle kontroller (Xiaomi Poco X3 NFC, Android 12, profile APK)
Emülatör (AVD "Efe") açıldı ama ölçüm başlamadan kapandı; bu sırada USB ile fiziksel cihaz bağlandı ve kontroller onunla yapıldı. Cihaz bağlantısı ölçümün ortasında kesildi.
- [x] Hiç kayıt yokken boş durum metni, Türkçe ay başlıkları, Pazartesi başlangıç, bugün çerçevesi, gelecek günler soluk (F1).
- [x] Kamera ikonu → sistem kamerası doğrudan açılır (F2a).
- [x] Kamerayı iptal et: hiçbir şey değişmez (F2c).
- [x] Kamera → deklanşör → onay: bugünün hücresinde ≤1,5 sn içinde küçük resim, toplam 3 dokunuş (F2b, §1).
- [x] Ayarlar ikonu Ayarlar'ı açar; bilgi metni, hatırlatma anahtarı (kapalı), "Saat: 20:00" görünür (F1g, F6g, F7a).
- [x] Demo veri 365 günü doldurur; ızgara küçük resimlerle görünür.
- [x] 365 kayıtla soğuk açılış `TotalTime`: 1539/1056/1093/1013/1031 ms (cihaz yeniden bağlandıktan sonra, iyileştirme öncesi APK; ilk turda 2096/1568 ms).
- [x] Uygulamayı tamamen kapat-aç: tüm kayıtlar yerinde (F6c).
- [x] Gelecek güne dokunmak hiçbir şey açmaz (F1e).
- [x] Fotoğraflı hücre → detay "8 Ekim 2026, Perşembe", Değiştir/Sil (F5a); Sil → onay → kayıt silinir, ana ekrana dönülür, hücre boş (F5c).
- [x] Boş güne dokun → "8 Ekim 2026" başlıklı Fotoğraf çek / Galeriden seç / Vazgeç sayfası (F3a).
- [x] Dolu bugünde kamera ikonu → "Bu günün fotoğrafı değiştirilsin mi?" onayı (F4b).
- [x] Saat seçici Türkçe ("Saat seçin", İptal/Tamam) ve 24 saat (F7g).
- [ ] Doğrulanmadı: galeriden seçme (kişisel galeriye dokunmamak için), iki parmakla yakınlaştırma, izin reddi, bildirimin gelmesi ve dokunma, cihaz yeniden başlatma, uçak modu. İyileştirilmiş APK kurulamadı (MIUI USB kurulumunu iptal etti, "INSTALL_FAILED_USER_RESTRICTED").

Doğrulama: format ✅, analyze ✅, 138/138 test ✅.

## Görsel uyum — onephoto-mockup.html
Mockup baştan sona okunup ekran ekran karşılaştırıldı; farklar düzeltildi:
- Tema: tüm renk/yarıçap/yazı belirteçleri `core/theme.dart` (`AppColors`, `AppDimens`, `AppText`); M3 tonlaması kapatıldı (beyaz diyalog/alt sayfa), %32 karartma, buton yarıçapı 22, SnackBar yarıçapı 8 ve `#FAFAFA` yazı, anahtar (switch) renkleri.
- Zaman çizelgesi: dolgulu kamera/ayar ikonları, başlık -0.02em, hafta günü satırı 11 semibold `#52525B` + 6px aralık + alt ayraç, ay başlığı 24/12 boşluk.
- Hücre: bugün çerçevesi hücrenin 1px dışında (outline-offset) ve kalın numara; gölge alttan %70'e; gün no. gölgesi %50; dolgulu kırık-resim ikonu.
- Boş durum: kesik çizgili gri kart + turuncu daire içinde kamera + 16 semibold metin; dokununca bugünün kamerası açılır.
- Alt sayfa: 28 yarıçap, 32×4 tutamaç, ortalanmış başlık, 56px satırlar, ortalanmış "Vazgeç" metin butonu.
- Diyalog: beyaz, 28 yarıçap, 24 iç boşluk, başlık 20 semibold.
- Gün detayı: beyaz zemin, 17 semibold başlık, alt kısımda gri "Değiştir" ve açık kırmızı "Sil" butonları (48px, 20px ikon).
- Ayarlar: ikonsuz 64px satırlar, ayraç, saat satırında `›`, gri bilgi kartı (14px, 1.45 satır yüksekliği).
İyileştirmeler: küçük resimler 220 ms'de yumuşak belirir; hücreden detaya Hero geçişi.
Cihazda (Poco X3, yeni profile APK) ekran görüntüleriyle doğrulandı: zaman çizelgesi, alt sayfa, detay, değiştirme diyaloğu, ayarlar. Boş durum kartı cihazda görülmedi (veri dolu); widget testiyle kapsandı.
365 kayıtla soğuk açılış (yeni APK): 1061/1047/1195/1045/1134 ms.
Doğrulama: format ✅, analyze ✅, 141/141 test ✅.

## Uygulama simgesi
- Yeni simge: turuncu (`#C2410C` → `#9A3412`) gradyan zemin, yarı saydam 3×3 takvim hücreleri, ortada beyaz "bugün" hücresi içinde güneş + dağ fotoğraf motifi.
- Android: `mipmap-*/ic_launcher.png` (API 24–25, yuvarlatılmış kare), adaptif simge `mipmap-anydpi-v26/ic_launcher.xml` = gradyan `drawable/ic_launcher_background.xml` + `mipmap-*/ic_launcher_foreground.png` (motif 66dp güvenli alanın içinde).
- iOS: `AppIcon.appiconset` içindeki 15 PNG, opak ve tam kare (köşe maskesini iOS uygular).
- Paket eklenmedi; PNG'ler geliştirme makinesinde Pillow betiğiyle üretildi (V18).
- Release APK derlendi ve telefona kuruldu; simge uygulama çekmecesinde doğrulandı.

## Modern görünüm, koyu tema (F9), dil (F10)
Referans: kullanıcının eklediği "One Photo / Day App" ekran görüntüsü (alt yüzen gezinme çubuğu).
- **Alt gezinme:** buzlu cam efektli (blur) yüzen hap çubuk: ana sayfa (en üste kaydırır) / gradyanlı kamera (bugün) / ayarlar. `ui/widgets/floating_nav_bar.dart`.
- **Başlık:** büyük "OnePhoto" + slogan, kaydırınca 32→22 px küçülür, slogan katlanarak kaybolur; hafta günü satırı sabit (`SliverPersistentHeader`).
- **Animasyonlar:** ayların ve ayar bölümlerinin sırayla belirmesi (`EntranceAnimation`, zamanlayıcısız), basınca küçülme (`PressScale`), yeni/değişen fotoğrafın hücrede ölçekli belirmesi (`AnimatedSwitcher`), küçük resimlerin yumuşak yüklenmesi, hücre→detay Hero, Android'de zoom sayfa geçişi, tema değişiminde renk geçişi.
- **Koyu tema (F9):** `AppPalette` ThemeExtension (açık = mockup, koyu karşılığı); Ayarlar > Görünüm: Sistem / Açık / Koyu; `shared_preferences` `theme`.
- **Dil (F10):** `Strings` artık dile göre (Türkçe/English), `StringsDelegate` + `context.strings`; ay/gün adları ve tarih biçimi `intl` ile dile göre; Material diyalogları (saat seçici) dile göre; açık hatırlatma bildirimi dil değişince yeni dilde yeniden kurulur. `shared_preferences` `language`.
- Yeni dosyalar: `state/appearance_controller.dart`, `ui/widgets/l10n.dart`, `ui/widgets/motion.dart`, `ui/widgets/floating_nav_bar.dart` (+ testleri), `test/core/strings_test.dart`.
- ISKELET: F1g güncellendi, F9 ve F10 eklendi, V19–V20.
Doğrulama: format ✅, analyze ✅, 173/173 test ✅, `flutter build apk --release` ✅, telefona kuruldu. Cihazda ekran kontrolü: telefon kilitli olduğu için bekliyor.

## Gün önizlemesi + not (F11), görünüm düzeltmeleri
- **Önizleme:** fotoğraflı güne dokununca kare fotoğraflı kart (Hero ile hücreden büyür), tarih, not alanı (500 karakter), "Tam ekran" ve "Kaydet". Kaydet / geri / kart dışına dokunma notu kaydeder; boş not silinir. Klavye açılınca fotoğraf 120 px'e küçülür. `ui/day_detail/day_preview.dart`.
- **Not:** `Entry.note`, şema v2 (`note TEXT`, eklemeli geçiş), `PhotoService.saveNote`, `TimelineController.updateNote`; fotoğraf değişince not korunur; hücrede not rozeti; tam ekran detayda not kartı.
- **Türkçe büyük harf hatası:** Ayarlar bölüm başlıkları `toUpperCase()` ile "DIL" oluyordu; büyük harfe çevirme kaldırıldı.
- **Telefondaki siyah kareler:** test sırasında karanlıkta çekilen 9 Ekim fotoğrafı ve "demo veri" butonunun ürettiği 362 birebir kopyası (md5 `2d4515…`) telefondan silindi. Kullanıcının 1 ve 2 Ekim fotoğrafları korundu. Silmeden önce veritabanı yedeği alındı (scratchpad `one_photo_backup.db`). Gerçek cihazda v1→v2 şema geçişi doğrulandı.
- Cihazda doğrulandı (Poco X3): alt çubuk, koyu tema, İngilizce, önizleme kartı, not yazma + geri tuşuyla kaydetme, not rozeti.
Doğrulama: format ✅, analyze ✅, 196/196 test ✅.

## Kategoriler (F12)
- 16 kategori, her birinin simgesi ve rengi var: Yemek, Manzara, Seyahat, Aile, Arkadaşlar, Evcil hayvan, Doğa, Spor, İş, Okul, Kutlama, Aşk, Ev, Sanat, Müzik, Ben (İngilizce adlarıyla). `core/categories.dart`, `ui/widgets/category_style.dart`.
- Seçim: fotoğraf eklenince açılan kartta ve gün önizlemesinde yatay kayan çipler; tek seçim, seçili çipe dokunmak kaldırır.
- Gösterim: hücrede sol üstte renkli, simgeli rozet; tam ekran detayda kategori çipi.
- Veri: `Entry.category`, şema v3 (`category TEXT`, eklemeli geçiş), `PhotoService.saveDetails`, `TimelineController.updateDetails`; fotoğraf değişince kategori korunur.
Doğrulama: format ✅, analyze ✅, 221/221 test ✅.
