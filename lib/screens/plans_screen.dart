import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  static const types = {
    'gun': 'Günlük',
    'unite': 'Ünite',
    'yillik': 'Yıllık',
  };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('📚 Ders Planları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openPlanDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Plan Ekle'),
              ),
            ],
          ),
        ),
        Expanded(
          child: s.plans.isEmpty
              ? const Center(child: Text('Henüz ders planı yok.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: s.plans.length,
                  itemBuilder: (context, i) {
                    final p = s.plans[i];
                    return Card(
                      child: ListTile(
                        leading: Chip(label: Text(types[p.planType] ?? 'Plan')),
                        title: Text(p.title),
                        subtitle: Text(
                            '${p.date != null ? DateFormat('dd.MM.yyyy').format(p.date!) : ''}\n${p.content ?? ''}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => s.deletePlan(p.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openPlanDialog(BuildContext context) {
    String type = 'gun';
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    DateTime? date;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ders Planı Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Plan Türü'),
                  items: types.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v ?? 'gun'),
                ),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(date == null ? 'Tarih seç' : DateFormat('dd.MM.yyyy').format(date!)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100));
                    if (picked != null) setState(() => date = picked);
                  },
                ),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: 'İçerik'),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final err = await context.read<AppState>().addPlan(
                    type, titleCtrl.text.trim(), date, contentCtrl.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  if (err != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Hata: $err')));
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
