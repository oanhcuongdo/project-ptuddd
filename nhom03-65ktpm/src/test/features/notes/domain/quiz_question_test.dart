import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/notes/domain/entities/quiz_question.dart';

void main() {
  test('đọc câu hỏi hợp lệ có bốn phương án và giải thích', () {
    final question = QuizQuestion.fromJson(<String, Object?>{
      'question': 'Định luật nào mô tả hiện tượng cảm ứng?',
      'options': <String>['Faraday', 'Newton', 'Ohm', 'Hooke'],
      'correctIndex': 0,
      'explanation': 'Định luật Faraday mô tả suất điện động cảm ứng.',
    });

    expect(question.correctIndex, 0);
    expect(question.options, hasLength(4));
    expect(question.explanation, contains('Faraday'));
  });

  test('từ chối đáp án sai chỉ số hoặc phương án trùng nhau', () {
    expect(
      () => QuizQuestion.fromJson(<String, Object?>{
        'question': 'Câu hỏi',
        'options': <String>['A', 'B', 'C', 'D'],
        'correctIndex': 4,
        'explanation': 'Lời giải',
      }),
      throwsFormatException,
    );
    expect(
      () => QuizQuestion.fromJson(<String, Object?>{
        'question': 'Câu hỏi',
        'options': <String>['A', 'A', 'C', 'D'],
        'correctIndex': 0,
        'explanation': 'Lời giải',
      }),
      throwsFormatException,
    );
  });
}
