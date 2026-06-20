import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int sem = 1;
  String exam = 'w1';
  bool resultView = false;
  final numCtrl = TextEditingController(text: '1');
  final maxCtrl = TextEditingController(text: '5');
  final topicCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final qs = s.examQs(sem, exam);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text('🔬 Madde Analizi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1.Dönem')),
                ButtonSegment(value: 2, label: Text('2.Dönem')),
              ],
              selected: {sem},
              onSelectionChanged: (v) => setState(() => sem = v.first),
            ),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'w1', label: Text('Yazılı 1')),
                ButtonSegment(value: 'w2', label: Text('Yazılı 2')),
              ],
              selected: {exam},
              onSelectionChanged: (v) => setState(() => exam = v.first),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ToggleButtons(
          isSelected: [!resultView, resultView],
          onPressed: (i) => setState(() => resultView = i == 1),
          children: const [
            Padding(padding: EdgeInsets.all(8), child: Text('📋 Soru & Not Girişi')),
            Padding(padding: EdgeInsets.all(8), child: Text('📊 Analiz Sonuçları')),
          ],
        ),
        const SizedBox(height: 16),
        if (!resultView) ..._entryWidgets(s, qs) else ..._resultWidgets(s, qs),
      ],
    );
  }

  List<Widget> _entryWidgets(AppState s, List<ExamQuestion> qs) {
    final nextQ = qs.isEmpty ? 1 : qs.map((q) => q.qNumber).reduce((a, b) => a > b ? a : b) + 1;
    numCtrl.text = '$nextQ';
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Soru Tanımla', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                      width: 70,
                      child: TextField(
                          controller: numCtrl,
                          decoration: const InputDecoration(labelText: 'S.No'),
                          keyboardType: TextInputType.number)),
                  SizedBox(
                      width: 90,
                      child: TextField(
                          controller: maxCtrl,
                          decoration: const InputDecoration(labelText: 'Maks. Puan'),
                          keyboardType: TextInputType.number)),
                  SizedBox(
                      width: 180,
                      child: TextField(
                          controller: topicCtrl,
                          decoration: const InputDecoration(labelText: 'Konu (opsiyonel)'))),
                  FilledButton(
                    onPressed: () async {
                      final qn = int.tryParse(numCtrl.text);
                      final mx = double.tryParse(maxCtrl.text);
                      if (qn == null || qn < 1 || mx == null || mx <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Geçerli soru no / puan girin')));
                        return;
                      }
                      final err = await s.addQuestion(
                          sem, exam, qn, mx, topicCtrl.text.trim().isEmpty ? null : topicCtrl.text.trim());
                      if (err != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                      } else {
                        topicCtrl.clear();
                      }
                    },
                    child: const Text('+ Soru Ekle'),
                  ),
                ],
              ),
              if (qs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final q in qs)
                      Chip(
                        label: Text('S${q.qNumber} • ${q.maxPoints.toStringAsFixed(0)}p${q.topic != null ? ' • ${q.topic}' : ''}'),
                        onDeleted: () => s.deleteQuestion(q.id),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (qs.isEmpty)
        const Card(
            child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Henüz soru tanımlanmadı.'))))
      else
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Öğrenci')),
                  for (final q in qs) DataColumn(label: Text('S${q.qNumber}\n${q.maxPoints.toStringAsFixed(0)}p')),
                  const DataColumn(label: Text('Toplam')),
                ],
                rows: [
                  for (final st in s.students)
                    DataRow(cells: [
                      DataCell(Text(st.name)),
                      for (final q in qs)
                        DataCell(_QScoreCell(
                          key: ValueKey('${q.id}-${st.id}'),
                          questionId: q.id,
                          studentId: st.id,
                          maxPts: q.maxPoints,
                        )),
                      DataCell(Builder(builder: (context) {
                        final total = qs.fold<double>(
                            0, (sum, q) => sum + (s.qScore(q.id, st.id)?.score ?? 0));
                        return Text(total.toStringAsFixed(0),
                            style: const TextStyle(fontWeight: FontWeight.bold));
                      })),
                    ]),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _resultWidgets(AppState s, List<ExamQuestion> qs) {
    if (qs.isEmpty) {
      return [
        const Card(
            child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Önce soru tanımlayın.'))))
      ];
    }
    final totalMax = qs.fold<double>(0, (sum, q) => sum + q.maxPoints);
    final studentTotals = s.students
        .map((st) => (
              st,
              qs.fold<double>(0, (sum, q) => sum + (s.qScore(q.id, st.id)?.score ?? 0))
            ))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    final n27 = (s.students.length * 0.27).ceil().clamp(1, s.students.length);
    final upper = studentTotals.take(n27).toList();
    final lower = studentTotals.reversed.take(n27).toList();
    final allTotals = studentTotals.map((e) => e.$2).toList();
    final classAvg =
        allTotals.isEmpty ? 0 : allTotals.reduce((a, b) => a + b) / allTotals.length;

    return [
      Row(
        children: [
          Expanded(child: _statCard('${s.students.length}', 'Mevcut')),
          const SizedBox(width: 8),
          Expanded(child: _statCard(classAvg.toStringAsFixed(1), 'Ortalama')),
          const SizedBox(width: 8),
          Expanded(
              child: _statCard(
                  allTotals.isEmpty ? '0' : allTotals.reduce((a, b) => a > b ? a : b).toStringAsFixed(0),
                  'En Yüksek')),
          const SizedBox(width: 8),
          Expanded(
              child: _statCard(
                  allTotals.isEmpty ? '0' : allTotals.reduce((a, b) => a < b ? a : b).toStringAsFixed(0),
                  'En Düşük')),
        ],
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Soru')),
                DataColumn(label: Text('Ort.')),
                DataColumn(label: Text('Güçlük (p)')),
                DataColumn(label: Text('Seviye')),
                DataColumn(label: Text('Ayr. (d)')),
                DataColumn(label: Text('Yorum')),
              ],
              rows: [
                for (final q in qs)
                  DataRow(cells: () {
                    final vals = s.students
                        .map((st) => s.qScore(q.id, st.id)?.score)
                        .whereType<double>()
                        .toList();
                    if (vals.isEmpty) {
                      return [
                        DataCell(Text('S${q.qNumber}')),
                        const DataCell(Text('—')),
                        const DataCell(Text('—')),
                        const DataCell(Text('Veri yok')),
                        const DataCell(Text('—')),
                        const DataCell(Text('—')),
                      ];
                    }
                    final avg = vals.reduce((a, b) => a + b) / vals.length;
                    final p = avg / q.maxPoints;
                    String pLbl = p >= .70
                        ? 'Kolay'
                        : p >= .40
                            ? 'Orta'
                            : p >= .20
                                ? 'Zor'
                                : 'Çok Zor';
                    final upperAvg = upper.isEmpty
                        ? 0
                        : upper.fold<double>(
                                0, (sum, e) => sum + (s.qScore(q.id, e.$1.id)?.score ?? 0)) /
                            upper.length;
                    final lowerAvg = lower.isEmpty
                        ? 0
                        : lower.fold<double>(
                                0, (sum, e) => sum + (s.qScore(q.id, e.$1.id)?.score ?? 0)) /
                            lower.length;
                    final d = (upperAvg - lowerAvg) / q.maxPoints;
                    String dLbl = d >= .40
                        ? 'İyi ✓'
                        : d >= .30
                            ? 'Yeterli'
                            : d >= .20
                                ? 'Zayıf ⚠️'
                                : 'Çok Zayıf ✗';
                    return [
                      DataCell(Text('S${q.qNumber}')),
                      DataCell(Text(avg.toStringAsFixed(1))),
                      DataCell(Text(p.toStringAsFixed(2))),
                      DataCell(Text(pLbl)),
                      DataCell(Text(d.toStringAsFixed(2))),
                      DataCell(Text(dLbl)),
                    ];
                  }()),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Öğrenci')),
                DataColumn(label: Text('Toplam')),
                DataColumn(label: Text('%')),
              ],
              rows: [
                for (var i = 0; i < studentTotals.length; i++)
                  DataRow(cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Text(studentTotals[i].$1.name)),
                    DataCell(Text(studentTotals[i].$2.toStringAsFixed(0))),
                    DataCell(Text(totalMax > 0
                        ? '${(studentTotals[i].$2 / totalMax * 100).round()}%'
                        : '—')),
                  ]),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _statCard(String value, String label) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      );
}

class _QScoreCell extends StatefulWidget {
  final String questionId;
  final String studentId;
  final double maxPts;
  const _QScoreCell(
      {super.key, required this.questionId, required this.studentId, required this.maxPts});

  @override
  State<_QScoreCell> createState() => _QScoreCellState();
}

class _QScoreCellState extends State<_QScoreCell> {
  late TextEditingController ctrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final v = s.qScore(widget.questionId, widget.studentId)?.score;
    ctrl = TextEditingController(text: v?.toStringAsFixed(0) ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
        onSubmitted: (val) async {
          final nv = val.trim().isEmpty ? null : double.tryParse(val.trim());
          final err = await context
              .read<AppState>()
              .saveQScore(widget.questionId, widget.studentId, widget.maxPts, nv);
          if (err != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          } else {
            final clamped = nv == null ? null : (nv < 0 ? 0.0 : (nv > widget.maxPts ? widget.maxPts : nv));
            ctrl.text = clamped?.toStringAsFixed(0) ?? '';
          }
        },
      ),
    );
  }
}
