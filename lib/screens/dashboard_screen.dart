import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../main.dart';

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
      padding: const EdgeInsets.all(20),
      children: [
        const Text('🏠 Özet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1D2E))),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _StatBox(icon: Icons.groups_rounded, value: '${s.students.length}', label: 'Öğrenci', color: kAccent),
            _StatBox(
                icon: Icons.edit_note_rounded,
                value: '$missing1',
                label: '1.Dönem Notu Eksik',
                color: const Color(0xFFF5A623)),
            _StatBox(
                icon: Icons.trending_down_rounded,
                value: '$low',
                label: '1.Dönem Düşük (<50)',
                color: const Color(0xFFE05252)),
            _StatBox(
                icon: Icons.report_problem_rounded,
                value: '$noPass',
                label: 'Yılsonu Kalan',
                color: const Color(0xFFE05252)),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('👋 Hoş geldiniz',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                    'Soldaki menüden Sınıflarım, Öğrenciler, Not Defteri, Madde Analizi, Puan Sistemi, Ders Planları ve Not Merkezi\'ne ulaşabilirsiniz.',
                    style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatBox(
      {required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const Spacer(),
          Text(value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11.5, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
