import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final missing1 = s.students.where((st) {
      final g = s.gradeFor(st.id, 1);
      return g == null || (g.w1 == null && g.w2 == null);
    }).length;
    final low = s.students.where((st) {
      final a = s.donemAvg(st.id, 1);
      return a != null && a < 50;
    }).length;
    final noPass = s.students.where((st) {
      final y = s.yilsonu(st.id);
      return y != null && y < 50;
    }).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('🏠 Özet',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _StatBox(value: '${s.students.length}', label: 'Öğrenci', color: null),
            _StatBox(
                value: '$missing1',
                label: '1.Dönem Notu Eksik',
                color: Colors.orange),
            _StatBox(
                value: '$low',
                label: '1.Dönem Düşük (<50)',
                color: Colors.red),
            _StatBox(
                value: '$noPass', label: 'Yılsonu Kalan', color: Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📅 Hoş geldiniz',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                    'Soldaki menüden öğrenciler, not defteri, madde analizi, puan sistemi ve ders planlarına ulaşabilirsiniz.',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  const _StatBox({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color ?? Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
