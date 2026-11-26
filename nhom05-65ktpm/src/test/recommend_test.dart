import 'package:english_pronunciation_app/data/app_database.dart';
import 'package:english_pronunciation_app/data/lessons.dart';
import 'package:english_pronunciation_app/data/recommend.dart';
import 'package:english_pronunciation_app/scoring/weak_sounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Bài đã thành thạo hết: mọi mục đạt điểm tối đa.
  LessonStat mastered(String id) => LessonStat(
      10, 100, 100, {for (final i in lessonById(id).items) i: 100});

  test('âm hay sai nhất quyết định bài gợi ý', () {
    final r = recommendLesson([const WeakSound('TH', 6, 10)], {})!;
    expect(r.lesson.id, 'th');
    expect(r.reason, contains('θ'));
    expect(r.reason, contains('60%'));
  });

  test('bỏ qua bài đã thành thạo, chuyển sang âm sai kế tiếp', () {
    final r = recommendLesson(
        [const WeakSound('TH', 6, 10), const WeakSound('R', 3, 10)], {'th': mastered('th')})!;
    expect(r.lesson.id, 'rl');
  });

  test('âm chưa có mẹo (HH) bị bỏ qua, rơi về bài đầu chưa thành thạo', () {
    final r = recommendLesson([const WeakSound('HH', 5, 5)], {'th': mastered('th')})!;
    expect(r.lesson.id, lessons[1].id);
    expect(r.reason, contains('chưa thành thạo'));
  });

  test('chưa có dữ liệu: gợi ý bài đầu tiên', () {
    expect(recommendLesson([], {})!.lesson.id, lessons.first.id);
  });

  test('thành thạo mọi bài thì không gợi ý nữa', () {
    final all = {for (final l in lessons) l.id: mastered(l.id)};
    expect(recommendLesson([const WeakSound('TH', 6, 10)], all), isNull);
  });
}
