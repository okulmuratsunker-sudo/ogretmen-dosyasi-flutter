import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../models.dart';

class ScoresScreen extends StatelessWidget {
  const ScoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final sorted = [...s.students]
      ..sort((a, b) => (s.scoreFor(b.id)?.score ?? 0).compareTo(s.scoreFor(a.id)?.score ?? 0));
    const medals = ['🥇', '🥈', '🥉'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('⭐ Puan Sistemi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('🏆 Sıralama', style: TextStyle(fontWeight: FontWeight.bold))),
              ),
              for (var i = 0; i < sorted.length; i++)
                ListTile(
                  leading: Text(i < 3 ? medals[i] : '${i + 1}.'),
                  title: Text(sorted[i].name),
                  trailing: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                          label: Text(
                              '${(s.scoreFor(sorted[i].id)?.score ?? 0) >= 0 ? '+' : ''}${(s.scoreFor(sorted[i].id)?.score ?? 0).toStringAsFixed(0)} ⭐')),
                      OutlinedButton(
                        onPressed: () => _openScoreDialog(context, sorted[i]),
                        child: const Text('± Puan'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child:
                        Text('📜 Son Puan Hareketleri', style: TextStyle(fontWeight: FontWeight.bold))),
              ),
              if (s.scoreHistory.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Henüz hareket yok.'),
                )
              else
                for (final h in s.scoreHistory.take(40))
                  ListTile(
                    dense: true,
                    title: Text(_studentName(s, h.studentId) + (h.note != null && h.note!.isNotEmpty ? '  —  ${h.note}' : '')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${h.delta >= 0 ? '+' : ''}${h.delta.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: h.delta >= 0 ? Colors.green : Colors.red),
                        ),
                        const SizedBox(width: 10),
                        Text(DateFormat('dd.MM HH:mm').format(h.createdAt),
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  String _studentName(AppState s, String id) {
    try {
      return s.students.firstWhere((st) => st.id == id).name;
    } catch (_) {
      return '?';
    }
  }

  void _openScoreDialog(BuildContext context, Student st) {
    final amtCtrl = TextEditingController(text: '1');
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${st.name} — Puan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amtCtrl,
              decoration: const InputDecoration(labelText: 'Puan Miktarı (eksi değer çıkarır)'),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
            ),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              final delta = double.tryParse(amtCtrl.text);
              if (delta == null) return;
              final err = await context
                  .read<AppState>()
                  .addScoreDelta(st.id, delta, noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err == null ? '✓ Puan kaydedildi' : 'Hata: $err')));
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
