# OnePhoto — One Photo a Day

## Proje
Kullanıcının her gün tek bir fotoğraf eklediği ve bunları ay ay takvim ızgarasında gösteren, tamamen çevrimdışı çalışan bir Android/iOS uygulaması.
- Kapsam, özellikler (F1–F8), kabul kriterleri, veri modeli, aşamalar: @ISKELET.md
- Agent yetkileri, yasaklar, çalışma döngüsü: @AGENT.md
- Çelişkide sıralama: ISKELET.md > CLAUDE.md > AGENT.md.

## Teknoloji Yığını
- Durum yönetimi: `ChangeNotifier` + `ListenableBuilder` (ek paket yok).
- Onaylı paket listesi (ISKELET §3) dışına çıkma (bkz. AGENT.md "Onay Gerektirenler").

## Komutlar
| İş | Komut |
|---|---|
| Performans ölçümü | `flutter run --profile` |
| iOS build (sadece macOS) | `flutter build ios --no-codesign` |
| Standart | `flutter pub get`, `flutter run`, `flutter test [dosya]`, `flutter analyze`, `dart format .`, `flutter build apk --debug\|--release` |

**Doğrulama üçlüsü** (her değişiklikten sonra, hepsi 0 hata/uyarı ile geçmeli):
```
dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test
```

## Kod Kuralları
- Klasör yapısı ISKELET §4 ile birebir aynıdır; yeni klasör açma, dosyayı uygun mevcut klasöre koy.
- Katman yönü: `ui → state → services → data → core` (aşağı doğru çağrı serbest, yukarı yasak). `core/` Flutter import etmez (saf Dart). `data/` ve `services/` `ui/` import etmez.
- Dosya adları `snake_case.dart`; sınıflar `PascalCase`; değişken/fonksiyon `camelCase`; private üyeler `_` ile.
- Her `lib/x/y.dart` için test dosyası `test/x/y_test.dart` (UI dahil, en az bir widget testi). Muaf: `main.dart`, `app.dart`, `core/strings.dart`, `core/theme.dart`, `core/clock.dart`, `core/errors.dart`, `data/entry_repository.dart` (soyut arayüz), `services/photo_picker.dart` (platform sarmalayıcısı; sahtesiyle test edilir).
- Gün anahtarı daima `String` `YYYY-MM-DD`, yalnızca `core/date_key.dart` üretir. Başka yerde `DateTime` → metin dönüşümü yazma; `toUtc()` kullanma.
- DB'ye mutlak yol yazma; sadece `file_name`. Yol çözümü `PhotoStorage` içinde.
- Kullanıcıya görünen her metin `lib/core/strings.dart` içinde; widget'ta sabit Türkçe metin yazma.
- Somut bağımlılıklar `main.dart`'ta oluşturulup kurucuyla aktarılır; global singleton / service locator yok.
- Hata yönetimi: `data/` ve `services/` beklenen hataları (izin reddi, I/O, DB) `core/errors.dart`'taki tipli istisnalar (`PhotoSaveException`, `PermissionDeniedException`) olarak fırlatır; `ui/` bunları yakalayıp `strings.dart`'taki mesajla SnackBar gösterir. `catch (_) {}` ile sessizce yutma.
- `print` yok; gerekirse `debugPrint`, ve sadece `kDebugMode` altında.
- Yorumlar "neden"i anlatır, "ne"yi değil. Açık API'lerde (`public` sınıf/metot) tek satırlık `///` doc yorumu.
- Widget'lar mümkün olduğunca `const`; build metodu ~80 satırı geçerse alt widget'a böl.

## Çalışma Kuralları
- Her görev ISKELET.md'deki bir özellik (F1–F8) veya aşamaya (1–8) bağlıdır; commit mesajında belirt.
- Her değişiklikten sonra doğrulama üçlüsünü çalıştır; kırmızıyken commit etme.
- Kapsam dışı (ISKELET §2) bir şey gerekiyor gibi görünürse uygulama; rapora "Açık nokta" olarak yaz.
- Commit formatı (Conventional Commits, İngilizce):
  `feat(timeline): render month grid (F1)` · `fix(data): delete old file after replace (F4)` · `test(core): leap year cases` · `chore: add packages`
- Küçük commit: bir commit = bir mantıksal değişiklik.

## Önemli Notlar / Tuzaklar
- **Saat dilimi:** gün anahtarı kayıt anında yerel saatle bir kez hesaplanır. `DateTime.now()` sadece `core/clock.dart`'taki `systemClock` içinde; diğer her yer kurucudan aldığı `Clock`'u kullanır ki sınır durumları (23:59, 00:00) test edilebilsin.
- **Türkçe yerelleştirme:** `main()` içinde `initializeDateFormatting('tr_TR')`; `MaterialApp`'e `locale: Locale('tr','TR')` ve `GlobalMaterialLocalizations` delegeleri (saat seçici/diyaloglar Türkçe olsun).
- **Kayıp picker sonucu (Android):** picker'ı açmadan önce hedef günü `pending_date_key` olarak sakla; açılışta `retrieveLostData()` ile kurtarılan fotoğrafı o güne yaz (ISKELET §3, §7).
- **`image_picker`'ı doğrudan çağırma:** yalnızca `services/photo_picker.dart` çağırır; diğer kod `PhotoPicker` arayüzünü kullanır ki testte sahtesi verilebilsin.
- **iOS yolu:** belge dizini yolu uygulama güncellemesinde değişir → yalnızca dosya adı sakla.
- **Değiştirme sırası:** yeni dosyayı yaz → DB'yi güncelle → eski dosyayı sil. Ters sıra veri kaybettirir.
- **Izgarada performans:** `Image.file(file, cacheWidth: 200)`; tam boy decode sadece detay ekranında.
- **iOS izin metinleri:** `ios/Runner/Info.plist` → `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` (Türkçe).
- **Android bildirimleri:** `POST_NOTIFICATIONS` çalışma anında istenir; `AndroidScheduleMode.inexactAllowWhileIdle` kullan (exact alarm izni ekleme).
- **Ağ yok:** HTTP paketi, analitik veya uzak URL'den görsel ekleme.
- **sqflite testleri:** `sqflite_common_ffi` ile `databaseFactoryFfi` + `inMemoryDatabasePath`; gerçek cihaz eklentisi testte çalışmaz.
- Ortam değişkeni / gizli anahtar yoktur; release imza dosyaları (`key.properties`, `*.jks`) `.gitignore`'dadır ve commit edilmez.
