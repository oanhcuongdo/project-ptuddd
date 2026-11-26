import 'package:chailish/features/ai_chat/data/ai_chat_repository.dart';
import 'package:chailish/features/ai_chat/data/chat_voice_services.dart';
import 'package:chailish/features/ai_chat/presentation/screens/ai_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeAiChatRepository repo;
  late FakeTts tts;
  late FakeSpeechInput speech;

  setUp(() {
    repo = FakeAiChatRepository();
    tts = FakeTts();
    speech = FakeSpeechInput();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatRepositoryProvider.overrideWithValue(repo),
          chatTtsProvider.overrideWithValue(tts),
          chatSpeechInputProvider.overrideWithValue(speech),
        ],
        child: const MaterialApp(home: AiChatScreen(lessonId: 1, lessonTitle: 'Chào hỏi')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows AI opening with pinyin, toggles translation and plays TTS', (tester) async {
    await pumpScreen(tester);

    expect(find.text('你好！你是学生吗？'), findsOneWidget);
    expect(find.text('nǐ hǎo! nǐ shì xuésheng ma?'), findsOneWidget);
    expect(find.text('Lượt 0/8'), findsOneWidget);
    expect(find.textContaining('chưa hoàn toàn chính xác'), findsOneWidget);

    // Nghĩa tiếng Việt ẩn mặc định, bấm nút để hiện.
    expect(find.byKey(const Key('ai-translation-a1')), findsNothing);
    await tester.tap(find.byKey(const Key('translate-a1')));
    await tester.pump();
    expect(find.text('Xin chào! Bạn là học sinh à?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('speak-a1')));
    expect(tts.spoken.single, ('你好！你是学生吗？', false));
  });

  testWidgets('suggested reply fills input and sending shows thinking then reply', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('suggestion-0')));
    await tester.pump();
    expect(find.widgetWithText(TextField, '我是学生。'), findsOneWidget);

    await tester.tap(find.byKey(const Key('send-button')));
    await tester.pump();
    expect(repo.sent.single.content, '我是学生。');
    expect(find.byKey(const Key('ai-typing')), findsOneWidget);
    expect(find.text('Đang phân tích ngữ pháp...'), findsOneWidget);

    await repo.completeTurn(correct: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai-typing')), findsNothing);
    expect(find.text('你叫什么名字？'), findsOneWidget);
    expect(find.text('1 lỗi · 70 điểm'), findsOneWidget);
    expect(find.text('Lượt 1/8'), findsOneWidget);
  });

  testWidgets('voice input fills the box and is sent as voice', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('mic-button')));
    await tester.pump();
    speech.say('我叫小明');
    await tester.pump();
    expect(find.widgetWithText(TextField, '我叫小明'), findsOneWidget);

    await tester.tap(find.byKey(const Key('send-button')));
    await tester.pump();
    expect(repo.sent.single.inputMethod, 'voice');
    await repo.completeTurn();
    await tester.pumpAndSettle();
  });

  testWidgets('error restores input and shows snackbar', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byKey(const Key('chat-input')), '我是学生。');
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-button')));
    await tester.pump();

    repo.current!.add(const StreamFailed('AI đang quá tải'));
    await repo.current!.close();
    await tester.pumpAndSettle();

    expect(find.text('AI đang quá tải'), findsOneWidget);
    expect(find.widgetWithText(TextField, '我是学生。'), findsOneWidget);
  });

  testWidgets('finished conversation hides input', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byKey(const Key('chat-input')), '再见');
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-button')));
    await tester.pump();
    await repo.completeTurn(turnCount: 8, shouldFinish: true);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-finished')), findsOneWidget);
    expect(find.byKey(const Key('chat-input')), findsNothing);
  });

  testWidgets('start failure shows retry', (tester) async {
    repo.startError = Exception('offline');
    await pumpScreen(tester);
    expect(find.byKey(const Key('chat-start-failed')), findsOneWidget);

    repo.startError = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('你好！你是学生吗？'), findsOneWidget);
  });
}
