# Play Store yayın rehberi

Bu klasör, Google Play Console'a yüklenecek her şeyi içerir. Kişisel bilgi içermez; ekran görüntüleri örnek görsellerle üretilmiştir.

| Dosya | Play Console alanı | Ölçü |
|---|---|---|
| `icon-512.png` | Uygulama simgesi | 512 × 512 |
| `feature-graphic-tr.png` / `feature-graphic-en.png` | Öne çıkan grafik | 1024 × 500 |
| `screenshots/tr/*.png`, `screenshots/en/*.png` | Telefon ekran görüntüleri (6 adet) | 1080 × 2160 |
| [`../privacy-policy.md`](../privacy-policy.md) | Gizlilik politikası URL'si | — |

## 1. Yükleme anahtarı (bir kez)

Anahtarı **deponun dışında** oluştur ve şifresiyle birlikte güvenli bir yerde yedekle; kaybolursa güncelleme yükleyemezsin.

```bash
keytool -genkey -v -keystore ~/onephoto-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` dosyasını oluştur (git'e girmez):

```properties
storePassword=<şifre>
keyPassword=<şifre>
keyAlias=upload
storeFile=C:/Users/<kullanıcı>/onephoto-upload.jks
```

Play Console'da **Play App Signing**'i açık bırak: Google uygulamayı kendi anahtarıyla imzalar, senin anahtarın yalnızca yükleme içindir.

## 2. Paketi derle

```bash
flutter build appbundle --release
# çıktı: build/app/outputs/bundle/release/app-release.aab
```

Her yeni sürümde `pubspec.yaml` içindeki `version: 1.0.0+1` değerinin `+` sonrasını (sürüm kodu) artır.

## 3. Mağaza girişi

**Uygulama adı:** OnePhoto

**Kısa açıklama (≤ 80 karakter)**
- TR: `Her gün tek bir fotoğraf ekle, hayatını ay ay takvimde gör. Tamamen çevrimdışı.`
- EN: `Add one photo a day and see your life month by month. Fully offline.`

**Tam açıklama — TR**

```
OnePhoto ile her gün tek bir kare seç; aylar geçtikçe hayatının görsel bir zaman çizelgesi oluşsun.

• Takvim görünümü: Her fotoğraf kendi gününde, ay ay ızgarada.
• 3 dokunuşta bugünün fotoğrafı: Kamera düğmesi → çek → onayla.
• Geçmiş günlere ekleme: Boş bir güne dokun, çek ya da galeriden seç.
• Kategoriler: Yemek, Manzara, Seyahat, Aile, Arkadaşlar, Evcil hayvan ve daha fazlası; her biri kendi rengi ve simgesiyle.
• Günün notu: O gün neler oldu, birkaç cümleyle yaz.
• Galeri: Tüm karelerin tek ızgarada, kategoriye göre süzülebilir.
• Koyu tema ve Türkçe/İngilizce arayüz.
• Günlük hatırlatma: İstediğin saatte nazik bir bildirim.

Gizlilik önce gelir: Hesap yok, reklam yok, analitik yok. OnePhoto internete hiç bağlanmaz; fotoğrafların yalnızca telefonunda kalır.
```

**Full description — EN**

```
Pick one photo every day with OnePhoto and watch a visual timeline of your life grow month by month.

• Calendar view: every photo on its own day, in a monthly grid.
• Today's photo in 3 taps: camera button → shoot → confirm.
• Fill in past days: tap an empty day, take a photo or choose one from your gallery.
• Categories: Food, View, Travel, Family, Friends, Pet and more, each with its own colour and icon.
• Note of the day: a few words about what happened.
• Gallery: all your shots in one grid, filterable by category.
• Dark theme and Turkish/English interface.
• Daily reminder: a gentle notification at the time you choose.

Privacy first: no account, no ads, no analytics. OnePhoto never connects to the internet; your photos stay on your phone.
```

**Kategori:** Fotoğrafçılık (Photography) · **Etiketler:** günlük, fotoğraf, takvim

## 4. Uygulama içeriği formları

| Form | Yanıt |
|---|---|
| Gizlilik politikası | `docs/privacy-policy.md` dosyasının herkese açık adresi (ör. GitHub sayfası). Önce `[iletişim e-postası]` alanını doldur. |
| Reklamlar | Uygulamada reklam **yok** |
| Uygulama erişimi | Tüm özellikler kısıtlamasız (giriş yok) |
| İçerik derecelendirmesi | Şiddet, cinsellik, kumar, kullanıcılar arası etkileşim **yok**; paylaşım özelliği **yok** |
| Hedef kitle | 13 yaş ve üzeri önerilir |
| Haber uygulaması | Hayır |
| **Veri güvenliği** | **Veri toplanmıyor**, **veri paylaşılmıyor**. Uygulama internete bağlanmaz; fotoğraflar, notlar ve ayarlar yalnızca cihazda saklanır. |
| İzinler | `POST_NOTIFICATIONS` (isteğe bağlı günlük hatırlatma), `RECEIVE_BOOT_COMPLETED` (yeniden başlatma sonrası hatırlatmayı kurmak), `VIBRATE`. Kamera ve fotoğraf erişimi sistem uygulamalarıyla yapılır, ayrı izin istenmez. |

## 5. Yayından önce kontrol listesi

- [ ] `android/key.properties` hazır, `flutter build appbundle --release` başarılı.
- [ ] Gizlilik politikası yayında ve e-posta dolduruldu.
- [ ] Önce **Dahili test** kanalına yükle, kendi telefonunda Play'den kurup dene.
- [ ] Play geliştirici hesabında görünen **geliştirici adını** istediğin gibi (ör. "OnePhoto") ayarla; bu ad mağazada herkese görünür.
