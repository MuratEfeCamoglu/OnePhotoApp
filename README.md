# OnePhoto — One Photo a Day

Her gün tek bir fotoğraf ekle; fotoğraflar ay ay takvim ızgarasında görünsün. Tamamen çevrimdışı çalışan bir Flutter uygulaması (Android + iOS telefon). Hesap, sunucu, analitik ya da ağ isteği yoktur.

- Ürün tanımı, kabul kriterleri (F1–F8), mimari: [ISKELET.md](ISKELET.md)
- Kod kuralları ve komutlar: [CLAUDE.md](CLAUDE.md) · Agent sözleşmesi: [AGENT.md](AGENT.md)
- Aşama aşama ilerleme ve doğrulama kaydı: [PROGRESS.md](PROGRESS.md)

## Özellikler

| # | Özellik |
|---|---|
| F1 | Zaman çizelgesi: en yeni ay üstte, Pazartesi başlayan 7 sütunlu ızgara, en az son 12 ay |
| F2 | Kamera ikonu → bugünün fotoğrafı |
| F3 | Boş güne dokun → "Fotoğraf çek / Galeriden seç / Vazgeç" |
| F4 | Günde tek fotoğraf; değiştirmeden önce onay |
| F5 | Gün detayı: 1x–4x yakınlaştırma, değiştir, sil |
| F6 | Fotoğraflar uygulamanın `photos/` klasörüne kopyalanır; DB'de yalnızca dosya adı |
| F7 | Günlük hatırlatma bildirimi (varsayılan kapalı, 20:00) |
| F8 | İzin ve kayıt hatalarında Türkçe SnackBar |

## Geliştirme

Gereksinimler: Flutter stable ≥ 3.35 (geliştirmede 3.47.5 kullanıldı), Android SDK; iOS için macOS + Xcode.

```bash
flutter pub get
flutter run                      # debug
flutter run --profile            # performans ölçümü
dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test
flutter build apk --release
```

Debug ve profile derlemelerinde Ayarlar ekranında **"365 günlük demo veri üret"** butonu bulunur: en az bir fotoğraf varken o fotoğrafı kopyalayarak son 365 günün boş günlerini doldurur. Release derlemede görünmez.

## Başarı ölçütleri (ISKELET §1)

Ölçüm tarihi: 2026-10-09. Cihaz: Xiaomi Poco X3 NFC (M2007J20CG, Android 12, orta seviye), profile APK.

| Ölçüt | Hedef | Sonuç | Yöntem |
|---|---|---|---|
| Bugünün fotoğrafı (bugün boşken) | ≤ 3 dokunuş | ✅ **3 dokunuş**: kamera ikonu → deklanşör → kameranın onay butonu; küçük resim ≤ 1,5 sn içinde bugünün hücresinde | Cihazda `adb` ile adım adım + ekran görüntüsü; widget testi `timeline_screen_test` |
| 365 fotoğrafla soğuk açılış → ilk ekran | ≤ 2 sn | ✅ **1045–1195 ms** (son APK, 5 ölçüm: 1061, 1047, 1195, 1045, 1134). Açılış iyileştirmesinden önceki APK: 1013–2096 ms | `adb shell am force-stop …; adb shell am start -W …` → `TotalTime` |
| Ağ isteği yok | Release manifestte `INTERNET` yok | ✅ Yok. İzinler: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE` (+ eklentinin iç `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`) | `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml` |
| Yalnızca onaylı paketler | ISKELET §3 listesi | ✅ `pubspec.yaml`: image_picker, path_provider, path, sqflite, shared_preferences, flutter_local_notifications, timezone, flutter_timezone, intl, flutter_localizations; dev: flutter_lints, sqflite_common_ffi | `pubspec.yaml` |

Soğuk açılış notu: saat dilimi veritabanı ve bildirim eklentisi artık ilk kareden sonra yükleniyor (bildirim çağrıları hazır olmasını bekler). Yeniden ölçmek için:

```bash
flutter build apk --profile && adb install -r build/app/outputs/flutter-apk/app-profile.apk
# Ayarlar > "365 günlük demo veri üret" (önce bir fotoğraf ekle)
adb shell am force-stop com.muratefecamoglu.one_photo_app
adb shell am start -W -n com.muratefecamoglu.one_photo_app/.MainActivity   # TotalTime (ms)
```
