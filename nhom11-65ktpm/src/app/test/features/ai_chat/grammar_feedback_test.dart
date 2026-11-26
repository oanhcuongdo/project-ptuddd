import 'package:chailish/features/ai_chat/data/ai_chat_repository.dart';
import 'package:chailish/features/ai_chat/data/chat_voice_services.dart';
import 'package:chailish/features/ai_chat/data/models/ai_chat_models.dart';
import 'package:chailish/features/ai_chat/presentation/screens/ai_chat_screen.dart';
import 'package:chailish/features/ai_chat/presentation/screens/ai_chat_summary_screen.dart';
import 'package:chailish/features/ai_chat/presentation/widgets/grammar_analysis_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Widget _wrap(Widget child, FakeAiChatRepository repo) => ProviderScope(
      overrides: [
        aiChatRepositoryProvider.overrideWithValue(repo),
        chatTtsProvider.overrideWithValue(FakeTts()),
        chatSpeechInputProvider.overrideWithValue(FakeSpeechInput()),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  group('GrammarAnalysisView', () {
    testWidgets('shows comparison, components and errors for a wrong sentence', (tester) async {
      final feedback = GrammarFeedback.fromJson(grammarJson(correct: false));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GrammarAnalysisView(feedback: feedback))));
      await tester.pumpAndSettle(); // chờ điểm số đếm lên xong

      expect(find.text('Cần chỉnh sửa'), findsOneWidget);
      expect(find.text('70'), findsOneWidget);
      expect(find.text('Câu của bạn'), findsOneWidget);
      expect(find.text('Câu chuẩn'), findsOneWidget);
      expect(find.byKey(const Key('corrected-sentence')), findsOneWidget);
      expect(find.text('wǒ shì xuésheng.'), findsOneWidget);

      // Thành phần câu có nhãn tiếng Việt.
      expect(find.byKey(const Key('component-subject-我')), findsOneWidget);
      expect(find.text('Chủ ngữ'), findsOneWidget);
      expect(find.text('Vị ngữ'), findsOneWidget);
      expect(find.text('Tân ngữ'), findsOneWidget);

      // Danh sách lỗi: loại lỗi, đoạn sai -> cách sửa, giải thích.
      await tester.scrollUntilVisible(find.byKey(const Key('grammar-error-0')), 200);
      expect(find.text('Lỗi cần sửa (1)'), findsOneWidget);
      expect(find.text('Dùng sai động từ'), findsOneWidget);
      expect(find.text('我是学生'), findsOneWidget);
      expect(find.text('Thiếu động từ 是.'), findsOneWidget);
      expect(find.text('Điểm NP: gp-shi'), findsOneWidget);
    });

    testWidgets('correct sentence shows no errors', (tester) async {
      final feedback = GrammarFeedback.fromJson(grammarJson(correct: true));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GrammarAnalysisView(feedback: feedback))));
      await tester.pumpAndSettle(); // chờ điểm số đếm lên xong
      expect(find.text('Câu chính xác'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Không có lỗi'), 200);
      expect(find.textContaining('đúng ngữ pháp'), findsOneWidget);
    });
  });

  group('AiChatSummaryScreen', () {
    testWidgets('finishes conversation and shows score, errors and history', (tester) async {
      final repo = FakeAiChatRepository();
      await tester.pumpWidget(_wrap(const AiChatSummaryScreen(conversationId: 'c1'), repo));
      await tester.pumpAndSettle();

      expect(repo.finishCalls, 1);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('Làm tốt lắm! Xem lại vài lỗi bên dưới.'), findsOneWidget);
      expect(find.text('2 lượt'), findsOneWidget);
      expect(find.text('1 câu đúng'), findsOneWidget);
      expect(find.text('Lỗi hay gặp'), findsOneWidget);
      expect(find.text('gp-shi'), findsOneWidget);

      await tester.scrollUntilVisible(find.byKey(const Key('answer-u1')), 200);
      expect(find.text('Sửa: 我是学生。'), findsOneWidget);
      await tester.tap(find.byKey(const Key('answer-u1')));
      await tester.pumpAndSettle();
      expect(find.text('Phân tích ngữ pháp'), findsOneWidget);
    });

    testWidgets('shows retry on error', (tester) async {
      final repo = _FailingFinishRepo();
      await tester.pumpWidget(_wrap(const AiChatSummaryScreen(conversationId: 'c1'), repo));
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });

  group('AiChatScreen integration', () {
    testWidgets('grammar chip opens analysis; finished banner opens summary', (tester) async {
      final repo = FakeAiChatRepository();
      await tester.pumpWidget(_wrap(const AiChatScreen(lessonId: 1), repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('chat-input')), '我学生。');
      await tester.pump();
      await tester.tap(find.byKey(const Key('send-button')));
      await tester.pump();
      await repo.completeTurn(correct: false, turnCount: 8, shouldFinish: true);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('grammar-chip-u1')));
      await tester.pumpAndSettle();
      expect(find.text('Phân tích ngữ pháp'), findsOneWidget);
      expect(find.text('Câu chuẩn'), findsOneWidget);
      Navigator.of(tester.element(find.text('Phân tích ngữ pháp'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('view-summary')));
      await tester.pumpAndSettle();
      expect(find.text('Tổng kết phiên ôn bài'), findsOneWidget);
      expect(repo.finishCalls, 1);
    });

    testWidgets('finish early asks for confirmation', (tester) async {
      final repo = FakeAiChatRepository();
      await tester.pumpWidget(_wrap(const AiChatScreen(lessonId: 1), repo));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('finish-early')), findsNothing);

      await tester.enterText(find.byKey(const Key('chat-input')), '我是学生。');
      await tester.pump();
      await tester.tap(find.byKey(const Key('send-button')));
      await tester.pump();
      await repo.completeTurn();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('finish-early')));
      await tester.pumpAndSettle();
      expect(find.text('Kết thúc phiên?'), findsOneWidget);
      await tester.tap(find.text('Kết thúc'));
      await tester.pumpAndSettle();
      expect(find.text('Tổng kết phiên ôn bài'), findsOneWidget);
    });
  });
}

class _FailingFinishRepo extends FakeAiChatRepository {
  @override
  Future<AiConversation> finishConversation(String id) async => throw Exception('offline');
}
