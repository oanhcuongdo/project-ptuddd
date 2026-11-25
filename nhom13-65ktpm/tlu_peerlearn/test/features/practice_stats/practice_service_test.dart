import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/quiz_question_item.dart';
import 'package:tlu_peerlearn/features/practice_stats/services/practice_service.dart';

void main() {
  group('PracticeService Unit Tests (Module 5 PRA)', () {
    late PracticeService service;

    setUp(() {
      service = PracticeService(null); // In-memory fallback
    });

    test('submitQuizAttempt calculates score correctly on 10-point scale (BR-08, PRA-02)',
        () async {
      const questions = [
        QuizQuestionItem(
          id: 'q1',
          quizId: 'quiz1',
          questionText: 'Khóa chính trong CSDL quan hệ là gì?',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 1, // B
        ),
        QuizQuestionItem(
          id: 'q2',
          quizId: 'quiz1',
          questionText: 'Câu lệnh truy vấn SQL là gì?',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 0, // A
        ),
      ];

      // Case 1: All correct (2/2) -> 10.0
      final attempt1 = await service.submitQuizAttempt(
        quizId: 'quiz1',
        userId: 'u1',
        questions: questions,
        selectedAnswers: {'q1': 1, 'q2': 0},
      );

      expect(attempt1.correctCount, 2);
      expect(attempt1.totalCount, 2);
      expect(attempt1.score, 10.0);

      // Case 2: 1 correct (1/2) -> 5.0
      final attempt2 = await service.submitQuizAttempt(
        quizId: 'quiz1',
        userId: 'u1',
        questions: questions,
        selectedAnswers: {'q1': 1, 'q2': 3}, // q2 wrong
      );

      expect(attempt2.correctCount, 1);
      expect(attempt2.totalCount, 2);
      expect(attempt2.score, 5.0);

      // Case 3: 0 correct (0/2) -> 0.0
      final attempt3 = await service.submitQuizAttempt(
        quizId: 'quiz1',
        userId: 'u1',
        questions: questions,
        selectedAnswers: {'q1': 0, 'q2': 2}, // both wrong
      );

      expect(attempt3.correctCount, 0);
      expect(attempt3.totalCount, 2);
      expect(attempt3.score, 0.0);
    });

    test('fetchQuizAnalytics returns correct structure for questions (PRA-03)', () async {
      const questions = [
        QuizQuestionItem(
          id: 'q1',
          quizId: 'quiz1',
          questionText: 'Khái niệm Normalization?',
          options: ['1NF', '2NF', '3NF', 'All'],
          correctIndex: 3,
        ),
      ];

      final analytics = await service.fetchQuizAnalytics('quiz1', questions);
      expect(analytics.quizId, 'quiz1');
      expect(analytics.questionStats.length, 1);
      expect(analytics.questionStats.first.questionText, 'Khái niệm Normalization?');
    });

    test('fetchPersonalSummary returns zeroed summary when client is null (PRA-04)', () async {
      final summary = await service.fetchPersonalSummary('u1');
      expect(summary.totalQuizzesTaken, 0);
      expect(summary.averageScore, 0.0);
      expect(summary.rememberedFlashcards, 0);
    });
  });
}
