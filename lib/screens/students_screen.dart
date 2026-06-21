import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.students
        .where((st) =>
            query.isEmpty ||
            st.name.toLowerCase().contains(query.toLowerCase()) ||
            (st.studentNumber ?? '').contains(query))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'İsim veya numara ara…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Öğrenci bulunamadı'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final st = list[i];
                    final sc = s.scoreFor(st.id)?.score ?? 0;
                    final d1 = s.donemAvg(st.id, 1);
                    final lv = MebLevel.of(d1);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Colors.primaries[st.name.hashCode % Colors.primaries.length],
                          child: Text(
                              st.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()),
                        ),
                        title: Text(st.name),
                        subtitle: Text('No: ${st.studentNumber ?? '—'}${st.className != null ? ' • ${st.className}' : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (d1 != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text('$d1 — ${lv.label}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: lv.fail
                                            ? Colors.red
                                            : lv.warn
                                                ? Colors.orange
                                                : Colors.green)),
                              ),
                            Chip(
                                label: Text(
                                    '${sc >= 0 ? '+' : ''}${sc.toStringAsFixed(0)} ⭐')),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, st),
                            ),
                          ],
                        ),
                        onTap: () => _showStudentSheet(context, st),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showStudentSheet(BuildContext context, Student st) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _StudentDetailSheet(student: st),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Student st) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenciyi Sil'),
        content: Text(
            '"${st.name}" öğrencisini ve TÜM notlarını/puanlarını kalıcı olarak silmek istiyor musunuz? Bu işlem geri alınamaz.'),
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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err == null ? '✓ ${st.name} silindi' : 'Hata: $err')));
    }
  }
}

class _StudentDetailSheet extends StatefulWidget {
  final Student student;
  const _StudentDetailSheet({required this.student});

  @override
  State<_StudentDetailSheet> createState() => _StudentDetailSheetState();
}

class _StudentDetailSheetState extends State<_StudentDetailSheet> {
  late TextEditingController noteCtrl;

  @override
  void initState() {
    super.initState();
    noteCtrl = TextEditingController(text: widget.student.notes ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final yn = s.yilsonu(widget.student.id);
    final ynLv = MebLevel.of(yn);
    const cols = [
      ['w1', 'Yazılı 1'],
      ['w2', 'Yazılı 2'],
      ['oral', 'Sözlü'],
      ['perf', 'Perf. 1'],
      ['perf2', 'Perf. 2'],
      ['project', 'Proje 1'],
      ['proj2', 'Proje 2'],
    ];
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.student.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final sem in [1, 2]) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$sem. Dönem',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                  Text('${s.donemAvg(widget.student.id, sem)?.toStringAsFixed(0) ?? '—'}'),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cols)
                    Container(
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          Text(c[1], style: const TextStyle(fontSize: 10)),
                          Text(
                              (s.gradeFor(widget.student.id, sem)?[c[0]])
                                      ?.toStringAsFixed(0) ??
                                  '—',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Yılsonu Notu', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${yn?.toStringAsFixed(0) ?? '—'} — ${ynLv.label}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '📝 Öğretmen Gözlem Notu',
                border: OutlineInputBorder(),
                hintText: 'Veli görüşmesi, davranış, gelişim notları…',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final err = await s.saveStudentNote(widget.student.id, noteCtrl.text);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(err == null ? '✓ Not kaydedildi' : 'Hata: $err')));
                  }
                },
                child: const Text('Notu Kaydet'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
