import '../models/flashcard_item.dart';
import '../models/quiz_question_item.dart';
import '../../documents/utils/topic_keyword_extractor.dart';

class LocalAiFallbackGenerator {
  /// Generates realistic flashcards from document text when offline/testing
  static List<FlashcardItem> generateFlashcards({
    required String documentText,
    required int count,
    required String difficulty,
    String? topic,
  }) {
    final keywords = TopicKeywordExtractor.extractKeywords(documentText, topN: count + 2);
    final cards = <FlashcardItem>[];

    for (var i = 0; i < count; i++) {
      final kw = keywords.isNotEmpty && i < keywords.length
          ? keywords[i]
          : 'Khái niệm #${i + 1}';

      cards.add(
        FlashcardItem(
          id: 'card-$i',
          setId: '',
          frontText: 'Định nghĩa và vai trò của "$kw" trong học phần là gì?',
          backText: '"$kw" là một thành phần trọng tâm trong tài liệu học tập, hỗ trợ nắm vững kiến thức môn học.',
          explanation: 'Dựa trên nội dung tài liệu trích xuất từ buổi học.',
          topic: topic ?? kw,
          difficulty: difficulty,
        ),
      );
    }
    return cards;
  }

  /// Generates realistic 4-option quiz questions from document text when offline/testing
  static List<QuizQuestionItem> generateQuiz({
    required String documentText,
    required int count,
    required String difficulty,
    String? topic,
  }) {
    final keywords = TopicKeywordExtractor.extractKeywords(documentText, topN: count + 4);
    final questions = <QuizQuestionItem>[];

    for (var i = 0; i < count; i++) {
      final kw = keywords.isNotEmpty && i < keywords.length
          ? keywords[i]
          : 'Kiến thức #${i + 1}';

      questions.add(
        QuizQuestionItem(
          id: 'quiz-q-$i',
          quizId: '',
          questionText: 'Khẳng định nào sau đây là ĐÚNG NHẤT về "$kw"?',
          options: [
            'A. Là khái niệm cốt lõi được định nghĩa trong học phần',
            'B. Chỉ áp dụng cho hệ cơ sở dữ liệu phi quan hệ',
            'C. Không liên quan đến lập trình ứng dụng',
            'D. Là giao thức mạng tầng ứng dụng',
          ],
          correctIndex: 0,
          explanation: '"$kw" là nội dung chính được trích xuất trực tiếp từ tài liệu ôn tập của phòng học.',
          topic: topic ?? kw,
          difficulty: difficulty,
        ),
      );
    }
    return questions;
  }
}
