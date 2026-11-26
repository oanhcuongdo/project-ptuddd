/// Nội dung bài học, dùng chung cho Bài học (#19), Flashcard (#20), Lộ trình (#29),
/// Kiểm tra (#30, #32) và Trợ lý AI (#8–#10).
///
/// Khớp định dạng file `data/lessons/<cấp>/lesson-XX.json`
/// (xem docs/hop-dong-du-lieu.md, mục 2).
library;

class WordExample {
  final String hanzi;
  final String pinyin;
  final String meaningVi;

  const WordExample({required this.hanzi, required this.pinyin, required this.meaningVi});

  factory WordExample.fromJson(Map<String, dynamic> j) => WordExample(
    hanzi: j['hanzi'] as String,
    pinyin: j['pinyin'] as String? ?? '',
    meaningVi: j['meaningVi'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'hanzi': hanzi, 'pinyin': pinyin, 'meaningVi': meaningVi};
}

class Word {
  /// Mã ổn định trong bài, vd. "ni-hao".
  final String code;
  final String hanzi;
  final String pinyin;
  final String? hanViet;
  final String meaningVi;
  final WordExample? example;

  /// Mã bài chứa từ này, vd. "hsk1-greetings-01".
  final String lessonCode;

  const Word({
    required this.code,
    required this.hanzi,
    required this.pinyin,
    required this.meaningVi,
    required this.lessonCode,
    this.hanViet,
    this.example,
  });

  /// Khóa duy nhất toàn hệ thống (dùng cho thẻ SRS, sự kiện...).
  String get key => '$lessonCode/$code';

  factory Word.fromJson(Map<String, dynamic> j, {required String lessonCode}) => Word(
    code: j['id'] as String,
    hanzi: j['hanzi'] as String,
    pinyin: j['pinyin'] as String,
    hanViet: j['hanViet'] as String?,
    meaningVi: j['meaningVi'] as String,
    lessonCode: lessonCode,
    example: j['example'] == null ? null : WordExample.fromJson(j['example'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'id': code,
    'hanzi': hanzi,
    'pinyin': pinyin,
    'hanViet': hanViet,
    'meaningVi': meaningVi,
    if (example != null) 'example': example!.toJson(),
  };
}

class GrammarPoint {
  final String id;
  final String pattern;
  final String explanationVi;
  final List<String> examples;

  const GrammarPoint({required this.id, required this.pattern, required this.explanationVi, this.examples = const []});

  factory GrammarPoint.fromJson(Map<String, dynamic> j) => GrammarPoint(
    id: j['id'] as String,
    pattern: j['pattern'] as String,
    explanationVi: j['explanationVi'] as String? ?? '',
    examples: [for (final e in (j['examples'] as List? ?? const [])) e as String],
  );
}

class Lesson {
  /// Id trên server (bảng `lessons`). Với dữ liệu mẫu offline = thứ tự nạp (1, 2, 3...)
  /// giống hệt id mà `seed_dev.py` tạo trên CSDL mới.
  final int id;

  /// Mã ổn định, vd. "hsk1-greetings-01".
  final String code;
  final String level; // PINYIN | HSK1 | HSK2
  final int order;
  final String title;
  final String? topic;
  final String? description;
  final List<Word> words;
  final List<GrammarPoint> grammarPoints;
  final int contentVersion;

  const Lesson({
    required this.id,
    required this.code,
    required this.level,
    required this.order,
    required this.title,
    required this.words,
    this.topic,
    this.description,
    this.grammarPoints = const [],
    this.contentVersion = 1,
  });

  factory Lesson.fromJson(Map<String, dynamic> j, {required int id}) {
    final code = j['id'] as String;
    return Lesson(
      id: id,
      code: code,
      level: j['level'] as String? ?? 'HSK1',
      order: j['order'] as int? ?? 0,
      title: j['title'] as String,
      topic: j['topic'] as String?,
      description: j['description'] as String?,
      contentVersion: j['contentVersion'] as int? ?? 1,
      words: [
        for (final w in (j['vocabulary'] as List? ?? const []))
          Word.fromJson(w as Map<String, dynamic>, lessonCode: code),
      ],
      grammarPoints: [
        for (final g in (j['grammarPoints'] as List? ?? const [])) GrammarPoint.fromJson(g as Map<String, dynamic>),
      ],
    );
  }
}
