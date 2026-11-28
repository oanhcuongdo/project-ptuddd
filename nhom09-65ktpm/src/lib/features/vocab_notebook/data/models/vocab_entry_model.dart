/// Model ánh xạ bảng `public.vocab_notebook` trên Supabase Cloud.
/// Lưu trữ từ vựng cá nhân đã dịch trong phòng chat hoặc tra cứu thủ công.
class VocabEntryModel {
  final String id;
  final String userId;
  final String word;
  final String translatedMeaning;
  final String sourceLang;
  final String targetLang;
  final String exampleSentence;
  final bool isMastered;
  final DateTime createdAt;

  const VocabEntryModel({
    required this.id,
    required this.userId,
    required this.word,
    required this.translatedMeaning,
    this.sourceLang = 'en',
    this.targetLang = 'vi',
    this.exampleSentence = '',
    this.isMastered = false,
    required this.createdAt,
  });

  /// Kiểm tra từ vựng có kèm câu ví dụ ngữ cảnh hay không
  bool get hasExample => exampleSentence.trim().isNotEmpty;

  /// Khóa chuẩn hóa dùng để phát hiện từ trùng lặp trong cùng ngôn ngữ nguồn/đích
  String get dedupeKey =>
      '${sourceLang.trim().toLowerCase()}->${targetLang.trim().toLowerCase()}:${word.trim().toLowerCase()}';

  /// Nhãn cặp ngôn ngữ ngắn gọn (ví dụ: "EN → VI", "ZH → VI")
  String get languagePairLabel =>
      '${_shortLabel(sourceLang)} → ${_shortLabel(targetLang)}';

  static String _shortLabel(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '-');
    if (normalized.startsWith('zh')) return 'ZH';
    if (normalized.startsWith('en')) return 'EN';
    if (normalized.startsWith('vi')) return 'VI';
    if (normalized.isEmpty || normalized == 'auto') return 'AUTO';
    return normalized.toUpperCase();
  }

  VocabEntryModel copyWith({
    String? id,
    String? userId,
    String? word,
    String? translatedMeaning,
    String? sourceLang,
    String? targetLang,
    String? exampleSentence,
    bool? isMastered,
    DateTime? createdAt,
  }) {
    return VocabEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      word: word ?? this.word,
      translatedMeaning: translatedMeaning ?? this.translatedMeaning,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      isMastered: isMastered ?? this.isMastered,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Khởi tạo từ bản ghi Supabase
  factory VocabEntryModel.fromMap(Map<String, dynamic> map) {
    return VocabEntryModel(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      word: (map['word'] as String? ?? '').trim(),
      translatedMeaning: (map['translated_meaning'] as String? ?? '').trim(),
      sourceLang: (map['source_lang'] as String? ?? 'en').trim(),
      targetLang: (map['target_lang'] as String? ?? 'vi').trim(),
      exampleSentence: (map['example_sentence'] as String? ?? '').trim(),
      isMastered: map['is_mastered'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  /// Dữ liệu dùng để INSERT bản ghi mới lên bảng `vocab_notebook`
  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'word': word.trim(),
      'translated_meaning': translatedMeaning.trim(),
      'source_lang': sourceLang.trim().toLowerCase(),
      'target_lang': targetLang.trim().toLowerCase(),
      'example_sentence': exampleSentence.trim(),
      'is_mastered': isMastered,
    };
  }

  /// Dữ liệu dùng để UPDATE nghĩa, câu ví dụ hoặc trạng thái thuộc từ
  Map<String, dynamic> toUpdateMap() {
    return {
      'word': word.trim(),
      'translated_meaning': translatedMeaning.trim(),
      'source_lang': sourceLang.trim().toLowerCase(),
      'target_lang': targetLang.trim().toLowerCase(),
      'example_sentence': exampleSentence.trim(),
      'is_mastered': isMastered,
    };
  }

  /// Dữ liệu đầy đủ dùng cho kiểm thử hoặc tuần tự hóa cục bộ
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      ...toInsertMap(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VocabEntryModel &&
        other.id == id &&
        other.userId == userId &&
        other.word == word &&
        other.translatedMeaning == translatedMeaning &&
        other.sourceLang == sourceLang &&
        other.targetLang == targetLang &&
        other.exampleSentence == exampleSentence &&
        other.isMastered == isMastered;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        word,
        translatedMeaning,
        sourceLang,
        targetLang,
        exampleSentence,
        isMastered,
      );
}
