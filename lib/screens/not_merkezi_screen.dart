import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class NotMerkeziScreen extends StatefulWidget {
  const NotMerkeziScreen({super.key});

  @override
  State<NotMerkeziScreen> createState() => _NotMerkeziScreenState();
}

class _NotMerkeziScreenState extends State<NotMerkeziScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  String? selectedClass;
  int sem = 1;
  String examType = 'w1';

  final noCtrl = TextEditingController();
  final valCtrl = TextEditingController();
  final noFocus = FocusNode();
  final valFocus = FocusNode();
  String preview = 'Hazır — öğrenci numarası girin';
  bool previewError = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 5, vsync: this);
  }

  void _checkNumber(AppState s) {
    final no = noCtrl.text.trim();
    if (no.isEmpty) {
      setState(() {
        preview = 'Hazır — öğrenci numarası girin';
        previewError = false;
      });
      return;
    }
    if (selectedClass == null) return;
    final st = s
        .studentsInClass(selectedClass!)
        .where((x) => x.studentNumber == no)
        .toList();
    if (st.isNotEmpty) {
      setState(() {
        preview = '${st.first.studentNumber} — ${st.first.name}';
        previewError = false;
      });
    } else {
      setState(() {
        preview = '❌ Bulunamadı: $no';
        previewError = true;
      });
    }
  }

  Future<void> _submitWritten(AppState s) async {
    final no = noCtrl.text.trim();
    if (no.isEmpty || selectedClass == null) return;
    final matches =
        s.studentsInClass(selectedClass!).where((x) => x.studentNumber == no);
    if (matches.isEmpty) {
      setState(() {
        preview = '❌ Bulunamadı: $no';
        previewError = true;
      });
      return;
    }
    final st = matches.first;
    final valStr = valCtrl.text.trim();
    if (valStr.isEmpty) return;
    final n = double.tryParse(valStr);
    if (n == null || n < 0 || n > 100) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not 0-100 arasında olmalı')));
      valCtrl.clear();
      return;
    }
    final existingGrade = s.gradeFor(st.id, sem);
    final existingVal = examType == 'w1' ? existingGrade?.w1 : existingGrade?.w2;
    if (existingVal != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(st.name),
          content: Text('Mevcut not: $existingVal. Değiştirmek istiyor musunuz?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Değiştir')),
          ],
        ),
      );
      if (confirmed != true) {
        noCtrl.clear();
        valCtrl.clear();
        noFocus.requestFocus();
        return;
      }
    }
    final err = await s.saveGrade(st.id, sem, examType, n);
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $err')));
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('✓ ${st.name}: $n')));
    }
    noCtrl.clear();
    valCtrl.clear();
    setState(() {
      preview = 'Hazır — öğrenci numarası girin';
      previewError = false;
    });
    noFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final classes = s.classNames;

    return Column(
      children: [
        TabBar(
          controller: tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Yazılı Giriş'),
            Tab(text: 'Sözlü Hesaplama'),
            Tab(text: 'Not Listesi'),
            Tab(text: 'E-Okul Kopyalama'),
            Tab(text: 'Dışa Aktarma'),
          ],
        ),
        Expanded(
          child: classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Önce sınıf/öğrenci listesi gerekli.'),
                      const SizedBox(height: 8),
                      FilledButton(
                          onPressed: () => Navigator.of(context).pushNamed('/classes'),
                          child: const Text('🏫 Sınıflarım')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: tabController,
                  children: [
                    _writtenEntryTab(s, classes),
                    _oralCalcTab(s, classes),
                    _gradeListTab(s, classes),
                    _eokulCopyTab(s, classes),
                    _exportTab(s, classes),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _classAndSemSelector(List<String> classes) {
    selectedClass ??= classes.first;
    return Row(
      children: [
        DropdownButton<String>(
          value: selectedClass,
          items: classes
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => selectedClass = v),
        ),
        const SizedBox(width: 16),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1.Dönem')),
            ButtonSegment(value: 2, label: Text('2.Dönem')),
          ],
          selected: {sem},
          onSelectionChanged: (v) => setState(() => sem = v.first),
        ),
      ],
    );
  }

  Widget _writtenEntryTab(AppState s, List<String> classes) {
    final list = selectedClass != null ? s.studentsInClass(selectedClass!) : [];
    final w1Count = list.where((st) => s.gradeFor(st.id, sem)?.w1 != null).length;
    final w2Count = list.where((st) => s.gradeFor(st.id, sem)?.w2 != null).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _classAndSemSelector(classes),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'w1', label: Text('1. Yazılı')),
            ButtonSegment(value: 'w2', label: Text('2. Yazılı')),
          ],
          selected: {examType},
          onSelectionChanged: (v) => setState(() => examType = v.first),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          Chip(label: Text('1.Yazılı: $w1Count / ${list.length}')),
          Chip(label: Text('2.Yazılı: $w2Count / ${list.length}')),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: previewError ? Colors.red.withOpacity(.08) : Colors.green.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(preview,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: previewError ? Colors.red : Colors.green[800])),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: noCtrl,
                focusNode: noFocus,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Öğrenci No', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (_) => _checkNumber(s),
                onSubmitted: (_) => valFocus.requestFocus(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: valCtrl,
                focusNode: valFocus,
                decoration: const InputDecoration(labelText: 'Not', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _submitWritten(s),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => _submitWritten(s),
          child: const Text('Kaydet (Enter)'),
        ),
      ],
    );
  }

  Widget _oralCalcTab(AppState s, List<String> classes) {
    final list = selectedClass != null ? s.studentsInClass(selectedClass!) : [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _classAndSemSelector(classes),
        const SizedBox(height: 12),
        const Text(
            'Sözlü = Yazılı Ortalaması + (Classroom Puanı / 2) — 100\'ü geçemez.',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => _calcAllOral(s, list),
          child: const Text('🧮 Tüm Sınıf İçin Sözlüleri Hesapla'),
        ),
        const SizedBox(height: 16),
        for (final st in list) _oralRow(s, st),
      ],
    );
  }

  Widget _oralRow(AppState s, st) {
    final g = s.gradeFor(st.id, sem);
    final avg = s.writtenAvg(st.id, sem);
    final manual = s.classroomScoreFor(st.id, sem)?.isManualOral ?? false;
    final clsCtrl = TextEditingController(
        text: s.classroomScoreFor(st.id, sem)?.classroomScore?.toStringAsFixed(0) ?? '');
    final oralCtrl = TextEditingController(text: g?.oral?.toStringAsFixed(0) ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(st.name)),
            Expanded(child: Text('Ort: ${avg?.toStringAsFixed(1) ?? '—'}')),
            SizedBox(
              width: 70,
              child: TextField(
                controller: clsCtrl,
                decoration: const InputDecoration(labelText: 'Classroom', isDense: true),
                keyboardType: TextInputType.number,
                onSubmitted: (v) async {
                  await s.setClassroomScore(st.id, sem, double.tryParse(v));
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: TextField(
                controller: oralCtrl,
                decoration: const InputDecoration(labelText: 'Sözlü', isDense: true),
                keyboardType: TextInputType.number,
                onSubmitted: (v) async {
                  final n = double.tryParse(v);
                  if (n != null && (n < 0 || n > 100)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Not 0-100 arasında olmalı')));
                    return;
                  }
                  await s.setOralManual(st.id, sem, n);
                  setState(() {});
                },
              ),
            ),
            if (manual)
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Otomatik hesaplamaya dön',
                onPressed: () async {
                  await s.resetOralToAuto(st.id, sem);
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _calcAllOral(AppState s, List list) async {
    final rows = list
        .map((st) => (st: st, avg: s.writtenAvg(st.id, sem), calc: s.calcOral(st.id, sem)))
        .toList();
    final missing = rows.where((r) => r.avg == null).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sözlü Hesaplama Önizleme'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (missing > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('⚠️ $missing öğrencinin yazılı notu yok, hesaplanmayacak',
                        style: const TextStyle(color: Colors.red)),
                  ),
                for (final r in rows)
                  ListTile(
                    dense: true,
                    title: Text(r.st.name),
                    subtitle: Text('Ort: ${r.avg?.toStringAsFixed(1) ?? '—'}'),
                    trailing: Text(r.calc?.toStringAsFixed(0) ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Onayla ve Kaydet')),
        ],
      ),
    );
    if (confirmed != true) return;
    int applied = 0;
    for (final r in rows) {
      if (r.avg == null) continue;
      final isManual = s.classroomScoreFor(r.st.id, sem)?.isManualOral ?? false;
      if (isManual) continue;
      final err = await s.saveGrade(r.st.id, sem, 'oral', r.calc);
      if (err == null) applied++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('✓ $applied öğrencinin sözlüsü hesaplandı')));
      setState(() {});
    }
  }

  Widget _gradeListTab(AppState s, List<String> classes) {
    final list = selectedClass != null ? s.studentsInClass(selectedClass!) : [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _classAndSemSelector(classes),
        const SizedBox(height: 8),
        if (selectedClass != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text('"$selectedClass" — $sem.Dönem Notlarını Sıfırla',
                  style: const TextStyle(color: Colors.red)),
              onPressed: () => _resetClassGrades(s, selectedClass!),
            ),
          ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('No')),
              DataColumn(label: Text('Ad Soyad')),
              DataColumn(label: Text('1.Yazılı')),
              DataColumn(label: Text('2.Yazılı')),
              DataColumn(label: Text('Ort.')),
              DataColumn(label: Text('Classroom')),
              DataColumn(label: Text('Sözlü')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final st in list)
                DataRow(cells: [
                  DataCell(Text(st.studentNumber ?? '—')),
                  DataCell(Text(st.name)),
                  DataCell(Text(s.gradeFor(st.id, sem)?.w1?.toStringAsFixed(0) ?? '—')),
                  DataCell(Text(s.gradeFor(st.id, sem)?.w2?.toStringAsFixed(0) ?? '—')),
                  DataCell(Text(s.writtenAvg(st.id, sem)?.toStringAsFixed(1) ?? '—')),
                  DataCell(Text(s.classroomScoreFor(st.id, sem)?.classroomScore?.toStringAsFixed(0) ?? '—')),
                  DataCell(Text(s.gradeFor(st.id, sem)?.oral?.toStringAsFixed(0) ?? '—')),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () => _resetStudentGrade(s, st),
                  )),
                ]),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _resetStudentGrade(AppState s, st) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notu Sıfırla'),
        content: Text('${st.name} için $sem. dönem TÜM notlarını sıfırlamak istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sıfırla')),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await s.resetStudentGrade(st.id, sem);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? '✓ Not sıfırlandı')));
    }
  }

  Future<void> _resetClassGrades(AppState s, String className) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınıf Notlarını Sıfırla'),
        content: Text(
            '"$className" sınıfının $sem. dönem TÜM notlarını sıfırlamak istiyor musunuz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sıfırla')),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await s.resetClassGrades(className, sem);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? '✓ Notlar sıfırlandı')));
    }
  }

  String eokulField = 'w1';

  Widget _eokulCopyTab(AppState s, List<String> classes) {
    final list = selectedClass != null ? s.studentsInClass(selectedClass!) : [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _classAndSemSelector(classes),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: eokulField,
          decoration: const InputDecoration(labelText: 'Kopyalanacak Alan'),
          items: const [
            DropdownMenuItem(value: 'w1', child: Text('1. Yazılı')),
            DropdownMenuItem(value: 'w2', child: Text('2. Yazılı')),
            DropdownMenuItem(value: 'avg', child: Text('Yazılı Ortalaması')),
            DropdownMenuItem(value: 'oral', child: Text('Sözlü')),
            DropdownMenuItem(value: 'classroom', child: Text('Classroom Puanı')),
          ],
          onChanged: (v) => setState(() => eokulField = v ?? 'w1'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('📋 Panoya Kopyala'),
          onPressed: () => _copyColumn(s, list),
        ),
        const SizedBox(height: 8),
        const Text(
            'Seçilen alan, okul numarasına göre sıralı tek sütun olarak panoya kopyalanır — e-Okul\'a doğrudan yapıştırmaya uygundur.',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Future<void> _copyColumn(AppState s, List list) async {
    if (selectedClass == null) return;
    int emptyCount = 0;
    final lines = list.map((st) {
      dynamic v;
      if (eokulField == 'avg') {
        v = s.writtenAvg(st.id, sem);
      } else if (eokulField == 'classroom') {
        v = s.classroomScoreFor(st.id, sem)?.classroomScore;
      } else {
        final g = s.gradeFor(st.id, sem);
        v = eokulField == 'oral' ? g?.oral : (eokulField == 'w1' ? g?.w1 : g?.w2);
      }
      if (v == null) {
        emptyCount++;
        return '';
      }
      return v is double ? v.toStringAsFixed(0) : v.toString();
    }).join('\n');
    await Clipboard.setData(ClipboardData(text: lines));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(emptyCount > 0
              ? '✓ Kopyalandı ($emptyCount öğrencide bu not eksik, boş satır olarak korundu)'
              : '✓ Panoya kopyalandı')));
    }
  }

  Widget _exportTab(AppState s, List<String> classes) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _classAndSemSelector(classes),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('📄 CSV Olarak Dışa Aktar'),
          onPressed: () => _exportCsv(s),
        ),
        const SizedBox(height: 8),
        const Text(
            'Seçilen sınıfın okul numarasına göre sıralı tam not listesi CSV dosyası olarak indirilir.',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Future<void> _exportCsv(AppState s) async {
    if (selectedClass == null) return;
    final list = s.studentsInClass(selectedClass!);
    final rows = <List<String>>[
      ['Okul No', 'Ad Soyad', 'Sınıf', '1.Yazılı', '2.Yazılı', 'Yazılı Ort.', 'Classroom', 'Sözlü']
    ];
    for (final st in list) {
      final g = s.gradeFor(st.id, sem);
      rows.add([
        st.studentNumber ?? '',
        st.name,
        st.className ?? '',
        g?.w1?.toStringAsFixed(0) ?? '',
        g?.w2?.toStringAsFixed(0) ?? '',
        s.writtenAvg(st.id, sem)?.toStringAsFixed(1) ?? '',
        s.classroomScoreFor(st.id, sem)?.classroomScore?.toStringAsFixed(0) ?? '',
        g?.oral?.toStringAsFixed(0) ?? '',
      ]);
    }
    final csv = rows
        .map((r) => r.map((c) => '"${c.replaceAll('"', '""')}"').join(','))
        .join('\r\n');
    final savePath = await FilePicker.platform.saveFile(
      fileName: 'not-merkezi-$selectedClass-d$sem.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (savePath == null) return;
    final file = File(savePath.endsWith('.csv') ? savePath : '$savePath.csv');
    await file.writeAsString('﻿$csv', encoding: const Utf8Codec());
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('✓ Kaydedildi: ${file.path}')));
    }
  }
}
