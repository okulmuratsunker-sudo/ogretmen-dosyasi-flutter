class ImportRow {
  final String no;
  final String name;
  final double? y1;
  final double? y2;
  final double? perf1;
  final double? perf2;
  final double? proje1;
  final double? proje2;

  ImportRow({
    required this.no,
    required this.name,
    this.y1,
    this.y2,
    this.perf1,
    this.perf2,
    this.proje1,
    this.proje2,
  });
}

class SchoolClass {
  final String id;
  final String name;

  SchoolClass({required this.id, required this.name});

  factory SchoolClass.fromMap(Map<String, dynamic> m) =>
      SchoolClass(id: m['id'], name: m['name']);
}

class ClassroomScore {
  final String id;
  final String studentId;
  final int semester;
  double? classroomScore;
  bool isManualOral;

  ClassroomScore({
    required this.id,
    required this.studentId,
    required this.semester,
    this.classroomScore,
    this.isManualOral = false,
  });

  factory ClassroomScore.fromMap(Map<String, dynamic> m) => ClassroomScore(
        id: m['id'],
        studentId: m['student_id'],
        semester: m['semester'],
        classroomScore: (m['classroom_score'] as num?)?.toDouble(),
        isManualOral: m['is_manual_oral'] ?? false,
      );
}

class Student {
  final String id;
  String name;
  String? studentNumber;
  String? className;
  String? notes;

  Student({
    required this.id,
    required this.name,
    this.studentNumber,
    this.className,
    this.notes,
  });

  factory Student.fromMap(Map<String, dynamic> m) => Student(
        id: m['id'],
        name: m['name'] ?? '',
        studentNumber: m['student_number'],
        className: m['class_name'],
        notes: m['notes'],
      );
}

class Grade {
  final String id;
  final String studentId;
  final int semester;
  double? w1, w2, oral, perf, perf2, project, proj2;

  Grade({
    required this.id,
    required this.studentId,
    required this.semester,
    this.w1,
    this.w2,
    this.oral,
    this.perf,
    this.perf2,
    this.project,
    this.proj2,
  });

  factory Grade.fromMap(Map<String, dynamic> m) => Grade(
        id: m['id'],
        studentId: m['student_id'],
        semester: m['semester'],
        w1: (m['w1'] as num?)?.toDouble(),
        w2: (m['w2'] as num?)?.toDouble(),
        oral: (m['oral'] as num?)?.toDouble(),
        perf: (m['perf'] as num?)?.toDouble(),
        perf2: (m['perf2'] as num?)?.toDouble(),
        project: (m['project'] as num?)?.toDouble(),
        proj2: (m['proj2'] as num?)?.toDouble(),
      );

  double? get average {
    final vals = [w1, w2, oral, perf, perf2, project, proj2]
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double? operator [](String key) {
    switch (key) {
      case 'w1':
        return w1;
      case 'w2':
        return w2;
      case 'oral':
        return oral;
      case 'perf':
        return perf;
      case 'perf2':
        return perf2;
      case 'project':
        return project;
      case 'proj2':
        return proj2;
    }
    return null;
  }

  void setKey(String key, double? v) {
    switch (key) {
      case 'w1':
        w1 = v;
        break;
      case 'w2':
        w2 = v;
        break;
      case 'oral':
        oral = v;
        break;
      case 'perf':
        perf = v;
        break;
      case 'perf2':
        perf2 = v;
        break;
      case 'project':
        project = v;
        break;
      case 'proj2':
        proj2 = v;
        break;
    }
  }
}

class ScoreEntry {
  final String id;
  final String studentId;
  double score;

  ScoreEntry({required this.id, required this.studentId, required this.score});

  factory ScoreEntry.fromMap(Map<String, dynamic> m) => ScoreEntry(
        id: m['id'],
        studentId: m['student_id'],
        score: (m['score'] as num?)?.toDouble() ?? 0,
      );
}

class ScoreHistoryItem {
  final String studentId;
  final double delta;
  final String? note;
  final DateTime createdAt;

  ScoreHistoryItem({
    required this.studentId,
    required this.delta,
    this.note,
    required this.createdAt,
  });

  factory ScoreHistoryItem.fromMap(Map<String, dynamic> m) => ScoreHistoryItem(
        studentId: m['student_id'],
        delta: (m['delta'] as num).toDouble(),
        note: m['note'],
        createdAt: DateTime.parse(m['created_at']),
      );
}

class ExamQuestion {
  final String id;
  final int semester;
  final String examType;
  final int qNumber;
  final double maxPoints;
  final String? topic;

  ExamQuestion({
    required this.id,
    required this.semester,
    required this.examType,
    required this.qNumber,
    required this.maxPoints,
    this.topic,
  });

  factory ExamQuestion.fromMap(Map<String, dynamic> m) => ExamQuestion(
        id: m['id'],
        semester: m['semester'],
        examType: m['exam_type'],
        qNumber: m['q_number'],
        maxPoints: (m['max_points'] as num).toDouble(),
        topic: m['topic'],
      );
}

class QuestionScore {
  final String id;
  final String questionId;
  final String studentId;
  double score;

  QuestionScore({
    required this.id,
    required this.questionId,
    required this.studentId,
    required this.score,
  });

  factory QuestionScore.fromMap(Map<String, dynamic> m) => QuestionScore(
        id: m['id'],
        questionId: m['question_id'],
        studentId: m['student_id'],
        score: (m['score'] as num).toDouble(),
      );
}

class LessonPlan {
  final String id;
  final String planType;
  final String title;
  final DateTime? date;
  final String? content;
  final DateTime createdAt;

  LessonPlan({
    required this.id,
    required this.planType,
    required this.title,
    this.date,
    this.content,
    required this.createdAt,
  });

  factory LessonPlan.fromMap(Map<String, dynamic> m) => LessonPlan(
        id: m['id'],
        planType: m['plan_type'],
        title: m['title'],
        date: m['date'] != null ? DateTime.tryParse(m['date']) : null,
        content: m['content'],
        createdAt: DateTime.parse(m['created_at']),
      );
}

class MebLevel {
  final String label;
  final bool fail;
  final bool warn;

  MebLevel(this.label, {this.fail = false, this.warn = false});

  static MebLevel of(double? n) {
    if (n == null) return MebLevel('—');
    if (n >= 85) return MebLevel('Pekiyi');
    if (n >= 70) return MebLevel('İyi');
    if (n >= 55) return MebLevel('Orta', warn: true);
    if (n >= 50) return MebLevel('Geçer', warn: true);
    return MebLevel('Başarısız', fail: true);
  }
}
