import 'dart:convert';
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
    if (selectedClass == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    if (result == null) return;
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
    final rows = <(String, String)>[];
    for (final line in lines) {
      final parts = line.split(RegExp(r'[,;\t]'));
      if (parts.length < 2) continue;
      final no = parts[0].trim();
      final name = parts.sublist(1).join(' ').trim().replaceAll('"', '');
      if (no.isEmpty || name.isEmpty) continue;
      if (RegExp(r'^[a-zA-ZçÇğĞıİöÖşŞüÜ]').hasMatch(no)) continue; // başlık satırı
      rows.add((no, name));
    }
    if (rows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Geçerli satır bulunamadı. Format: Numara,Ad Soyad (her satırda bir öğrenci)')));
      }
      return;
    }
    final err =
        await context.read<AppState>().importStudentsToClass(selectedClass!, rows);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err ?? '✓ ${rows.length} satır işlendi')));
    }
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
