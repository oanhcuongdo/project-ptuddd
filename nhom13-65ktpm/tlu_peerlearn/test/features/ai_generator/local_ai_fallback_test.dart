import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/services/local_ai_fallback_generator.dart';

void main() {
  group('LocalAiFallbackGenerator Tests', () {
    const text = 'Flutter và Dart là công nghệ phát triển ứng dụng di động đa nền tảng chất lượng cao.';

    test('generates expected count of flashcards', () {
      final cards = LocalAiFallbackGenerator.generateFlashcards(
        documentText: text,
        count: 5,
        difficulty: 'medium',
        topic: 'Flutter',
      );
      expect(cards.length, 5);
      expect(cards.first.frontText, isNotEmpty);
      expect(cards.first.backText, isNotEmpty);
    });

    test('generates expected count of quiz questions with 4 options', () {
      final questions = LocalAiFallbackGenerator.generateQuiz(
        documentText: text,
        count: 6,
        difficulty: 'basic',
      );
      expect(questions.length, 6);
      expect(questions.first.options.length, 4);
      expect(questions.first.correctIndex, 0);
    });
  });
}
