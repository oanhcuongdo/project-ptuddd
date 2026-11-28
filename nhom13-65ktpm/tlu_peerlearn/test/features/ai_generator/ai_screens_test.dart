import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/generated_set.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/quiz_question_item.dart';
import 'package:tlu_peerlearn/features/ai_generator/screens/ai_draft_review_screen.dart';
import 'package:tlu_peerlearn/features/ai_generator/screens/generate_content_dialog.dart';
import 'package:tlu_peerlearn/features/documents/models/document_item.dart';

void main() {
  group('AI Generator Screens Tests', () {
    testWidgets('GenerateContentDialog renders options and slider', (tester) async {
      final docs = [
        DocumentItem(
          id: 'doc-1',
          roomId: 'r1',
          fileName: 'Lap_trinh_huong_doi_tuong.pdf',
          fileUrl: '',
          fileType: 'pdf',
          fileSize: 1024 * 1024,
          uploadedBy: 'u1',
          uploadedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenerateContentDialog(
              availableDocuments: docs,
              onGenerate: ({
                required documentIds,
                required contentType,
                required count,
                required difficulty,
                topic,
              }) async {},
            ),
          ),
        ),
      );

      expect(find.text('Tạo nội dung ôn tập bằng AI'), findsOneWidget);
      expect(find.text('Lap_trinh_huong_doi_tuong.pdf'), findsOneWidget);
      expect(find.text('Trắc nghiệm (Quiz)'), findsOneWidget);
      expect(find.text('Flashcard'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('AiDraftReviewScreen displays questions and publish button', (tester) async {
      final mockSet = GeneratedSet(
        id: 's1',
        roomId: 'r1',
        createdBy: 'u1',
        title: 'Đề kiểm tra thử',
        contentType: 'quiz',
        difficulty: 'medium',
        status: 'draft',
        createdAt: DateTime.now(),
      );

      final mockQuestions = [
        QuizQuestionItem(
          id: 'q1',
          quizId: 'quiz1',
          questionText: 'Tính đóng gói là gì?',
          options: ['A. Giấu thông tin', 'B. Kế thừa', 'C. Đa hình', 'D. Trừu tượng'],
          correctIndex: 0,
        ),
      ];

      var published = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AiDraftReviewScreen(
            generatedSet: mockSet,
            quizQuestions: mockQuestions,
            onPublish: () async => published = true,
          ),
        ),
      );

      expect(find.text('BẢN NHÁP (DRAFT)'), findsOneWidget);
      expect(find.text('Tính đóng gói là gì?'), findsOneWidget);
      expect(find.text('A. '), findsOneWidget);
      expect(find.text('Giấu thông tin'), findsOneWidget);

      await tester.tap(find.text('Phát hành cho phòng học (Publish)'));
      await tester.pumpAndSettle();
      expect(published, isTrue);
      expect(find.text('ĐÃ PHÁT HÀNH'), findsOneWidget);
    });
  });
}
