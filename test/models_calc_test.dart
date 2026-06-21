# Local unit tests for simple model calculations

This test file verifies Grade.average and MebLevel mapping without requiring Supabase.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ogretmen_dosyasi/models.dart';

void main() {
  test('Grade.average hesaplama doğru', () {
    final g = Grade(id: 'g1', studentId: 's1', semester: 1, w1: 80.0, w2: null, oral: null, perf: null, perf2: null, project: null, proj2: null);
    final avg = g.average;
    expect(avg, 80.0);
  });

  test('MebLevel mapping doğru', () {
    expect(MebLevel.of(90).label, 'Pekiyi');
    expect(MebLevel.of(75).label, 'İyi');
    expect(MebLevel.of(60).label, 'Orta');
    expect(MebLevel.of(52).label, 'Geçer');
    expect(MebLevel.of(40).label, 'Başarısız');
  });
}
```
