import 'dart:math';

import '../models/learning_event.dart';
import '../models/lesson.dart';

/// Sinh sự kiện học tập giả cho [days] ngày gần nhất (giống `seed_dev.py` trên server).
///
/// Dùng để dựng trang chủ, thống kê, heatmap, huy hiệu khi chưa ai ghi sự kiện thật:
/// menu dev → "Tạo 30 ngày học giả", hoặc gọi thẳng trong test.
List<LearningEvent> generateDemoEvents(List<Lesson> lessons, {int days = 30, DateTime? now, int seed = 42}) {
  final rnd = Random(seed);
  final end = now ?? DateTime.now();
  final today = DateTime(end.year, end.month, end.day);
  final words = [for (final l in lessons) ...l.words];
  if (words.isEmpty) return const [];
  final chars = {for (final w in words) ...w.hanzi.split('')}.toList();
  final events = <LearningEvent>[];

  for (var back = days - 1; back >= 0; back--) {
    // Nghỉ một số ngày cũ để heatmap có khoảng trống; 5 ngày gần nhất luôn học (streak).
    if (back > 4 && rnd.nextDouble() < 0.25) continue;
    final day = today.subtract(Duration(days: back));
    var clock = day.add(Duration(hours: 19, minutes: rnd.nextInt(90)));
    if (back == 0 && clock.isAfter(end)) clock = end.subtract(const Duration(minutes: 30));
    void add(LearningEventType type, {int xp = 0, int sec = 30, double? score, String? ref, Map<String, dynamic>? data}) {
      events.add(LearningEvent(type: type, occurredAt: clock, xp: xp, durationSec: sec, score: score, refId: ref, data: data));
      clock = clock.add(Duration(seconds: sec));
    }

    for (var i = 0, n = 4 + rnd.nextInt(9); i < n; i++) {
      add(LearningEventType.srsReview, xp: 1, sec: 12, ref: words[rnd.nextInt(words.length)].key, data: {'quality': 2 + rnd.nextInt(4)});
    }
    for (var i = 0, n = 1 + rnd.nextInt(5); i < n; i++) {
      final score = 60 + rnd.nextInt(39);
      add(
        LearningEventType.pronunciationScored,
        xp: score >= 90 ? 5 : 2,
        sec: 40,
        score: score.toDouble(),
        ref: words[rnd.nextInt(words.length)].hanzi,
        data: {
          'tones': {for (final t in ['1', '2', '3', '4']) t: 55 + rnd.nextInt(46)},
        },
      );
    }
    for (var i = 0, n = rnd.nextInt(5); i < n; i++) {
      add(
        LearningEventType.characterWritten,
        xp: 2,
        sec: 60,
        score: (50 + rnd.nextInt(51)).toDouble(),
        ref: chars[rnd.nextInt(chars.length)],
        data: {'mode': rnd.nextBool() ? 'trace' : 'free', 'wrong_strokes': rnd.nextInt(4)},
      );
    }
    if (back == 20 || back == 12 || back == 3) {
      final lesson = lessons[min(lessons.length - 1, back == 3 ? 1 : 0)];
      add(LearningEventType.lessonCompleted, xp: 20, sec: 600, score: (75 + rnd.nextInt(24)).toDouble(), ref: lesson.code);
    }
    if (back % 6 == 1) {
      add(LearningEventType.aiSessionFinished, xp: 10, sec: 420, score: (60 + rnd.nextInt(36)).toDouble(), ref: 'demo-$back');
    }
  }
  return events;
}
