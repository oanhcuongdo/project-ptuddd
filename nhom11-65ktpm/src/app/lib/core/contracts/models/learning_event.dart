import 'dart:math';

/// Loại sự kiện học tập. Tên `wire` trùng với server (`app/models/progress.py`).
enum LearningEventType {
  lessonCompleted('lesson_completed'),
  srsReview('srs_review'),
  pronunciationScored('pronunciation_scored'),
  characterWritten('character_written'),
  aiSessionFinished('ai_session_finished'),
  quizCompleted('quiz_completed'),
  placementCompleted('placement_completed'),
  studySession('study_session');

  final String wire;
  const LearningEventType(this.wire);

  static LearningEventType fromWire(String s) =>
      values.firstWhere((t) => t.wire == s, orElse: () => LearningEventType.studySession);
}

/// Một hoạt động học đã xong: ôn một thẻ, chấm một câu phát âm, viết một chữ...
///
/// Mỗi tính năng ghi sự kiện qua `progressServiceProvider`; trang chủ, thống kê,
/// streak, XP, huy hiệu, bảng xếp hạng chỉ đọc sự kiện (xem docs/hop-dong-du-lieu.md).
class LearningEvent {
  /// UUID v4 sinh trên máy: gửi lại nhiều lần server vẫn không ghi trùng.
  final String id;
  final LearningEventType type;
  final DateTime occurredAt;
  final int xp;
  final int durationSec;

  /// Điểm 0..100 (nếu hoạt động có chấm điểm).
  final double? score;

  /// Đối tượng liên quan: mã bài, `Word.key`, chữ Hán, id phiên AI...
  final String? refId;
  final Map<String, dynamic>? data;

  LearningEvent({
    String? id,
    required this.type,
    DateTime? occurredAt,
    this.xp = 0,
    this.durationSec = 0,
    this.score,
    this.refId,
    this.data,
  }) : id = id ?? newUuid(),
       occurredAt = occurredAt ?? DateTime.now();

  /// Định dạng gửi `POST /api/events` (snake_case như các API khác).
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.wire,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'xp': xp,
    'duration_sec': durationSec,
    'score': ?score,
    'ref_id': ?refId,
    'data': ?data,
  };

  factory LearningEvent.fromJson(Map<String, dynamic> j) => LearningEvent(
    id: j['id'] as String,
    type: LearningEventType.fromWire(j['type'] as String),
    occurredAt: DateTime.parse(j['occurred_at'] as String).toLocal(),
    xp: j['xp'] as int? ?? 0,
    durationSec: j['duration_sec'] as int? ?? 0,
    score: (j['score'] as num?)?.toDouble(),
    refId: j['ref_id'] as String?,
    data: j['data'] as Map<String, dynamic>?,
  );
}

final _rnd = Random.secure();

/// UUID v4 ngẫu nhiên (không cần thêm package).
String newUuid() {
  final b = List<int>.generate(16, (_) => _rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
