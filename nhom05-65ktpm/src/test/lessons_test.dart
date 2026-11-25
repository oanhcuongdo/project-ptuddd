import 'package:english_pronunciation_app/data/lessons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mỗi bài có ít nhất 6 mục luyện', () {
    for (final l in lessons) {
      expect(l.items.length, greaterThanOrEqualTo(6), reason: l.id);
    }
  });

  test('không có mục trùng trong cùng một bài (điểm cao nhất tính theo câu mẫu)', () {
    for (final l in lessons) {
      expect(l.items.toSet().length, l.items.length, reason: l.id);
    }
  });

  test('id bài học là duy nhất và lessonById tìm đúng', () {
    expect(lessons.map((l) => l.id).toSet().length, lessons.length);
    for (final l in lessons) {
      expect(lessonById(l.id), same(l));
    }
  });
}
