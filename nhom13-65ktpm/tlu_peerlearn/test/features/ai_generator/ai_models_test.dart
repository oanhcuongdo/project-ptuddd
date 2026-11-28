import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/flashcard_item.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/generated_set.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/quiz_question_item.dart';

void main() {
  group('AI Generator Models Tests', () {
    test('GeneratedSet serialization and draft status', () {
      final json = {
        'id': 'set-1',
        'room_id': 'room-1',
        'created_by': 'user-1',
        'title': 'Bộ ôn tập OOP Dart',
        'content_type': 'flashcard',
        'difficulty': 'medium',
        'topic': 'OOP',
        'status': 'draft',
        'version': 1,
        'created_at': '2026-11-20T10:00:00.000Z',
      };

      final set = GeneratedSet.fromJson(json);
      expect(set.isDraft, isTrue);
      expect(set.isPublished, isFalse);
      expect(set.isFlashcard, isTrue);
      expect(set.isQuiz, isFalse);

      final published = set.copyWith(status: 'published', publishedAt: DateTime.now());
      expect(published.isPublished, isTrue);
      expect(published.isDraft, isFalse);
    });

    test('FlashcardItem serialization', () {
      final card = FlashcardItem(
        id: 'c-1',
        setId: 'set-1',
        frontText: 'Polymorphism là gì?',
        backText: 'Tính đa hình trong lập trình hướng đối tượng',
        explanation: 'Cho phép các đối tượng khác nhau phản ứng với cùng một thông điệp',
      );

      final json = card.toJson();
      final fromJson = FlashcardItem.fromJson(json);
      expect(fromJson.frontText, 'Polymorphism là gì?');
      expect(fromJson.backText, 'Tính đa hình trong lập trình hướng đối tượng');
    });

    test('QuizQuestionItem serialization with 4 options', () {
      final question = QuizQuestionItem(
        id: 'q-1',
        quizId: 'quiz-1',
        questionText: 'Từ khóa nào định nghĩa hàm bất đồng bộ trong Dart?',
        options: ['async', 'await', 'future', 'stream'],
        correctIndex: 0,
        explanation: 'Từ khóa async dùng để khai báo một hàm bất đồng bộ',
      );

      final json = question.toJson();
      final fromJson = QuizQuestionItem.fromJson(json);
      expect(fromJson.options.length, 4);
      expect(fromJson.correctIndex, 0);
      expect(fromJson.options[fromJson.correctIndex], 'async');
    });
  });
}
