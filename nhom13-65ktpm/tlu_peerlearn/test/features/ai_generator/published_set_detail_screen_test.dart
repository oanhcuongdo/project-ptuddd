import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/flashcard_item.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/generated_set.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/quiz_question_item.dart';
import 'package:tlu_peerlearn/features/ai_generator/screens/published_set_detail_screen.dart';

void main() {
  group('PublishedSetDetailScreen Tests', () {
    testWidgets('renders published quiz questions with answer explanation', (tester) async {
      final set = GeneratedSet(
        id: 's1',
        roomId: 'r1',
        createdBy: 'u1',
        title: 'Đề thi trắc nghiệm Dart',
        contentType: 'quiz',
        difficulty: 'medium',
        status: 'published',
        createdAt: DateTime.now(),
      );

      final questions = [
        QuizQuestionItem(
          id: 'q1',
          quizId: 'quiz1',
          questionText: 'Tính năng nào sau đây là của Dart?',
          options: ['Null safety', 'Header files', 'Pointers', 'Multiple inheritance'],
          correctIndex: 0,
          explanation: 'Dart hỗ trợ Sound Null Safety từ phiên bản 2.12',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: PublishedSetDetailScreen(
            set: set,
            questions: questions,
          ),
        ),
      );

      expect(find.text('Đề thi trắc nghiệm Dart'), findsOneWidget);
      expect(find.text('ĐÃ PHÁT HÀNH'), findsOneWidget);
      expect(find.text('Câu 1: Tính năng nào sau đây là của Dart?'), findsOneWidget);
      expect(find.text('Null safety'), findsOneWidget);
      expect(find.text('Giải thích: Dart hỗ trợ Sound Null Safety từ phiên bản 2.12'), findsOneWidget);
    });

    testWidgets('flips flashcard on tap', (tester) async {
      final set = GeneratedSet(
        id: 's2',
        roomId: 'r1',
        createdBy: 'u1',
        title: 'Bộ thẻ OOP',
        contentType: 'flashcard',
        difficulty: 'basic',
        status: 'published',
        createdAt: DateTime.now(),
      );

      final cards = [
        FlashcardItem(
          id: 'c1',
          setId: 's2',
          frontText: 'Encapsulation là gì?',
          backText: 'Tính đóng gói thông tin và phương thức trong lớp',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: PublishedSetDetailScreen(
            set: set,
            flashcards: cards,
          ),
        ),
      );

      expect(find.text('Encapsulation là gì?'), findsOneWidget);
      expect(find.text('Tính đóng gói thông tin và phương thức trong lớp'), findsNothing);

      // Tap to flip
      await tester.tap(find.text('Encapsulation là gì?'));
      await tester.pumpAndSettle();

      expect(find.text('Tính đóng gói thông tin và phương thức trong lớp'), findsOneWidget);
    });
  });
}
