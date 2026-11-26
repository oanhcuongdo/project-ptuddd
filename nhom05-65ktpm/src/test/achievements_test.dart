import 'package:english_pronunciation_app/data/achievements.dart';
import 'package:english_pronunciation_app/data/app_database.dart';
import 'package:english_pronunciation_app/data/lessons.dart';
import 'package:english_pronunciation_app/scoring/rate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Set<String> unlocked({
    int bestStreak = 0,
    int attempts = 0,
    Map<String, LessonStat> lessonStats = const {},
    Rate? rate,
  }) =>
      {
        for (final a in achievements(
            bestStreak: bestStreak, attempts: attempts, lessonStats: lessonStats, rate: rate))
          if (a.unlocked) a.title,
      };

  LessonStat full(String id, {int score = 100}) =>
      LessonStat(5, score.toDouble(), score, {for (final i in lessonById(id).items) i: score});

  test('người mới chưa có huy hiệu nào', () {
    expect(unlocked(), isEmpty);
  });

  test('huy hiệu chuỗi ngày mở theo mốc 3/7/30', () {
    expect(unlocked(bestStreak: 3), {'Khởi động'});
    expect(unlocked(bestStreak: 7), {'Khởi động', 'Một tuần bền bỉ'});
    expect(unlocked(bestStreak: 30), contains('Thói quen thép'));
  });

  test('huy hiệu số lượt nói mở theo mốc 50/200', () {
    expect(unlocked(attempts: 49), isEmpty);
    expect(unlocked(attempts: 50), {'Chăm nói'});
    expect(unlocked(attempts: 200), {'Chăm nói', 'Nói không ngừng'});
  });

  test('điểm 90+ chỉ cần một bài có điểm cao nhất từ 90', () {
    expect(unlocked(lessonStats: {'th': const LessonStat(1, 90, 90, {})}), {'Điểm 90+'});
    expect(unlocked(lessonStats: {'th': const LessonStat(1, 89, 89, {})}), isEmpty);
  });

  test('xong một bài khác xong tất cả', () {
    final one = unlocked(lessonStats: {'th': full('th')});
    expect(one, containsAll(['Xong một bài', 'Điểm 90+']));
    expect(one, isNot(contains('Xong tất cả')));
    final all = unlocked(lessonStats: {for (final l in lessons) l.id: full(l.id)});
    expect(all, contains('Xong tất cả'));
  });

  test('bài mới đạt 79 điểm một mục thì chưa xong bài', () {
    final th = lessonById('th');
    final almost = LessonStat(5, 90, 100,
        {for (final i in th.items) i: 100, th.items.first: masteryScore - 1});
    expect(unlocked(lessonStats: {'th': almost}), isNot(contains('Xong một bài')));
  });

  test('huy hiệu trình độ cần rate Intermediate trở lên', () {
    expect(unlocked(rate: const Rate(60, Level.elementary, 20)), isEmpty);
    expect(unlocked(rate: const Rate(72, Level.intermediate, 20)), {'Trình độ Intermediate'});
    expect(unlocked(rate: const Rate(90, Level.advanced, 20)), {'Trình độ Intermediate'});
  });
}
