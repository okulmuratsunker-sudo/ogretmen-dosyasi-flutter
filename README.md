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

## Backend
- Supabase project ref: `hnshsiflnlzqxxaaqnow`
- Tablolar: `teacher_students`, `teacher_grades`, `student_scores`,
  `score_history`, `exam_questions`, `question_scores`, `teacher_plans`,
  `teacher_schedule`, `teacher_photos`
- Tüm tablolarda RLS açık, sadece giriş yapmış kullanıcılar erişebilir.
