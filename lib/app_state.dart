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
  List<SchoolClass> classes = [];
  List<ClassroomScore> classroomScores = [];
  bool loading = false;

  List<String> get classNames {
    final fromStudents = students.map((s) => s.className).whereType<String>();
    final fromClasses = classes.map((c) => c.name);
    return {...fromStudents, ...fromClasses}.toList()..sort();
  }

  List<Student> studentsInClass(String className) {
    final list = students.where((s) => s.className == className).toList();
    list.sort((a, b) =>
        (int.tryParse(a.studentNumber ?? '') ?? 0)
            .compareTo(int.tryParse(b.studentNumber ?? '') ?? 0));
    return list;
  }

  ClassroomScore? classroomScoreFor(String studentId, int semester) {
    try {
      return classroomScores.firstWhere(
          (c) => c.studentId == studentId && c.semester == semester);
    } catch (_) {
      return null;
    }
  }

  double? writtenAvg(String studentId, int semester) {
    final g = gradeFor(studentId, semester);
    if (g == null) return null;
    final vals = [g.w1, g.w2].whereType<double>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double? calcOral(String studentId, int semester) {
    final avg = writtenAvg(studentId, semester);
    if (avg == null) return null;
    final cls = classroomScoreFor(studentId, semester)?.classroomScore ?? 0;
    var v = avg + cls / 2;
    if (v > 100) v = 100;
    if (v < 0) v = 0;
    return v.roundToDouble();
  }

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
        supabase.from('teacher_classes').select().order('name'),
        supabase.from('nm_classroom_scores').select(),
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
      classes = (results[7] as List).map((e) => SchoolClass.fromMap(e)).toList();
      classroomScores =
          (results[8] as List).map((e) => ClassroomScore.fromMap(e)).toList();
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

  // ── Sınıflarım ──
  Future<String?> createClass(String name) async {
    if (classNames.contains(name)) return 'Bu sınıf zaten var';
    try {
      final data =
          await supabase.from('teacher_classes').insert({'name': name}).select().single();
      classes.add(SchoolClass.fromMap(data));
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteClass(String name) async {
    try {
      final ids = studentsInClass(name).map((s) => s.id).toList();
      if (ids.isNotEmpty) {
        await supabase.from('teacher_students').delete().inFilter('id', ids);
      }
      final still = await supabase
          .from('teacher_students')
          .select('id')
          .eq('class_name', name)
          .limit(1);
      if ((still as List).isNotEmpty) {
        return 'Bazı öğrenciler silinemedi (yetki sorunu olabilir).';
      }
      students.removeWhere((s) => s.className == name);
      grades.removeWhere((g) => ids.contains(g.studentId));
      scores.removeWhere((s) => ids.contains(s.studentId));
      scoreHistory.removeWhere((h) => ids.contains(h.studentId));
      classroomScores.removeWhere((c) => ids.contains(c.studentId));
      final classRow = classes.where((c) => c.name == name).toList();
      if (classRow.isNotEmpty) {
        await supabase.from('teacher_classes').delete().eq('id', classRow.first.id);
        classes.removeWhere((c) => c.name == name);
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addStudentToClass(
      String className, String studentNumber, String name) async {
    final dup = students.any((s) =>
        s.className == className && s.studentNumber == studentNumber);
    if (dup) return 'Bu sınıfta $studentNumber numaralı öğrenci zaten var';
    try {
      final data = await supabase
          .from('teacher_students')
          .insert({
            'name': name,
            'student_number': studentNumber,
            'class_name': className,
          })
          .select()
          .single();
      students.add(Student.fromMap(data));
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> importStudentsToClass(String className, List<ImportRow> rows,
      {int? semester}) async {
    int added = 0;
    int gradesWritten = 0;
    final dups = <String>[];
    for (final row in rows) {
      final existing = students
          .where((s) => s.className == className && s.studentNumber == row.no)
          .toList();
      String? studentId;
      if (existing.isNotEmpty) {
        dups.add(row.no);
        studentId = existing.first.id;
      } else {
        try {
          final data = await supabase
              .from('teacher_students')
              .insert({
                'name': row.name,
                'student_number': row.no,
                'class_name': className,
              })
              .select()
              .single();
          final st = Student.fromMap(data);
          students.add(st);
          studentId = st.id;
          added++;
        } catch (e) {
          dups.add('${row.no} (hata)');
          continue;
        }
      }
      if (semester != null) {
        final fields = {
          'w1': row.y1,
          'w2': row.y2,
          'perf': row.perf1,
          'perf2': row.perf2,
          'project': row.proje1,
          'proj2': row.proje2,
        };
        for (final entry in fields.entries) {
          if (entry.value == null) continue;
          final err = await saveGrade(studentId, semester, entry.key, entry.value);
          if (err == null) gradesWritten++;
        }
      }
    }
    notifyListeners();
    if (added == 0 && dups.isEmpty) return 'Geçerli satır bulunamadı';
    var msg = '✓ $added yeni öğrenci eklendi';
    if (gradesWritten > 0) msg += ', $gradesWritten not Not Defteri\'ne işlendi';
    if (dups.isNotEmpty) msg += '. Mevcut/atlanan: ${dups.join(', ')}';
    return msg;
  }

  Future<String?> deleteStudent(String studentId) async {
    try {
      final ids = [studentId];
      await supabase.from('teacher_students').delete().inFilter('id', ids);
      final still = await supabase
          .from('teacher_students')
          .select('id')
          .eq('id', studentId)
          .limit(1);
      if ((still as List).isNotEmpty) {
        return 'Kayıt silinemedi (yetki sorunu olabilir).';
      }
      students.removeWhere((s) => s.id == studentId);
      grades.removeWhere((g) => g.studentId == studentId);
      scores.removeWhere((s) => s.studentId == studentId);
      scoreHistory.removeWhere((h) => h.studentId == studentId);
      classroomScores.removeWhere((c) => c.studentId == studentId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Not Merkezi ──
  Future<String?> setClassroomScore(
      String studentId, int semester, double? value) async {
    try {
      final existing = classroomScoreFor(studentId, semester);
      if (existing != null) {
        await supabase
            .from('nm_classroom_scores')
            .update({'classroom_score': value})
            .eq('id', existing.id);
        existing.classroomScore = value;
      } else {
        final data = await supabase
            .from('nm_classroom_scores')
            .insert({
              'student_id': studentId,
              'semester': semester,
              'classroom_score': value,
            })
            .select()
            .single();
        classroomScores.add(ClassroomScore.fromMap(data));
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> setOralManual(
      String studentId, int semester, double? value) async {
    final err = await saveGrade(studentId, semester, 'oral', value);
    if (err != null) return err;
    try {
      final existing = classroomScoreFor(studentId, semester);
      if (existing != null) {
        await supabase
            .from('nm_classroom_scores')
            .update({'is_manual_oral': true})
            .eq('id', existing.id);
        existing.isManualOral = true;
      } else {
        final data = await supabase
            .from('nm_classroom_scores')
            .insert({
              'student_id': studentId,
              'semester': semester,
              'is_manual_oral': true,
            })
            .select()
            .single();
        classroomScores.add(ClassroomScore.fromMap(data));
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resetOralToAuto(String studentId, int semester) async {
    final calc = calcOral(studentId, semester);
    if (calc == null) return 'Yazılı notu olmadan otomatik hesaplanamaz';
    final err = await saveGrade(studentId, semester, 'oral', calc);
    if (err != null) return err;
    final existing = classroomScoreFor(studentId, semester);
    if (existing != null) {
      await supabase
          .from('nm_classroom_scores')
          .update({'is_manual_oral': false})
          .eq('id', existing.id);
      existing.isManualOral = false;
      notifyListeners();
    }
    return null;
  }

  Future<String?> resetStudentGrade(String studentId, int semester) async {
    final g = gradeFor(studentId, semester);
    if (g == null) return 'Bu dönem için not yok';
    try {
      await supabase.from('teacher_grades').delete().eq('id', g.id);
      grades.removeWhere((x) => x.id == g.id);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resetClassGrades(String className, int semester) async {
    final ids = studentsInClass(className).map((s) => s.id).toList();
    final targetGradeIds = grades
        .where((g) => g.semester == semester && ids.contains(g.studentId))
        .map((g) => g.id)
        .toList();
    if (targetGradeIds.isEmpty) return 'Sıfırlanacak not yok';
    try {
      await supabase
          .from('teacher_grades')
          .delete()
          .inFilter('id', targetGradeIds);
      grades.removeWhere((g) => targetGradeIds.contains(g.id));
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
