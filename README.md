# Öğretmen Dosyası (Flutter)

`ogretmen-dosyasi.html` web uygulamasının Flutter sürümü. Bağımsız bir Supabase
projesi kullanır, mevcut ChemClass / web uygulamasıyla veri paylaşmaz.

## Özellikler
- Giriş / Kayıt (Supabase Auth)
- Ana Ekran (özet istatistikler)
- Öğrenciler (liste, arama, gözlem notu)
- Not Defteri (dönemlik notlar, otomatik kaydet)
- Madde Analizi (soru bazlı puanlama, güçlük/ayırt edicilik analizi)
- Puan Sistemi (sıralama, puan geçmişi)
- Ders Planları (günlük/ünite/yıllık)

## Kurulum
```bash
flutter pub get
flutter run
```

Supabase bağlantı bilgileri `lib/constants.dart` içinde tanımlı.

## Local geliştirme
Bu repoda doğrudan gizli anahtarlar saklanmamalıdır. Local geliştirme için şu adımları öneririz:

1. Depo kökünde bir `.env` dosyası oluşturun (bu dosyayı versiyona eklememek için .gitignore zaten güncellenecek):

```
SUPABASE_URL=https://<your-ref>.supabase.co
SUPABASE_ANON_KEY=eyJ... (anon key)
```

2. Uygulama içinde `flutter_dotenv` veya benzeri bir yöntemle bu değişkenleri yükleyin ve `lib/constants.dart` içindeki sabit anahtarları kullanmak yerine ortam değişkenlerini okuyun.

3. Eğer mevcut anahtarlar repoda ifşa olduysa Supabase kontrol panelinden anahtarları rotasyon (yenileme) yapın.

Not: README'deki `hnshsiflnlzqxxaaqnow` ref ile `lib/constants.dart` içindeki URL çelişebilir; hangi Supabase projesini kullandığınızı netleştirip README'i ona göre güncelleyin.
