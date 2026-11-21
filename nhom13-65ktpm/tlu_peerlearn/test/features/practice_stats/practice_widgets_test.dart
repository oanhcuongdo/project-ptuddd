import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/flashcard_item.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/generated_set.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/quiz_question_item.dart';
import 'package:tlu_peerlearn/features/practice_stats/models/flashcard_study_item.dart';
import 'package:tlu_peerlearn/features/practice_stats/models/quiz_attempt.dart';
import 'package:tlu_peerlearn/features/practice_stats/screens/flashcard_study_screen.dart';
import 'package:tlu_peerlearn/features/practice_stats/screens/quiz_analytics_screen.dart';
import 'package:tlu_peerlearn/features/practice_stats/screens/quiz_taking_screen.dart';
import 'package:tlu_peerlearn/features/practice_stats/widgets/flashcard_card.dart';

void main() {
  group('Practice & Stats Widgets Tests (PRA)', () {
    testWidgets('FlashcardCard flips between front and back on tap (PRA-01)',
        (tester) async {
      const card = FlashcardItem(
        id: 'fc1',
        setId: 'set1',
        frontText: 'Khóa chính là gì?',
        backText: 'Là tập thuộc tính xác định duy nhất một bộ',
        explanation: 'Khóa chính không được mang giá trị null',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlashcardCard(flashcard: card),
          ),
        ),
      );

      // Mặt trước
      expect(find.text('MẶT TRƯỚC (CÂU HỎI)'), findsOneWidget);
      expect(find.text('Khóa chính là gì?'), findsOneWidget);
      expect(find.text('MẶT SAU (ĐÁP ÁN)'), findsNothing);

      // Chạm để lật
      await tester.tap(find.byType(FlashcardCard));
      await tester.pump();

      // Mặt sau
      expect(find.text('MẶT SAU (ĐÁP ÁN)'), findsOneWidget);
      expect(find.text('Là tập thuộc tính xác định duy nhất một bộ'), findsOneWidget);
      expect(find.text('Giải thích: Khóa chính không được mang giá trị null'), findsOneWidget);
    });

    testWidgets('FlashcardStudyScreen displays progress and toggles remembered (PRA-01)',
        (tester) async {
      final set = GeneratedSet(
        id: 'set1',
        roomId: 'room1',
        createdBy: 'u1',
        title: 'Ôn tập SQL Cơ bản',
        contentType: 'flashcard',
        difficulty: 'basic',
        status: 'published',
        createdAt: DateTime.now(),
      );

      final cards = [
        const FlashcardStudyItem(
          flashcard: FlashcardItem(
            id: 'fc1',
            setId: 'set1',
            frontText: 'Câu 1',
            backText: 'Đáp án 1',
          ),
          isRemembered: false,
        ),
        const FlashcardStudyItem(
          flashcard: FlashcardItem(
            id: 'fc2',
            setId: 'set1',
            frontText: 'Câu 2',
            backText: 'Đáp án 2',
          ),
          isRemembered: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FlashcardStudyScreen(
              generatedSet: set,
              userId: 'u1',
              initialCards: cards,
            ),
          ),
        ),
      );

      expect(find.text('Đã thuộc 1/2 thẻ'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Câu 1'), findsOneWidget);

      // Bấm "Đã nhớ thẻ" cho Câu 1
      await tester.tap(find.text('Đã nhớ thẻ'));
      await tester.pump();

      expect(find.text('Đã thuộc 2/2 thẻ'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('QuizTakingScreen allows selecting option and submits for score (PRA-02)',
        (tester) async {
      final set = GeneratedSet(
        id: 'set_quiz_1',
        roomId: 'room1',
        createdBy: 'u1',
        title: 'Trắc nghiệm CSDL 15 phút',
        contentType: 'quiz',
        difficulty: 'medium',
        status: 'published',
        createdAt: DateTime.now(),
      );

      const questions = [
        QuizQuestionItem(
          id: 'q1',
          quizId: 'quiz1',
          questionText: 'Thứ tự thực thi mệnh đề SQL nào là đầu tiên?',
          options: ['FROM', 'WHERE', 'SELECT', 'GROUP BY'],
          correctIndex: 0, // FROM
          explanation: 'FROM được thực thi đầu tiên để xác định bảng nguồn',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizTakingScreen(
              generatedSet: set,
              quizId: 'quiz1',
              userId: 'u1',
              initialQuestions: questions,
            ),
          ),
        ),
      );

      expect(find.text('Thứ tự thực thi mệnh đề SQL nào là đầu tiên?'), findsOneWidget);

      // Chọn đáp án A. FROM
      await tester.tap(find.text('A. FROM'));
      await tester.pump();

      // Nộp bài
      await tester.tap(find.text('Nộp bài kiểm tra'));
      await tester.pumpAndSettle();

      // Kiểm tra kết quả hiển thị (PRA-02: Điểm số, đúng/sai, giải thích)
      expect(find.text('10.0 / 10'), findsOneWidget);
      expect(find.text('Đúng 1/1 câu hỏi'), findsOneWidget);
      expect(find.text('Câu 1: Đúng'), findsOneWidget);
      expect(find.text('Giải thích: FROM được thực thi đầu tiên để xác định bảng nguồn'), findsOneWidget);
    });

    testWidgets('QuizAnalyticsScreen renders average score and per-question accuracy (PRA-03)',
        (tester) async {
      final set = GeneratedSet(
        id: 'set_quiz_1',
        roomId: 'room1',
        createdBy: 'u1',
        title: 'Trắc nghiệm CSDL',
        contentType: 'quiz',
        difficulty: 'medium',
        status: 'published',
        createdAt: DateTime.now(),
      );

      const summary = QuizAnalyticsSummary(
        quizId: 'quiz1',
        totalAttempts: 5,
        averageScore: 8.4,
        highestScore: 10.0,
        questionStats: [
          QuestionStat(
            questionId: 'q1',
            questionText: 'Câu hỏi về JOIN',
            correctCount: 2,
            totalCount: 5,
            correctRate: 0.40, // 40% < 50% => CẦN GIẢI ĐÁP
          ),
          QuestionStat(
            questionId: 'q2',
            questionText: 'Câu hỏi về PRIMARY KEY',
            correctCount: 5,
            totalCount: 5,
            correctRate: 1.0,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizAnalyticsScreen(
              generatedSet: set,
              quizId: 'quiz1',
              initialSummary: summary,
            ),
          ),
        ),
      );

      expect(find.text('8.4'), findsOneWidget);
      expect(find.text('10.0'), findsOneWidget);
      expect(find.text('CẦN GIẢI ĐÁP'), findsOneWidget);
      expect(find.text('40% (2/5)'), findsOneWidget);
      expect(find.text('100% (5/5)'), findsOneWidget);
    });
  });
}
