import 'translation_language.dart';

/// Model chứa kết quả dịch thuật tức thì cho tin nhắn trong phòng Chat.
/// Phân hệ Trợ lý Dịch thuật Tức thì - Dự án BuddyTalk (Nhóm 09 - 65KTPM).
class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final bool isSuccess;
  final bool fromCache;
  final String? errorMessage;
  final DateTime timestamp;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.isSuccess,
    this.fromCache = false,
    this.errorMessage,
    required this.timestamp,
  });

  /// Khởi tạo kết quả dịch thành công
  factory TranslationResult.success({
    required String originalText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
    bool fromCache = false,
  }) {
    return TranslationResult(
      originalText: originalText,
      translatedText: translatedText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      isSuccess: true,
      fromCache: fromCache,
      timestamp: DateTime.now(),
    );
  }

  /// Khởi tạo kết quả dịch thất bại khi gặp sự cố mạng hoặc timeout
  factory TranslationResult.failure({
    required String originalText,
    required String errorMessage,
    String sourceLanguage = 'auto',
    String targetLanguage = 'vi',
  }) {
    return TranslationResult(
      originalText: originalText,
      translatedText: originalText, // Giữ nguyên câu gốc nếu lỗi
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      isSuccess: false,
      fromCache: false,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }

  /// Ngôn ngữ nguồn đã chuẩn hóa theo enum [TranslationLanguage]
  TranslationLanguage get sourceLangEnum =>
      TranslationLanguage.fromCode(sourceLanguage);

  /// Ngôn ngữ đích đã chuẩn hóa theo enum [TranslationLanguage]
  TranslationLanguage get targetLangEnum =>
      TranslationLanguage.fromCode(targetLanguage);

  /// Kiểm tra ngôn ngữ nguồn và ngôn ngữ đích có trùng nhau hay không
  bool get isSameLanguage =>
      sourceLangEnum != TranslationLanguage.auto &&
      sourceLangEnum == targetLangEnum;

  /// Kiểm tra kết quả có bản dịch hợp lệ để hiển thị
  bool get hasTranslation => isSuccess && translatedText.trim().isNotEmpty;

  /// Nhãn cặp ngôn ngữ ngắn gọn hiển thị trên giao diện (ví dụ: "EN → VI")
  String get languagePairLabel =>
      '${sourceLangEnum.shortLabel} → ${targetLangEnum.shortLabel}';

  /// Tạo bản sao với các thuộc tính tùy chỉnh (ví dụ đánh dấu `fromCache = true`)
  TranslationResult copyWith({
    String? originalText,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
    bool? isSuccess,
    bool? fromCache,
    String? errorMessage,
    DateTime? timestamp,
  }) {
    return TranslationResult(
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      isSuccess: isSuccess ?? this.isSuccess,
      fromCache: fromCache ?? this.fromCache,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Chuyển đổi sang Map để lưu trữ hoặc đồng bộ dữ liệu
  Map<String, dynamic> toMap() {
    return {
      'original_text': originalText,
      'translated_text': translatedText,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'is_success': isSuccess ? 1 : 0,
      'from_cache': fromCache ? 1 : 0,
      'error_message': errorMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Khởi tạo từ Map (CSDL)
  factory TranslationResult.fromMap(Map<String, dynamic> map) {
    return TranslationResult(
      originalText: map['original_text'] as String? ?? '',
      translatedText: map['translated_text'] as String? ?? '',
      sourceLanguage: map['source_language'] as String? ?? 'auto',
      targetLanguage: map['target_language'] as String? ?? 'vi',
      isSuccess: (map['is_success'] == 1 || map['is_success'] == true),
      fromCache: (map['from_cache'] == 1 || map['from_cache'] == true),
      errorMessage: map['error_message'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return '[$sourceLanguage -> $targetLanguage] "$originalText" => "$translatedText"';
    }
    return 'Translation Failed: $errorMessage ("$originalText")';
  }
}
