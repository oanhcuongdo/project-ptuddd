import '../scoring/feedback.dart';
import '../scoring/phonemes.dart';
import '../scoring/weak_sounds.dart';
import 'app_database.dart';
import 'lessons.dart';

/// Bài nên luyện tiếp: bài ứng với âm hay sai nhất mà bài đó chưa thành thạo hết;
/// chưa có dữ liệu lỗi thì lấy bài đầu tiên chưa thành thạo. Null nếu đã thành
/// thạo mọi bài.
({Lesson lesson, String reason})? recommendLesson(
    List<WeakSound> weak, Map<String, LessonStat> stats) {
  bool done(Lesson l) => masteredCount(l, stats[l.id]?.itemBest ?? const {}) == l.items.length;

  for (final w in weak) {
    final id = suggestionForPhoneme(w.phoneme)?.lessonId; // âm chưa có mẹo thì bỏ qua
    if (id == null) continue;
    final l = lessonById(id);
    if (!done(l)) {
      return (
        lesson: l,
        reason: 'Bạn hay sai âm /${ipa(w.phoneme)}/ (${(w.rate * 100).round()}% số lần)',
      );
    }
  }
  for (final l in lessons) {
    if (!done(l)) return (lesson: l, reason: 'Bài tiếp theo chưa thành thạo');
  }
  return null;
}
