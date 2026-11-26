import '../scoring/rate.dart';
import 'app_database.dart';
import 'lessons.dart';

class Achievement {
  final String title;
  final String description;
  final bool unlocked;
  const Achievement(this.title, this.description, this.unlocked);
}

/// Huy hiệu tính thẳng từ thống kê hiện có (không lưu thêm gì vào CSDL), nên
/// luôn khớp với dữ liệu và không cần di chuyển CSDL khi thêm huy hiệu mới.
List<Achievement> achievements({
  required int bestStreak,
  required int attempts,
  required Map<String, LessonStat> lessonStats,
  Rate? rate,
}) {
  bool mastered(Lesson l) =>
      masteredCount(l, lessonStats[l.id]?.itemBest ?? const {}) == l.items.length;

  return [
    Achievement('Khởi động', 'Luyện 3 ngày liên tiếp', bestStreak >= 3),
    Achievement('Một tuần bền bỉ', 'Luyện 7 ngày liên tiếp', bestStreak >= 7),
    Achievement('Thói quen thép', 'Luyện 30 ngày liên tiếp', bestStreak >= 30),
    Achievement('Chăm nói', 'Đạt 50 lượt nói', attempts >= 50),
    Achievement('Nói không ngừng', 'Đạt 200 lượt nói', attempts >= 200),
    Achievement('Điểm 90+', 'Có một lượt nói đạt từ 90 điểm',
        lessonStats.values.any((s) => s.bestScore >= 90)),
    Achievement('Xong một bài', 'Thành thạo mọi mục của một bài học', lessons.any(mastered)),
    Achievement('Xong tất cả', 'Thành thạo mọi bài học', lessons.every(mastered)),
    Achievement('Trình độ Intermediate', 'Đạt rate từ ${Level.intermediate.minRate} trở lên',
        rate != null && rate.level.index >= Level.intermediate.index),
  ];
}
