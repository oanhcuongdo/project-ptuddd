import '../fake_implementation.dart';
import '../lesson_repository.dart';
import '../models/learning_event.dart';
import '../models/lesson.dart';
import '../models/path.dart';
import '../path_repository.dart';

/// Bản giả: dựng bản đồ từ danh sách bài (gom theo cấp độ thành các chặng) và
/// tính trạng thái, sao từ sự kiện `lesson_completed` / `quiz_completed`.
///
/// Không ghi sự kiện nào: `lesson_completed` do màn Bài học (#19) ghi.
/// Bản thật sẽ gọi `GET /api/path`.
class FakePathRepository with FakeImplementation implements PathRepository {
  FakePathRepository(this._lessons, this._events);

  final LessonRepository _lessons;
  final List<LearningEvent> _events;

  static const _levelOrder = ['PINYIN', 'HSK1', 'HSK2'];
  static const _levelTitles = {
    'PINYIN': 'Ngữ âm Pinyin',
    'HSK1': 'HSK 1',
    'HSK2': 'HSK 2',
  };

  @override
  Future<PathMap> loadPath() async {
    final lessons = await _lessons.lessons();

    // Gom bài theo cấp độ, giữ thứ tự PINYIN -> HSK1 -> HSK2 (cấp lạ xếp sau).
    final byLevel = <String, List<Lesson>>{};
    for (final l in lessons) {
      byLevel.putIfAbsent(l.level, () => []).add(l);
    }
    final levels = byLevel.keys.toList()
      ..sort((a, b) {
        int rank(String x) {
          final i = _levelOrder.indexOf(x);
          return i < 0 ? _levelOrder.length : i;
        }

        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.compareTo(b);
      });

    final stages = <PathStage>[
      for (var i = 0; i < levels.length; i++)
        PathStage(
          id: i + 1,
          order: i + 1,
          level: levels[i],
          title: 'Chặng ${i + 1} · ${_levelTitles[levels[i]] ?? levels[i]}',
          nodes: [
            for (final l in byLevel[levels[i]]!)
              PathNode(
                id: l.id,
                title: l.title,
                order: l.order,
                lessonId: l.id,
              ),
          ],
        ),
    ];

    return buildPathMap(stages, _bestScores(lessons));
  }

  /// Điểm cao nhất của từng node (khóa = id node = id bài trong bản giả).
  Map<int, double> _bestScores(List<Lesson> lessons) {
    final idByCode = {for (final l in lessons) l.code: l.id};
    final best = <int, double>{};

    void keepMax(int nodeId, double score) {
      final old = best[nodeId];
      if (old == null || score > old) best[nodeId] = score;
    }

    for (final e in _events) {
      final score = e.score;
      final ref = e.refId;
      if (score == null || ref == null) continue;
      switch (e.type) {
        case LearningEventType.lessonCompleted:
          // ref_id là mã bài (Lesson.code); chấp nhận thêm id số cho chắc.
          final id = idByCode[ref] ?? int.tryParse(ref);
          if (id != null) keepMax(id, score);
        case LearningEventType.quizCompleted:
          // ref_id là id node (vd. "4" hoặc "node-4").
          final m = RegExp(r'(\d+)$').firstMatch(ref);
          if (m != null) keepMax(int.parse(m.group(1)!), score);
        default:
          break;
      }
    }
    return best;
  }
}