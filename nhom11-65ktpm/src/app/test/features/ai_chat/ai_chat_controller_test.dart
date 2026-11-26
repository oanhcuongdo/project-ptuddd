import 'package:chailish/core/network/api_client.dart';
import 'package:chailish/features/ai_chat/application/ai_chat_controller.dart';
import 'package:chailish/features/ai_chat/data/ai_chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeAiChatRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeAiChatRepository();
    container = ProviderContainer(overrides: [aiChatRepositoryProvider.overrideWithValue(repo)]);
    // Giữ provider autoDispose sống trong suốt test.
    container.listen(aiChatControllerProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  AiChatController controller() => container.read(aiChatControllerProvider.notifier);
  AiChatState state() => container.read(aiChatControllerProvider);

  test('start loads the AI opening message', () async {
    await controller().start(1);
    expect(state().phase, ChatPhase.ready);
    expect(state().conversationId, 'c1');
    expect(state().bubbles.single.text, '你好！你是学生吗？');
    expect(state().suggestions.single.hanzi, '我是学生。');
  });

  test('start failure exposes server message', () async {
    repo.startError = ApiException(429, 'Bạn đã dùng hết lượt hôm nay');
    await controller().start(1);
    expect(state().phase, ChatPhase.startFailed);
    expect(state().errorMessage, 'Bạn đã dùng hết lượt hôm nay');
  });

  test('send streams reply, attaches grammar and updates turn count', () async {
    await controller().start(1);
    final sending = controller().send(' 我学生。 ', inputMethod: 'voice');

    expect(state().phase, ChatPhase.thinking);
    expect(state().bubbles.length, 3);
    expect(state().bubbles[1].text, '我学生。');
    expect(state().suggestions, isEmpty); // ẩn gợi ý khi AI đang trả lời
    expect(repo.sent.single, (content: '我学生。', inputMethod: 'voice'));

    repo.current!.add(const UserMessageSaved('u1'));
    repo.current!.add(const ReplyDelta('你叫'));
    await Future<void>.delayed(Duration.zero);
    expect(state().phase, ChatPhase.streaming);
    expect(state().bubbles.last.text, '你叫');
    expect(state().bubbles.last.isStreaming, isTrue);

    await repo.completeTurn(correct: false);
    await sending;

    final s = state();
    expect(s.phase, ChatPhase.ready);
    expect(s.turnCount, 1);
    expect(s.bubbles[1].id, 'u1');
    expect(s.bubbles[1].grammarStatus, GrammarStatus.done);
    expect(s.bubbles[1].grammar!.score, 70);
    expect(s.bubbles.last.id, 'a2');
    expect(s.bubbles.last.isStreaming, isFalse);
    expect(s.bubbles.last.pinyin, isNotEmpty);
  });

  test('stream error removes pending bubbles and returns the input', () async {
    await controller().start(1);
    final sending = controller().send('我是学生。');
    repo.current!.add(const UserMessageSaved('u1'));
    repo.current!.add(const StreamFailed('AI đang quá tải'));
    await repo.current!.close();
    await sending;

    expect(state().phase, ChatPhase.ready);
    expect(state().bubbles.length, 1);
    expect(state().errorMessage, 'AI đang quá tải');
    expect(state().failedInput, '我是学生。');
  });

  test('connection closed before done is treated as failure', () async {
    await controller().start(1);
    final sending = controller().send('我是学生。');
    repo.current!.add(const ReplyDelta('你'));
    await repo.current!.close();
    await sending;
    expect(state().bubbles.length, 1);
    expect(state().errorMessage, contains('Mất kết nối'));
  });

  test('should_finish moves to finished phase and blocks sending', () async {
    await controller().start(1);
    final sending = controller().send('我是学生。');
    await repo.completeTurn(turnCount: 8, shouldFinish: true);
    await sending;
    expect(state().phase, ChatPhase.finished);
    expect(state().canSend, isFalse);

    await controller().send('再见');
    expect(repo.sent.length, 1);
  });

  test('toggleTranslation flips per bubble', () async {
    await controller().start(1);
    controller().toggleTranslation('a1');
    expect(state().revealedTranslations, {'a1'});
    controller().toggleTranslation('a1');
    expect(state().revealedTranslations, isEmpty);
  });
}
