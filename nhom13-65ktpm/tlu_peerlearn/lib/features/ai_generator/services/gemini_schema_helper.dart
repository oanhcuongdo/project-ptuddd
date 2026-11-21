class GeminiSchemaHelper {
  static const int minItems = 5;
  static const int maxItems = 20;
  static const int maxDocuments = 2; // BR-04

  /// Validates count of flashcards or quiz questions (must be between 5 and 20)
  static String? validateItemCount(int count) {
    if (count < minItems || count > maxItems) {
      return 'Số lượng phải từ $minItems đến $maxItems câu/thẻ.';
    }
    return null;
  }

  /// Validates selected documents count (must be 1 or 2 documents - BR-04)
  static String? validateSelectedDocuments(List<String> documentIds) {
    if (documentIds.isEmpty) {
      return 'Vui lòng chọn ít nhất 1 tài liệu để tạo nội dung.';
    }
    if (documentIds.length > maxDocuments) {
      return 'Chỉ được chọn tối đa $maxDocuments tài liệu mỗi lần (BR-04).';
    }
    return null;
  }

  /// JSON Schema for Gemini 2.5 Flash Structured Outputs (Flashcards)
  static Map<String, dynamic> get flashcardsJsonSchema => {
        'type': 'OBJECT',
        'properties': {
          'items': {
            'type': 'ARRAY',
            'items': {
              'type': 'OBJECT',
              'properties': {
                'front_text': {'type': 'STRING', 'description': 'Câu hỏi hoặc thuật ngữ mặt trước'},
                'back_text': {'type': 'STRING', 'description': 'Định nghĩa hoặc câu trả lời mặt sau'},
                'explanation': {'type': 'STRING', 'description': 'Giải thích chi tiết hoặc ví dụ'},
                'topic': {'type': 'STRING', 'description': 'Chủ đề'},
              },
              'required': ['front_text', 'back_text'],
            },
          },
        },
        'required': ['items'],
      };

  /// JSON Schema for Gemini 2.5 Flash Structured Outputs (Quiz)
  static Map<String, dynamic> get quizJsonSchema => {
        'type': 'OBJECT',
        'properties': {
          'questions': {
            'type': 'ARRAY',
            'items': {
              'type': 'OBJECT',
              'properties': {
                'question_text': {'type': 'STRING', 'description': 'Nội dung câu hỏi trắc nghiệm'},
                'options': {
                  'type': 'ARRAY',
                  'items': {'type': 'STRING'},
                  'description': 'Đúng 4 phương án lựa chọn A, B, C, D',
                },
                'correct_index': {
                  'type': 'INTEGER',
                  'description': 'Chỉ số phương án đúng từ 0 đến 3',
                },
                'explanation': {'type': 'STRING', 'description': 'Giải thích lý do đúng'},
                'topic': {'type': 'STRING', 'description': 'Chủ đề'},
              },
              'required': ['question_text', 'options', 'correct_index'],
            },
          },
        },
        'required': ['questions'],
      };

  /// Builds system prompt for Gemini AI
  static String buildPrompt({
    required String contentType, // 'flashcard' | 'quiz'
    required int count,
    required String difficulty, // 'basic' | 'medium' | 'advanced'
    String? topic,
    required String documentContext,
  }) {
    final typeName = contentType == 'flashcard' ? 'Flashcard (Thẻ ghi nhớ)' : 'câu hỏi trắc nghiệm 4 lựa chọn (Quiz)';
    return '''
Bạn là trợ lý AI chuyên môn học tập của trường Đại học Thủy Lợi (TLU).
Nhiệm vụ: Hãy tạo chính xác $count $typeName dựa trên ngữ cảnh tài liệu được cung cấp dưới đây.

Yêu cầu kỹ thuật:
- Mức độ khó: $difficulty
- Chủ đề trọng tâm: ${topic?.isNotEmpty == true ? topic : 'Toàn bộ nội dung tài liệu'}
- Ngôn ngữ: Tiếng Việt chuẩn mực, rõ ràng, chính xác.
${contentType == 'quiz' ? '- Mỗi câu hỏi phải có đúng 4 phương án, correct_index từ 0 đến 3.' : ''}

NỘI DUNG TÀI LIỆU NGUỒN:
$documentContext
''';
  }
}
