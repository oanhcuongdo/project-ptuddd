/// Model chứa kết quả dịch thuật tức thì cho tin nhắn trong phòng Chat.
/// Phân hệ Chat Thực Chiến 1-1 - Dự án BuddyTalk (Nhóm 09 - 65KTPM).
class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final bool isSuccess;
  final String? errorMessage;
  final DateTime timestamp;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.isSuccess,
    this.errorMessage,
    required this.timestamp,
  });

  /// Khởi tạo kết quả dịch thành công
  factory TranslationResult.success({
    required String originalText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    return TranslationResult(
      originalText: originalText,
      translatedText: translatedText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      isSuccess: true,
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
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }

  /// Chuyển đổi sang Map để lưu trữ CSDL SQLite hoặc gửi qua Supabase
  Map<String, dynamic> toMap() {
    return {
      'original_text': originalText,
      'translated_text': translatedText,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'is_success': isSuccess ? 1 : 0,
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
      errorMessage: map['error_message'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
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

