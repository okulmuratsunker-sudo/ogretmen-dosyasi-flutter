import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Student> students = [];
  List<Grade> grades = [];
  List<ScoreEntry> scores = [];
  List<ScoreHistoryItem> scoreHistory = [];
  List<ExamQuestion> examQuestions = [];
  List<QuestionScore> questionScores = [];
  List<LessonPlan> plans = [];
  bool loading = false;

  Grade? gradeFor(String studentId, int semester) {
    try {
      return grades.firstWhere(
          (g) => g.studentId == studentId && g.semester == semester);
    } catch (_) {
      return null;
    }
  }

  ScoreEntry? scoreFor(String studentId) {
    try {
      return scores.firstWhere((s) => s.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  double? donemAvg(String studentId, int semester) =>
      gradeFor(studentId, semester)?.average;

  double? yilsonu(String studentId) {
    final d1 = donemAvg(studentId, 1);
    final d2 = donemAvg(studentId, 2);
    if (d1 == null && d2 == null) return null;
    if (d1 == null) return d2;
    if (d2 == null) return d1;
    return (d1 + d2) / 2;
  }

  List<ExamQuestion> examQs(int semester, String examType) {
    final list = examQuestions
        .where((q) => q.semester == semester && q.examType == examType)
        .toList();
    list.sort((a, b) => a.qNumber.compareTo(b.qNumber));
    return list;
  }

  QuestionScore? qScore(String questionId, String studentId) {
    try {
      return questionScores.firstWhere(
          (s) => s.questionId == questionId && s.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        supabase.from('teacher_students').select().order('name'),
        supabase.from('teacher_grades').select(),
        supabase.from('student_scores').select(),
        supabase
            .from('score_history')
            .select()
            .order('created_at', ascending: false),
        supabase
            .from('exam_questions')
            .select()
            .order('semester')
            .order('exam_type')
            .order('q_number'),
        supabase.from('question_scores').select(),
        supabase
            .from('teacher_plans')
            .select()
            .order('created_at', ascending: false),
      ]);
      students =
          (results[0] as List).map((e) => Student.fromMap(e)).toList();
      grades = (results[1] as List).map((e) => Grade.fromMap(e)).toList();
      scores = (results[2] as List).map((e) => ScoreEntry.fromMap(e)).toList();
      scoreHistory =
          (results[3] as List).map((e) => ScoreHistoryItem.fromMap(e)).toList();
      examQuestions =
          (results[4] as List).map((e) => ExamQuestion.fromMap(e)).toList();
      questionScores =
          (results[5] as List).map((e) => QuestionScore.fromMap(e)).toList();
      plans = (results[6] as List).map((e) => LessonPlan.fromMap(e)).toList();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> saveGrade(
      String studentId, int semester, String col, double? value) async {
    if (value != null && (value < 0 || value > 100)) {
      return 'Not 0-100 arasında olmalı';
    }
    var g = gradeFor(studentId, semester);
    try {
      if (g != null) {
        g.setKey(col, value);
        await supabase
            .from('teacher_grades')
            .update({col: value, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', g.id);
      } else {
        final row = {
          'student_id': studentId,
          'semester': semester,
          col: value,
        };
        final data = await supabase
            .from('teacher_grades')
            .insert(row)
            .select()
            .single();
        grades.add(Grade.fromMap(data));
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addScoreDelta(
      String studentId, double delta, String? note) async {
    try {
      var sc = scoreFor(studentId);
      final newVal = (sc?.score ?? 0) + delta;
      if (sc != null) {
        await supabase
            .from('student_scores')
            .update({
              'score': newVal,
              'updated_at': DateTime.now().toIso8601String()
            })
            .eq('id', sc.id);
        sc.score = newVal;
      } else {
        final data = await supabase
            .from('student_scores')
            .insert({'student_id': studentId, 'score': delta})
            .select()
            .single();
        scores.add(ScoreEntry.fromMap(data));
      }
      await supabase.from('score_history').insert(
          {'student_id': studentId, 'delta': delta, 'note': note ?? ''});
      scoreHistory.insert(
          0,
          ScoreHistoryItem(
              studentId: studentId,
              delta: delta,
              note: note,
              createdAt: DateTime.now()));
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> saveStudentNote(String studentId, String note) async {
    try {
      await supabase
          .from('teacher_students')
          .update({'notes': note})
          .eq('id', studentId);
      final st = students.firstWhere((s) => s.id == studentId);
      st.notes = note;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addQuestion(
      int semester, String examType, int qNumber, double maxPoints, String? topic) async {
    final exists = examQuestions.any((q) =>
        q.semester == semester && q.examType == examType && q.qNumber == qNumber);
    if (exists) return 'Bu soru numarası zaten var';
    try {
      final data = await supabase
          .from('exam_questions')
          .insert({
            'semester': semester,
            'exam_type': examType,
            'q_number': qNumber,
            'max_points': maxPoints,
            'topic': topic,
          })
          .select()
          .single();
      examQuestions.add(ExamQuestion.fromMap(data));
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> deleteQuestion(String id) async {
    await supabase.from('exam_questions').delete().eq('id', id);
    examQuestions.removeWhere((q) => q.id == id);
    questionScores.removeWhere((s) => s.questionId == id);
    notifyListeners();
  }

  Future<String?> saveQScore(
      String questionId, String studentId, double maxPts, double? value) async {
    double? nv = value;
    if (nv != null && nv < 0) nv = 0;
    if (nv != null && nv > maxPts) nv = maxPts;
    try {
      final existing = qScore(questionId, studentId);
      if (nv == null) {
        if (existing != null) {
          await supabase.from('question_scores').delete().eq('id', existing.id);
          questionScores.removeWhere((s) => s.id == existing.id);
        }
      } else if (existing != null) {
        await supabase
            .from('question_scores')
            .update({'score': nv})
            .eq('id', existing.id);
        existing.score = nv;
      } else {
        final data = await supabase
            .from('question_scores')
            .insert({
              'question_id': questionId,
              'student_id': studentId,
              'score': nv
            })
            .select()
            .single();
        questionScores.add(QuestionScore.fromMap(data));
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addPlan(String type, String title, DateTime? date, String? content) async {
    try {
      final data = await supabase
          .from('teacher_plans')
          .insert({
            'plan_type': type,
            'title': title,
            'date': date?.toIso8601String().split('T').first,
            'content': content,
          })
          .select()
          .single();
      plans.insert(0, LessonPlan.fromMap(data));
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> deletePlan(String id) async {
    await supabase.from('teacher_plans').delete().eq('id', id);
    plans.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
