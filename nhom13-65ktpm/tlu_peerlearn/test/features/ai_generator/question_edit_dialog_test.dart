import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/quiz_question_item.dart';
import 'package:tlu_peerlearn/features/ai_generator/widgets/question_edit_dialog.dart';

void main() {
  testWidgets('QuestionEditDialog allows modifying question text and options', (tester) async {
    final original = QuizQuestionItem(
      id: '1',
      quizId: 'q',
      questionText: 'Câu hỏi ban đầu',
      options: ['Phương án A', 'Phương án B', 'Phương án C', 'Phương án D'],
      correctIndex: 0,
    );

    QuizQuestionItem? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionEditDialog(
            question: original,
            onSave: (q) => saved = q,
          ),
        ),
      ),
    );

    expect(find.text('Chỉnh sửa câu hỏi'), findsOneWidget);
    expect(find.text('Câu hỏi ban đầu'), findsOneWidget);

    // Enter new question text
    await tester.enterText(find.byType(TextFormField).first, 'Câu hỏi đã sửa');

    // Tap Save
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(saved?.questionText, 'Câu hỏi đã sửa');
  });
}
