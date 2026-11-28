import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/notes_dao.dart';
import 'package:smart_note/core/database/quiz_scores_dao.dart';
import 'package:smart_note/core/services/ai_client.dart';
import 'package:smart_note/features/notes/data/repositories/note_repository_impl.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/notes/presentation/bloc/notes_cubit.dart';
import 'package:smart_note/features/notes/presentation/pages/quiz_page.dart';

class _QuizTransport implements AiTransport {
  int calls = 0;

  @override
  Future<AiHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls++;
    return AiHttpResponse(
      statusCode: 200,
      body: jsonEncode(<String, Object?>{
        'quiz': List<Map<String, Object?>>.generate(
          5,
          (int index) => <String, Object?>{
            'question': 'Câu hỏi ${index + 1}',
            'options': <String>['Đúng', 'B', 'C', 'D'],
            'correctIndex': 0,
            'explanation': 'Giải thích câu ${index + 1}.',
          },
        ),
      }),
    );
  }

  @override
  void close() {}
}

void main() {
  late AppDatabase database;
  late NoteRepositoryImpl repository;
  late NotesCubit cubit;
  late _QuizTransport transport;
  late AiClient aiClient;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = NoteRepositoryImpl(NotesDao(database));
    cubit = NotesCubit(repository);
    transport = _QuizTransport();
    aiClient = AiClient(
      endpoint: Uri.parse('https://quiz.test'),
      transport: transport,
    );
  });

  tearDown(() async {
    await cubit.close();
    aiClient.close();
    await database.close();
  });

  Future<void> pumpPage(WidgetTester tester, String content) async {
    final now = DateTime.now();
    await repository.createNote(
      Note(
        id: 'quiz-note',
        title: 'Ghi chú học tập',
        content: content,
        kind: NoteKind.note,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: QuizPage(
          notesCubit: cubit,
          scoresDao: QuizScoresDao(database),
          aiClient: aiClient,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ghi chú học tập').last);
    await tester.pumpAndSettle();
  }

  testWidgets('không gọi AI khi ghi chú quá ngắn', (WidgetTester tester) async {
    await pumpPage(tester, 'Chỉ có vài từ.');

    expect(transport.calls, 0);
    expect(find.textContaining('Ghi chú quá ngắn'), findsOneWidget);
  });

  testWidgets('tạo 5 câu, chấm điểm, hiện giải thích và lưu lịch sử', (
    WidgetTester tester,
  ) async {
    await pumpPage(
      tester,
      'Định luật Faraday mô tả hiện tượng cảm ứng điện từ trong cuộn dây. '
      'Từ thông thay đổi sẽ tạo ra suất điện động cảm ứng. '
      'Chiều dòng điện tuân theo định luật Lenz. '
      'Máy phát điện biến đổi cơ năng thành điện năng.',
    );

    expect(transport.calls, 1);
    for (var index = 0; index < 5; index++) {
      final question = find.textContaining('Câu hỏi ${index + 1}');
      await tester.scrollUntilVisible(
        question,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      final card = find.ancestor(of: question, matching: find.byType(Card));
      final option = find
          .descendant(of: card.first, matching: find.byType(RadioListTile<int>))
          .first;
      await tester.tap(option);
      await tester.pump();
    }

    final submit = find.text('Nộp bài và lưu điểm');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.textContaining('Giải thích: Giải thích câu'), findsWidgets);
    expect(find.text('Kết quả: 5/5 câu đúng'), findsOneWidget);
    final scores = await QuizScoresDao(database).getAll();
    expect(scores, hasLength(1));
    expect(scores.single.noteId, 'quiz-note');
    expect(scores.single.correctAnswers, 5);
  });
}
