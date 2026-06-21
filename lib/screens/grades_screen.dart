import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

const _gradeCols = [
  ['w1', 'Yazılı 1'],
  ['w2', 'Yazılı 2'],
  ['oral', 'Sözlü'],
  ['perf', 'Perf. 1'],
  ['perf2', 'Perf. 2'],
  ['project', 'Proje 1'],
  ['proj2', 'Proje 2'],
];

class _GradesScreenState extends State<GradesScreen> {
  int sem = 1;
  String query = '';
  String? classFilter;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final classes = s.classNames;
    if (classFilter != null && !classes.contains(classFilter)) classFilter = null;
    var list = s.students
        .where((st) => query.isEmpty || st.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (classFilter != null) {
      list = list.where((st) => st.className == classFilter).toList();
    }
    list.sort((a, b) =>
        (int.tryParse(a.studentNumber ?? '') ?? 0)
            .compareTo(int.tryParse(b.studentNumber ?? '') ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Text('📝 Not Defteri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1. Dönem')),
                  ButtonSegment(value: 2, label: Text('2. Dönem')),
                ],
                selected: {sem},
                onSelectionChanged: (s) => setState(() => sem = s.first),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tümü'),
                selected: classFilter == null,
                onSelected: (_) => setState(() => classFilter = null),
              ),
              for (final c in classes)
                ChoiceChip(
                  label: Text(c),
                  selected: classFilter == c,
                  onSelected: (_) => setState(() => classFilter = c),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Öğrenci ara…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DataTable(
              columns: [
                const DataColumn(label: Text('Öğrenci')),
                const DataColumn(label: Text('No')),
                for (final c in _gradeCols) DataColumn(label: Text(c[1])),
                const DataColumn(label: Text('Dönem Notu')),
              ],
              rows: [
                for (final st in list)
                  DataRow(cells: [
                    DataCell(Text(st.name)),
                    DataCell(Text(st.studentNumber ?? '—')),
                    for (final c in _gradeCols)
                      DataCell(_GradeCell(
                        key: ValueKey('${st.id}-$sem-${c[0]}'),
                        studentId: st.id,
                        semester: sem,
                        col: c[0],
                      )),
                    DataCell(Builder(builder: (context) {
                      final dn = s.donemAvg(st.id, sem);
                      return Text(dn?.toStringAsFixed(0) ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.bold));
                    })),
                  ]),
              ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('💡 Notu yazıp Enter\'a basın — otomatik kaydedilir.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ],
    );
  }
}

class _GradeCell extends StatefulWidget {
  final String studentId;
  final int semester;
  final String col;
  const _GradeCell(
      {super.key, required this.studentId, required this.semester, required this.col});

  @override
  State<_GradeCell> createState() => _GradeCellState();
}

class _GradeCellState extends State<_GradeCell> {
  late TextEditingController ctrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final v = s.gradeFor(widget.studentId, widget.semester)?[widget.col];
    ctrl = TextEditingController(text: v?.toStringAsFixed(0) ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
        onSubmitted: (val) async {
          final nv = val.trim().isEmpty ? null : double.tryParse(val.trim());
          final err = await context
              .read<AppState>()
              .saveGrade(widget.studentId, widget.semester, widget.col, nv);
          if (err != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          }
        },
      ),
    );
  }
}
