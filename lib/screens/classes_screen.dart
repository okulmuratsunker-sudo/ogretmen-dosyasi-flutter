import 'dart:convert';
import 'package:excel2003/excel2003.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  String? selectedClass;
  final newClassCtrl = TextEditingController();
  final stuNoCtrl = TextEditingController();
  final stuNameCtrl = TextEditingController();
  String? error;

  Future<void> _createClass() async {
    final name = newClassCtrl.text.trim();
    if (name.isEmpty) return;
    final err = await context.read<AppState>().createClass(name);
    if (err == null) {
      newClassCtrl.clear();
      setState(() => selectedClass = name);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _deleteClass(String name, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınıfı Sil'),
        content: Text(count > 0
            ? '"$name" sınıfındaki $count öğrenciyi ve TÜM notlarını/puanlarını kalıcı olarak silmek istiyor musunuz? Bu işlem geri alınamaz.'
            : '"$name" sınıfını silmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await context.read<AppState>().deleteClass(name);
    if (mounted) {
      if (selectedClass == name) setState(() => selectedClass = null);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err == null ? '✓ Sınıf silindi' : 'Hata: $err')));
    }
  }

  Future<void> _addStudent() async {
    final no = stuNoCtrl.text.trim();
    final name = stuNameCtrl.text.trim();
    if (no.isEmpty || name.isEmpty || selectedClass == null) {
      setState(() => error = 'Numara ve ad soyad zorunlu.');
      return;
    }
    final err = await context
        .read<AppState>()
        .addStudentToClass(selectedClass!, no, name);
    setState(() => error = err);
    if (err == null) {
      stuNoCtrl.clear();
      stuNameCtrl.clear();
    }
  }

  Future<void> _importExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt', 'xls'],
      withData: true,
    );
    if (result == null) return;
    final path = result.files.single.path;
    final name = result.files.single.name.toLowerCase();

    List<ImportRow> rows;
    int? detectedSemester;
    String? detectedClassName;

    if (name.endsWith('.xls') && path != null) {
      try {
        final parsed = _parseEokulXls(path);
        rows = parsed.rows;
        detectedSemester = parsed.semester;
        detectedClassName = parsed.className;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('XLS dosyası okunamadı: $e')));
        }
        return;
      }
    } else {
      final bytes = result.files.single.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Dosya okunamadı.')));
        }
        return;
      }
      final text = utf8.decode(bytes, allowMalformed: true);
      final lines = text.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty);
      rows = [];
      for (final line in lines) {
        final parts = line.split(RegExp(r'[,;\t]'));
        if (parts.length < 2) continue;
        final no = parts[0].trim();
        final studentName = parts.sublist(1).join(' ').trim().replaceAll('"', '');
        if (no.isEmpty || studentName.isEmpty) continue;
        if (RegExp(r'^[a-zA-ZçÇğĞıİöÖşŞüÜ]').hasMatch(no)) continue; // başlık satırı
        rows.add(ImportRow(no: no, name: studentName));
      }
    }

    if (rows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Geçerli satır bulunamadı. CSV format: Numara,Ad Soyad (her satırda bir öğrenci)')));
      }
      return;
    }
    // Dosyada sınıf adı algılandıysa onu kullan (otomatik tanır); yoksa
    // ekranda seçili olan sınıfa düş.
    final targetClass = detectedClassName ?? selectedClass;
    if (targetClass == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Sınıf adı dosyadan algılanamadı. Lütfen önce bir sınıf seçin.')));
      }
      return;
    }
    final err = await context
        .read<AppState>()
        .importStudentsToClass(targetClass, rows, semester: detectedSemester);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err ?? '✓ ${rows.length} satır işlendi (sınıf: $targetClass)')));
      setState(() => selectedClass = targetClass);
    }
  }

  // e-Okul "Puan Çizelgesi" / "Puan/Not Çizelgesi" .xls formatını okur.
  // Sütunları isimle (Y1/Y2/P1/P2/Proje hücre metniyle) bulur — merge'lenmiş
  // hücreler nedeniyle sabit sütun indeksine güvenmek hataya açık olurdu.
  // Not Defteri şeması sadece 2 yazılı + 2 performans + 2 proje destekliyor;
  // dosyada bundan fazlası varsa (Y3-Y5, P3, U2/U3) sessizce atlanır.
  // ÖNEMLİ: e-Okul'daki "SINAVLAR" bölümünün 5 ortak slotu (Y1-Y5) okulda/
  // derste serbestçe kullanılıyor: Y1=1.Yazılı, Y2=2.Yazılı, Y3=1.Performans,
  // Y4=2.Performans, Y5=Proje (varsa). "Performans"/"Uygulama"/"Proje" grup
  // başlıkları altındaki P1-P3/U1-U3/Proje sütunları ise e-Okul'un kendi
  // AĞIRLIKLI ORTALAMA hesaplamasıdır (ham not değil) — bilerek okunmuyor.
  ({List<ImportRow> rows, int? semester, String? className}) _parseEokulXls(String path) {
    final reader = XlsReader(path);
    reader.open();
    final sheet = reader.sheet(0);

    int headerRow = -1;
    int colY1 = -1, colY2 = -1, colY3 = -1, colY4 = -1, colY5 = -1;
    String className = '';
    int? semester;
    for (int r = sheet.firstRow; r <= sheet.lastRow; r++) {
      for (int c = sheet.firstCol; c <= sheet.lastCol; c++) {
        final v = sheet.cell(r, c);
        if (v == null) continue;
        final s = v.toString().trim();
        if (s == 'Y1') {
          headerRow = r;
          colY1 = c;
        }
        if (r == headerRow) {
          if (s == 'Y2') colY2 = c;
          if (s == 'Y3') colY3 = c;
          if (s == 'Y4') colY4 = c;
          if (s == 'Y5') colY5 = c;
        }
        if (RegExp(r'Sınıfı\s*/\s*Şubesi').hasMatch(s)) {
          for (int cc = c; cc <= sheet.lastCol; cc++) {
            final v2 = sheet.cell(r, cc);
            if (v2 != null && v2.toString().contains(':')) {
              className = v2.toString().replaceAll(':', '').trim();
              break;
            }
          }
        }
        if (semester == null) {
          final m = RegExp(r'(I{1,2})\.\s*DÖNEM\s*PUAN', caseSensitive: false)
              .firstMatch(s);
          if (m != null) semester = m.group(1)!.toUpperCase() == 'II' ? 2 : 1;
        }
      }
    }
    if (headerRow < 0 || colY1 < 0) {
      throw 'e-Okul formatı tanınamadı (Y1 sütunu bulunamadı).';
    }

    // e-Okul'da bazı sütunlar (özellikle U1-U3) bazen "Ağırlıklı Puan" gibi
    // 0-100 aralığı dışında değerler taşıyabiliyor — bunları not olarak kabul
    // etmemek için aralık dışı değerleri reddediyoruz.
    double? toScore(dynamic v) {
      if (v == null) return null;
      double? d;
      if (v is num) {
        d = v.toDouble();
      } else {
        d = double.tryParse(v.toString());
      }
      if (d == null || d < 0 || d > 100) return null;
      return d;
    }

    final rows = <ImportRow>[];
    for (int r = headerRow + 1; r <= sheet.lastRow; r++) {
      final noV = sheet.cell(r, 1);
      final nameV = sheet.cell(r, 2);
      if (noV == null || nameV == null) continue;
      final noStr = noV.toString().trim();
      final no = noStr.endsWith('.0') ? noStr.substring(0, noStr.length - 2) : noStr;
      final studentName = nameV.toString().trim();
      if (no.isEmpty || studentName.isEmpty || !RegExp(r'^\d+$').hasMatch(no)) {
        continue;
      }
      rows.add(ImportRow(
        no: no,
        name: studentName,
        y1: toScore(sheet.cell(r, colY1)),
        y2: colY2 >= 0 ? toScore(sheet.cell(r, colY2)) : null,
        perf1: colY3 >= 0 ? toScore(sheet.cell(r, colY3)) : null,
        perf2: colY4 >= 0 ? toScore(sheet.cell(r, colY4)) : null,
        proje1: colY5 >= 0 ? toScore(sheet.cell(r, colY5)) : null,
        proje2: null,
      ));
    }
    return (rows: rows, semester: semester, className: className.isEmpty ? null : className);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final classes = s.classNames;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('🏫 Sınıflarım',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('① Yeni Sınıf Oluştur',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newClassCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Örn: 9-D, AL-10/C',
                            border: OutlineInputBorder(),
                            isDense: true),
                        onSubmitted: (_) => _createClass(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _createClass, child: const Text('+ Oluştur')),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('veya', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _importExcel,
                  icon: const Icon(Icons.upload_file),
                  label: const Text(
                      'Excel/CSV/XLS Yükle (e-Okul dosyası ise sınıfı otomatik tanır)'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('② Sınıflar (${classes.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (classes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Henüz sınıf yok.')),
                )
              else
                for (final c in classes)
                  ListTile(
                    selected: selectedClass == c,
                    title: Text(c),
                    subtitle: Text('${s.studentsInClass(c).length} öğrenci'),
                    onTap: () => setState(() => selectedClass = c),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteClass(c, s.studentsInClass(c).length),
                    ),
                  ),
            ],
          ),
        ),
        if (selectedClass != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('③ "$selectedClass" Sınıfına Öğrenci Ekle',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      TextButton.icon(
                        onPressed: _importExcel,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('CSV Yükle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: stuNoCtrl,
                          decoration: const InputDecoration(
                              hintText: 'No', isDense: true, border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: stuNameCtrl,
                          decoration: const InputDecoration(
                              hintText: 'Ad Soyad',
                              isDense: true,
                              border: OutlineInputBorder()),
                          onSubmitted: (_) => _addStudent(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(onPressed: _addStudent, child: const Text('+ Ekle')),
                    ],
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 12),
                  for (final st in s.studentsInClass(selectedClass!))
                    ListTile(
                      dense: true,
                      title: Text(st.name),
                      subtitle: Text('No: ${st.studentNumber ?? '—'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDeleteStudent(st),
                      ),
                    ),
                  if (s.studentsInClass(selectedClass!).isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Bu sınıfta henüz öğrenci yok.'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDeleteStudent(Student st) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenciyi Sil'),
        content: Text(
            '"${st.name}" öğrencisini ve TÜM notlarını/puanlarını kalıcı olarak silmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await context.read<AppState>().deleteStudent(st.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err == null ? '✓ ${st.name} silindi' : 'Hata: $err')));
    }
  }
}
