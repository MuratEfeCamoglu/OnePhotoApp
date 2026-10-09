# One Photo a Day — Proje İskeleti ve Sınırları

> Bu dosya projenin **tek doğruluk kaynağıdır**: ne yapılıyor, ne yapılmıyor, ne zaman "bitti" denir.
> Teknoloji/komut/kod kuralları için `CLAUDE.md`, agent davranışı için `AGENT.md`.
> Dosyalar çelişirse sıralama: **ISKELET.md > CLAUDE.md > AGENT.md**.

## 1. Amaç ve Hedef Kullanıcı

- **Sorun:** İnsanlar her gün çok fotoğraf çekiyor ama "o gün nasıldı" sorusuna bakılacak düzenli, gün gün bir kayıt yok. Galeri karmaşık; bir günü temsil eden tek kare kayboluyor.
- **Çözüm:** Kullanıcı her gün **tek bir fotoğraf** ekler; uygulama bunları ay ay takvim ızgarasında gösteren görsel bir yaşam zaman çizelgesi oluşturur.
- **Hedef kullanıcı:** Günlük tutma / anı biriktirme alışkanlığı kazanmak isteyen, akıllı telefon kullanan bireyler (tek kullanıcı, tek cihaz). Teknik bilgi gerektirmez.
- **Başarı ölçütleri (MVP):**
  - Bugün henüz fotoğraf yokken, uygulama açıldıktan sonra bugünün fotoğrafı **en fazla 3 dokunuşla** kaydedilir (kamera ikonu → deklanşör → kameranın onay butonu).
  - 365 fotoğraflı veride zaman çizelgesi, profile modda soğuk açılıştan itibaren **≤ 2 sn** içinde ilk ekranı gösterir.
  - Uygulama hiçbir koşulda ağ isteği yapmaz (tüm veri cihazda kalır). Ölçüm: release APK'nın birleştirilmiş manifestinde (`build/app/intermediates/merged_manifests/release/**/AndroidManifest.xml`) `android.permission.INTERNET` bulunmaz ve `pubspec.yaml` yalnızca §3'teki onaylı paketleri içerir.

## 2. Kapsam

### Kapsam İçi (MVP)

Terimler: **Gün anahtarı** = cihazın yerel saat dilimine göre `YYYY-MM-DD` metni. **Bugün** = cihaz yerel saatine göre bugünün gün anahtarı. **Kayıt (Entry)** = bir güne bağlı tek fotoğraf.

| # | Özellik | Öncelik | Kabul Kriteri |
|---|---|---|---|
| F1 | **Zaman çizelgesi (ana ekran)** | Zorunlu | (a) Aylar yeniden eskiye, üstte en yeni ay olacak şekilde dikey listelenir. (b) Gösterilen aralık: `min(ilk kaydın ayı, bugünün ayı − 11 ay)` → bugünün ayı. (c) Her ay başlığı Türkçe "Ocak 2026" biçimindedir. (d) Her ay 7 sütunlu ızgaradır, hafta **Pazartesi** başlar, ayın 1'i doğru hafta gününe hizalanır. (e) Fotoğrafı olan gün, köşeleri yuvarlatılmış küçük resim + üzerinde gün numarası; olmayan gün sadece gri gün numarası; gelecek günler %40 opaklıkta ve dokunulamaz; bugün belirgin bir çerçeveyle işaretlidir. (f) Hiç kayıt yokken ızgaranın üstünde "İlk fotoğrafını ekle" yazan boş durum mesajı görünür (ızgara yine (b)'deki 12 ayı gösterir). (g) Üst çubukta başlık "OnePhoto", sağda kamera ikonu (F2) ve ayarlar ikonu (Ayarlar ekranını açar) bulunur. |
| F2 | **Bugünün fotoğrafını kameradan çek** | Zorunlu | (a) Ana ekran üst çubuğundaki kamera ikonuna basınca sistem kamerası açılır. (b) Onaylanan fotoğraf bugünün kaydı olarak kaydedilir ve ekrana dönüldüğünde bugünün hücresinde **1 sn içinde** küçük resim görünür. (c) Kullanıcı kamerayı iptal ederse hiçbir veri değişmez. |
| F3 | **Galeriden fotoğraf seç** | Zorunlu | (a) Boş bir geçmiş/bugün hücresine dokununca alttan "Fotoğraf çek / Galeriden seç / Vazgeç" seçenekli bir sayfa açılır. (b) Seçilen fotoğraf **dokunulan günün** kaydı olur (fotoğrafın EXIF tarihi dikkate alınmaz). (c) Kamera ikonu her zaman **bugün** içindir; hücre seçimi o hücrenin günü içindir. |
| F4 | **Günde tek fotoğraf kuralı** | Zorunlu | (a) Bir gün anahtarı için veritabanında en fazla 1 kayıt bulunur (birincil anahtar = gün anahtarı). (b) Fotoğrafı olan bir güne yeni fotoğraf eklenmek istenirse "Bu günün fotoğrafı değiştirilsin mi?" onayı çıkar; "Vazgeç" seçilirse hiçbir şey değişmez. (c) Değiştirmede yeni dosya yazılıp kayıt güncellendikten **sonra** eski dosya silinir; işlem sonunda `photos/` klasöründe o güne ait tek dosya kalır. |
| F5 | **Gün detayı** | Zorunlu | (a) Fotoğraflı hücreye dokununca tam ekran detay açılır: fotoğraf (sığdırılmış, iki parmakla 1x–4x yakınlaştırma), üstte "9 Ekim 2026, Cuma" biçiminde tarih. (b) "Değiştir" eylemi F3'teki seçenek sayfasını açar ve F4(b) onayını uygular. (c) "Sil" eylemi onay ister; onaylanınca kayıt ve dosya silinir, ana ekrana dönülür ve hücre boş görünür. |
| F6 | **Kalıcı ve çevrimdışı saklama** | Zorunlu | (a) Fotoğraflar uygulamanın belge dizini altında `photos/` klasörüne kopyalanır; galerideki orijinal silinse bile uygulamadaki kopya görünmeye devam eder. (b) Veritabanında **sadece dosya adı** saklanır, mutlak yol saklanmaz (iOS konteyner yolu güncellemelerde değişir). (c) Uygulama kapatılıp açıldığında tüm kayıtlar aynen görünür. (d) Kaydedilen fotoğrafın uzun kenarı ≤ 2048 px, JPEG kalite 85'tir. (e) Dosyası diskte bulunmayan kayıt, uygulamayı çökertmez; hücrede kırık-resim ikonu gösterilir. (f) Açılışta, DB'de hiçbir kaydın referans vermediği `photos/` dosyaları silinir (yetim temizliği). (g) Ayarlar ekranında "Fotoğraflar sadece bu cihazda saklanır; uygulamayı silersen kaybolur." bilgi metni görünür. |
| F7 | **Günlük hatırlatma bildirimi** | Önemli (süre aşılırsa ilk ertelenecek özellik) | (a) Ayarlar ekranında açık/kapalı anahtarı ve saat seçici vardır; varsayılan **kapalı**, varsayılan saat **20:00**. (b) Açıldığında bildirim izni istenir; izin reddedilirse anahtar kapalıya döner ve "Bildirim izni verilmedi" mesajı görünür. (c) Açıkken her gün seçilen saatte (Android'de ±15 dk sapma kabul) "Bugünün fotoğrafını ekledin mi?" yerel bildirimi gelir. (d) Bildirime dokunmak uygulamayı ana ekranda açar. (e) Ayar uygulama yeniden başlatıldığında korunur. (f) Cihaz yeniden başlatıldıktan sonra da bildirim gelmeye devam eder. (g) Saat seçici ve sistem diyalogları Türkçe görünür. |
| F8 | **İzin ve hata durumları** | Zorunlu | (a) Kamera/galeri izni reddedilirse uygulama çökmez; "Kamera izni gerekli. Ayarlar > OnePhoto üzerinden izin verebilirsin." biçiminde SnackBar gösterilir. (b) Dosya yazma veya veritabanı hatasında "Fotoğraf kaydedilemedi, tekrar dene." SnackBar'ı gösterilir ve yarım kalan dosya silinir. (c) iOS `Info.plist` içinde `NSCameraUsageDescription` ve `NSPhotoLibraryUsageDescription` Türkçe açıklamalarla tanımlıdır. |

### Sonraki Sürümler (MVP sonrası, şimdi yapılmayacak)
- Fotoğrafa kısa not / ruh hali ekleme.
- Seri (streak) sayacı ve istatistikler.
- Yedekleme / dışa aktarma (ZIP), iCloud / Google Drive senkronizasyonu.
- Fotoğraflardan timelapse video veya kolaj üretme.
- Fotoğraf çekildiyse o günün hatırlatmasını atlama (akıllı hatırlatma).
- Çoklu dil desteği (İngilizce), açık/koyu tema seçimi, ana ekran widget'ı.
- Uygulama kilidi (PIN / biyometrik).

### Kapsam Dışı (yapılmayacak)
- **Kullanıcı hesabı, giriş, sunucu/backend** — tek cihaz kişisel günlük; backend maliyet ve gizlilik yükü getirir.
- **Sosyal özellikler** (paylaşım akışı, takip, beğeni) — ürün özel bir günlüktür.
- **Günde birden fazla fotoğraf veya video** — ürünün temel kuralını bozar.
- **Uygulama içi fotoğraf düzenleme/filtre** — sistem araçları yeterli; kapsamı şişirir.
- **Reklam, analitik, crash-reporting SDK'ları** — "hiç ağ isteği yok" ilkesini bozar.
- **Web, masaüstü, tablet'e özel düzen** — sadece Android + iOS telefon.

## 3. Mimari

- **Genel yaklaşım:** Tek Flutter uygulaması, tamamen yerel (offline-first, backend yok). Katmanlar: `ui` → `state` → `services` → `data` → `core`. Üst katman alttakini (bir veya daha fazla seviye aşağı) çağırabilir, tersi yasak.
- **Ana bileşenler:**
  - `core/date_key.dart` → `DateTime` ↔ gün anahtarı (`YYYY-MM-DD`) dönüşümü, Türkçe tarih biçimleme. Saat dilimi: daima cihaz yereli. Fonksiyonlar `DateTime.now()` çağırmaz, `DateTime` parametresi alır.
  - `core/clock.dart` → `typedef Clock = DateTime Function();` ve `systemClock`. "Bugün" ihtiyacı olan her sınıf (`PhotoService`, `TimelineController`, ekranlar) kurucuda `Clock` alır; testlerde sabit zaman verilir.
  - `core/errors.dart` → Tipli istisnalar: `PhotoSaveException`, `PermissionDeniedException`.
  - `core/calendar.dart` → Bir ay için 7 sütunlu ızgara hücre listesini (baştaki boşluklar dahil) ve gösterilecek ay aralığını üretir. Saf Dart, UI bağımsız.
  - `data/entry_repository.dart` → `EntryRepository` soyut arayüzü: `getAll()`, `getByDate(dateKey)`, `upsert(entry)`, `delete(dateKey)`.
  - `data/sqflite_entry_repository.dart` → Arayüzün sqflite uygulaması.
  - `data/photo_storage.dart` → Seçilen dosyayı `photos/` altına kopyalar, dosya adından `File` çözer, dosya siler.
  - `services/photo_service.dart` → Akış orkestrasyonu: picker'dan dosya al → kopyala → repo'ya yaz → eskisini sil; hata halinde geri al (F4c, F8b). Açılışta yetim temizliğini yapar (F6f). Picker açılmadan önce hedef gün anahtarını `pending_date_key` olarak saklar; Android'de etkinlik öldürülürse açılışta `ImagePicker.retrieveLostData()` ile kurtarılan fotoğrafı bu güne yazar, sonra anahtarı siler.
  - `services/photo_picker.dart` → `PhotoPicker` soyut arayüzü (`pickFromCamera()`, `pickFromGallery()`, `retrieveLost()`; hepsi `Future<File?>`, iptalde `null`) ve `image_picker` kullanan `ImagePickerPhotoPicker` uygulaması (`maxWidth/maxHeight: 2048`, `imageQuality: 85`). İzin reddini `PermissionDeniedException`'a çevirir.
  - `services/settings_store.dart` → shared_preferences üzerinden hatırlatma ayarları ve `pending_date_key`.
  - `services/reminder_service.dart` → flutter_local_notifications ile günlük bildirimi kurar/iptal eder.
  - `state/timeline_controller.dart` → `ChangeNotifier`; tüm kayıtları `Map<String, Entry>` olarak tutar, ekle/değiştir/sil sonrası dinleyicileri bilgilendirir.
  - `ui/` → Ekranlar ve widget'lar: `TimelineScreen`, `DayDetailScreen`, `SettingsScreen`, `PhotoSourceSheet`.
- **Bağımlılık enjeksiyonu:** `main.dart` somut sınıfları oluşturur ve kurucu parametreleriyle aşağı iletir; global singleton yok. Testlerde sahte uygulamalar (ör. `FakeEntryRepository`, `FakePhotoPicker`) verilir; `image_picker` yalnızca `services/photo_picker.dart` içinde çağrılır.
- **Navigasyon:** Navigator 1.0 (`MaterialPageRoute`). Ekranlar: Timeline (ana) → DayDetail, Timeline → Settings.
- **Veri modeli:**

  `entries` tablosu (sqflite, veritabanı dosyası `one_photo.db`, şema sürümü 1):

  | Sütun | Tip | Kural |
  |---|---|---|
  | `date_key` | TEXT | PRIMARY KEY, `YYYY-MM-DD` |
  | `file_name` | TEXT | NOT NULL, örn. `2026-10-09_1760000000000.jpg` |
  | `created_at` | INTEGER | NOT NULL, epoch ms (kaydın ilk oluşturulması) |
  | `updated_at` | INTEGER | NOT NULL, epoch ms (son değiştirme) |

  Dart modeli: `Entry { String dateKey; String fileName; DateTime createdAt; DateTime updatedAt; }` — değişmez (immutable), `toMap()` / `fromMap()` içerir.

  Ayarlar (shared_preferences): `reminder_enabled: bool` (varsayılan `false`), `reminder_minutes: int` (gece yarısından itibaren dakika, varsayılan `1200` = 20:00), `pending_date_key: String?` (açık bir picker işleminin hedef günü; işlem bitince silinir).

  İlişki: 1 gün anahtarı → 0..1 Entry → 1 dosya.
- **Dış bağımlılıklar (onaylı paket listesi):** `image_picker`, `path_provider`, `path`, `sqflite`, `shared_preferences`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `intl`, `flutter_localizations` (Flutter SDK'dan); geliştirme: `flutter_lints`, `sqflite_common_ffi`. Bu liste dışı paket eklemek onay gerektirir (bkz. AGENT.md). Ağ API'si yoktur.

## 4. Klasör Yapısı

```
OnePhotoApp/
├── CLAUDE.md
├── ISKELET.md
├── AGENT.md
├── README.md
├── pubspec.yaml
├── pubspec.lock              # commit edilir
├── analysis_options.yaml
├── android/                  # flutter create üretir
├── ios/                      # flutter create üretir
├── lib/
│   ├── main.dart             # bağımlılıkları kurar, runApp
│   ├── app.dart              # MaterialApp, tema, locale (tr_TR), localizationsDelegates
│   ├── core/
│   │   ├── clock.dart
│   │   ├── date_key.dart
│   │   ├── errors.dart
│   │   ├── calendar.dart
│   │   ├── strings.dart      # tüm kullanıcıya görünen metinler
│   │   └── theme.dart
│   ├── data/
│   │   ├── entry.dart
│   │   ├── entry_repository.dart
│   │   ├── sqflite_entry_repository.dart
│   │   └── photo_storage.dart
│   ├── services/
│   │   ├── photo_picker.dart
│   │   ├── photo_service.dart
│   │   ├── settings_store.dart
│   │   └── reminder_service.dart
│   ├── state/
│   │   └── timeline_controller.dart
│   └── ui/
│       ├── timeline/
│       │   ├── timeline_screen.dart
│       │   ├── month_grid.dart
│       │   └── day_cell.dart
│       ├── day_detail/
│       │   └── day_detail_screen.dart
│       ├── settings/
│       │   └── settings_screen.dart
│       └── widgets/
│           └── photo_source_sheet.dart
└── test/                     # lib/ yapısını aynalar, dosya adı *_test.dart
    ├── core/
    ├── data/
    ├── services/
    ├── state/
    └── ui/
```

## 5. Kısıtlar

- **Teknik:** Flutter stable kanal (≥ 3.35), Dart ≥ 3.9, null-safety. Platformlar: Android (minSdk 24, targetSdk = Flutter varsayılanı) ve iOS (≥ 13.0), sadece telefon dikey yön.
- **Performans:**
  - 365 kayıtla soğuk açılış → ilk zaman çizelgesi karesi ≤ 2 sn (profile mod, orta seviye cihaz: ≥ 4 GB RAM).
  - Izgaradaki küçük resimler `Image.file(..., cacheWidth: 200)` ile küçültülerek decode edilir; tam boy decode sadece detay ekranında yapılır.
  - Ay listesi `ListView.builder` / `CustomScrollView` ile tembel (lazy) oluşturulur; tüm aylar aynı anda oluşturulmaz.
- **Gizlilik / güvenlik:** Hiç ağ isteği yok; `INTERNET` izni release manifest'ine eklenmez (Flutter debug manifest'indeki hariç). Fotoğraflar sadece uygulamanın özel belge dizininde. Analitik/takip yok.
- **Depolama:** Fotoğraf başına hedef ≤ 1 MB (2048 px, kalite 85); 1 yıl ≈ ≤ 365 MB.
- **Dil:** Arayüz yalnızca Türkçe; tüm metinler `lib/core/strings.dart` içinde.
- **Zaman:** 6–12 iş günü (kaynak fikir: "Beginner-friendly, 6–12 Days"). 10. günün sonunda F7 bitmemişse F7 "Sonraki Sürümler"e taşınır.

## 6. Geliştirme Aşamaları

Her aşama sonunda `flutter analyze`, `dart format --output=none --set-exit-if-changed .` ve `flutter test` temiz geçmelidir.

| Aşama | İçerik | Tahmini süre | Bitti Kriteri |
|---|---|---|---|
| 1. Kurulum | `flutter create --org com.muratefecamoglu --project-name one_photo_app --platforms android,ios .`; `.gitignore` içinden `*.lock` satırını kaldır (pubspec.lock commit edilmeli); onaylı paketleri ekle; `analysis_options.yaml` = `flutter_lints`; §4 klasörlerini oluştur; uygulama adı "OnePhoto". | 0.5 gün | `flutter run` boş ana ekranı açar; analyze/format/test temiz; `pubspec.lock` git'te izleniyor. |
| 2. Çekirdek mantık | `date_key.dart`, `calendar.dart`, `entry.dart` + birim testleri. | 1 gün | Testler: ay başı hafta günü hizası (≥ 3 farklı ay), artık yıl Şubatı (2028-02 = 29 gün), ay aralığı hesabı (kayıt yok / 2 yıl önceki kayıt), gün anahtarı biçimi, Türkçe ay adları. |
| 3. Veri katmanı | `EntryRepository`, sqflite uygulaması, `PhotoStorage`, `PhotoService` + testler (`sqflite_common_ffi`, geçici dizin). | 1.5 gün | Testler: upsert aynı gün için tek satır bırakır; değiştirme sonrası eski dosya silinir; DB hatasında yeni dosya silinir; delete satırı ve dosyayı kaldırır; yetim temizliği sadece referanssız dosyaları siler; 23:59 ve 00:00 `Clock` değerleri doğru güne yazılır. |
| 4. Zaman çizelgesi UI | `TimelineController`, `TimelineScreen`, `MonthGrid`, `DayCell`, boş durum, Ayarlar ekranının iskeleti (sadece F6g bilgi metni). | 2 gün | F1 kabul kriterleri; widget testleri: sahte repo ile 3 kayıt → 3 küçük resim hücresi; gelecek gün dokunulamaz; kayıt yokken boş durum metni; dosyası olmayan kayıt kırık-resim ikonu gösterir (F6e). |
| 5. Ekleme akışları | Kamera ikonu (F2), hücre seçenek sayfası (F3), değiştirme onayı (F4), izin/hata mesajları (F8). | 1.5 gün | F2, F3, F4, F8 kabul kriterleri; gerçek cihazda/emülatörde manuel kontrol listesi (bkz. AGENT.md). |
| 6. Gün detayı | `DayDetailScreen`: yakınlaştırma, değiştir, sil (F5). | 1 gün | F5 kabul kriterleri; widget testi: sil onayı → controller'dan kayıt kalkar. |
| 7. Hatırlatma | `SettingsStore`, `ReminderService`, `SettingsScreen`'e hatırlatma bölümü (F7). | 1.5 gün | F7 kabul kriterleri; birim testi: ayar kaydet/oku; manuel: bildirim 1 dk sonraya kurulup geldiği görülür. |
| 8. Cila ve teslim | Uygulama ikonu (varsayılan Flutter ikonu kalabilir), debug/profile-only "365 günlük demo veri üret" butonu (Ayarlar, `kReleaseMode` değilken görünür; en az 1 kayıt varken o kaydın fotoğrafını kopyalayarak son 365 günün boş günlerini doldurur), performans ölçümü, README. | 1 gün | §1 başarı ölçütleri ölçülmüş ve README'ye yazılmış; `flutter build apk --release` başarılı. |

Toplam tahmin: ~10 gün (6–12 gün aralığında).

## 7. Riskler

| Risk | Etki | Önlem |
|---|---|---|
| Saat dilimi / gece yarısı hatası: 23:59'da çekilen fotoğraf ertesi güne yazılır veya UTC kullanılarak yanlış güne düşer. | Yüksek — ürünün temel vaadi bozulur. | Gün anahtarı **kayıt anında** yerel `DateTime.now()` ile bir kez hesaplanır ve saklanır; asla UTC'den türetilmez. `date_key.dart` için sınır testleri (23:59, 00:00, yaz saati geçişi). |
| iOS uygulama konteyner yolu güncellemelerde değişir; mutlak yol saklanırsa tüm fotoğraflar "kaybolur". | Yüksek | DB'de yalnızca dosya adı; yol her açılışta `getApplicationDocumentsDirectory()` ile çözülür (F6b). |
| Uygulama silinince tüm fotoğraflar gider (yedek yok). | Yüksek (kullanıcı için) | MVP'de kabul edilen risk; Ayarlar ekranında "Fotoğraflar sadece bu cihazda saklanır, uygulamayı silersen kaybolur." bilgi metni. Yedekleme "Sonraki Sürümler"de. |
| Büyük fotoğraflar ızgarada bellek taşmasına/takılmaya yol açar. | Orta | `image_picker` `maxWidth/maxHeight: 2048, imageQuality: 85`; ızgarada `cacheWidth: 200`; lazy liste. |
| Android bildirim kısıtları (Android 13+ izin, Doze modu) hatırlatmayı geciktirir/engeller. | Orta | `POST_NOTIFICATIONS` izni çalışma anında istenir; `AndroidScheduleMode.inexactAllowWhileIdle` kullanılır (exact alarm izni gerekmez), ±15 dk sapma kabul edilir. |
| Değiştirme/silme sırasında uygulama çökerse yetim dosya veya kayıtsız dosya kalır. | Düşük | Sıra: yeni dosya yaz → DB güncelle → eski dosyayı sil. Açılışta yetim temizliği (F6f). |
| Android, kamera açıkken düşük bellek nedeniyle uygulama etkinliğini öldürür; çekilen fotoğraf kaybolur. | Orta | Açılışta `ImagePicker.retrieveLostData()` kontrolü; kurtarılan fotoğraf picker açılmadan önce saklanan `pending_date_key` gününe kaydedilir (V3); anahtar yoksa bugüne. |
| 6–12 gün süresi aşılır. | Orta | F7 ilk ertelenecek özellik; aşamalar bağımsız teslim edilebilir. |

## 8. Varsayımlar

Önem sırasına göre (üstteki yanlışsa en çok iş değişir):

- **V1 — Platform ve teknoloji:** Android + iOS telefon, **Flutter/Dart**. Gerekçe: depodaki mevcut `.gitignore` Flutter şablonudur.
- **V2 — Tamamen yerel:** Hesap, backend, bulut senkronizasyonu yok; veri yalnızca cihazda.
- **V3 — Gün ataması:** Fotoğrafın günü, kullanıcının eklediği gündür (kamera = bugün, hücre = o hücrenin günü); EXIF tarihi kullanılmaz.
- **V4 — Geçmişe ekleme serbest:** Geçmiş günlere fotoğraf eklenebilir/değiştirilebilir; gelecek günlere eklenemez.
- **V5 — Gösterilen aralık:** En az son 12 ay gösterilir (geçmişe ekleme yapılabilsin diye); daha eski kayıt varsa onun ayına kadar uzanır.
- **V6 — Arayüz dili Türkçe**, hafta Pazartesi başlar, tarih biçimi `tr_TR`.
- **V7 — Kamera:** Özel kamera ekranı yerine sistem kamerası (`image_picker`) kullanılır; ön izleme/tekrar çekme sistem arayüzünde yapılır.
- **V8 — Hatırlatma varsayılan kapalı**, 20:00; o gün fotoğraf eklenmiş olsa da bildirim gelir (akıllı atlama sonraki sürümde).
- **V9 — Küçük resim dosyası üretilmez:** Izgara orijinal (≤ 2048 px) dosyayı `cacheWidth` ile küçük decode eder. Performans hedefi tutmazsa küçük resim üretimi eklenir (onay gerektirir).
- **V10 — Durum yönetimi:** Ek paket yok; `ChangeNotifier` + `ListenableBuilder`.
- **V11 — Paket kimliği:** `com.muratefecamoglu.one_photo_app` (Android `applicationId` / iOS bundle id `com.muratefecamoglu.onePhotoApp`), görünen ad "OnePhoto".
- **V12 — Tema:** Sadece açık tema; görsel stil kaynak görseldeki gibi beyaz zemin, yuvarlatılmış küçük resimler.
- **V13 — Yayın:** MVP'nin "bitti" tanımı mağaza yayını içermez; release APK üretilebilmesi yeterlidir. iOS release build macOS gerektirir, bu ortamda doğrulanamayabilir.
