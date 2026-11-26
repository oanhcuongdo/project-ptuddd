/// Kết quả chấm phát âm: CHUNG một định dạng cho engine offline (#13) và API
/// online Azure (#14), để màn phản hồi (#15) không cần biết kết quả từ đâu.
///
/// JSON (snake_case) xem docs/hop-dong-du-lieu.md, mục 4.
library;

/// Một âm tiết tách thành thanh mẫu / vận mẫu / thanh điệu. `tone`: 1–4, 5 = thanh nhẹ.
class SyllableParts {
  final String initial;
  final String finalPart;
  final int tone;

  const SyllableParts({required this.initial, required this.finalPart, required this.tone});

  factory SyllableParts.fromJson(Map<String, dynamic> j) =>
      SyllableParts(initial: j['initial'] as String? ?? '', finalPart: j['final'] as String? ?? '', tone: j['tone'] as int? ?? 5);

  Map<String, dynamic> toJson() => {'initial': initial, 'final': finalPart, 'tone': tone};

  @override
  String toString() => '$initial$finalPart$tone';
}

/// ok = xanh (chuẩn), warn = vàng (chấp nhận được), error = đỏ (sai).
enum SyllableStatus { ok, warn, error }

/// Loại lỗi ở một âm tiết (khớp ma trận lỗi người Việt ở #13 và mẹo ở #22).
enum PronunciationError { initial, finalPart, tone, missing, extra }

class SyllableScore {
  final String hanzi;
  final SyllableParts expected;

  /// Âm người học đọc được nhận ra; null nếu bỏ sót âm tiết.
  final SyllableParts? actual;
  final double score;
  final SyllableStatus status;
  final List<PronunciationError> errors;

  const SyllableScore({
    required this.hanzi,
    required this.expected,
    required this.actual,
    required this.score,
    required this.status,
    this.errors = const [],
  });

  factory SyllableScore.fromJson(Map<String, dynamic> j) => SyllableScore(
    hanzi: j['hanzi'] as String,
    expected: SyllableParts.fromJson(j['expected'] as Map<String, dynamic>),
    actual: j['actual'] == null ? null : SyllableParts.fromJson(j['actual'] as Map<String, dynamic>),
    score: (j['score'] as num).toDouble(),
    status: SyllableStatus.values.byName(j['status'] as String),
    errors: [for (final e in (j['errors'] as List? ?? const [])) _errorFromWire(e as String)],
  );

  Map<String, dynamic> toJson() => {
    'hanzi': hanzi,
    'expected': expected.toJson(),
    'actual': actual?.toJson(),
    'score': score,
    'status': status.name,
    'errors': [for (final e in errors) _errorToWire(e)],
  };
}

PronunciationError _errorFromWire(String s) => s == 'final' ? PronunciationError.finalPart : PronunciationError.values.byName(s);
String _errorToWire(PronunciationError e) => e == PronunciationError.finalPart ? 'final' : e.name;

enum ScoringSource { online, offline }

class PronunciationResult {
  /// Điểm tổng 0..100.
  final double overall;
  final double accuracy;
  final double tone;
  final double fluency;
  final double completeness;
  final ScoringSource source;

  /// Câu nhận dạng được từ giọng người học (có thể rỗng).
  final String recognizedText;
  final List<SyllableScore> syllables;

  const PronunciationResult({
    required this.overall,
    required this.accuracy,
    required this.tone,
    required this.fluency,
    required this.completeness,
    required this.source,
    required this.syllables,
    this.recognizedText = '',
  });

  factory PronunciationResult.fromJson(Map<String, dynamic> j) => PronunciationResult(
    overall: (j['overall'] as num).toDouble(),
    accuracy: (j['accuracy'] as num).toDouble(),
    tone: (j['tone'] as num).toDouble(),
    fluency: (j['fluency'] as num).toDouble(),
    completeness: (j['completeness'] as num).toDouble(),
    source: ScoringSource.values.byName(j['source'] as String),
    recognizedText: j['recognized_text'] as String? ?? '',
    syllables: [for (final s in (j['syllables'] as List)) SyllableScore.fromJson(s as Map<String, dynamic>)],
  );

  Map<String, dynamic> toJson() => {
    'overall': overall,
    'accuracy': accuracy,
    'tone': tone,
    'fluency': fluency,
    'completeness': completeness,
    'source': source.name,
    'recognized_text': recognizedText,
    'syllables': [for (final s in syllables) s.toJson()],
  };
}

/// File ghi âm (WAV 16 kHz mono) do [VoiceRecorder] trả về.
class Recording {
  /// Đường dẫn file; null với bản ghi giả.
  final String? path;
  final Duration duration;

  const Recording({required this.path, required this.duration});
}
