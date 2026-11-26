import 'dart:async';

import 'package:chailish/features/ai_chat/data/ai_chat_repository.dart';
import 'package:chailish/features/ai_chat/data/chat_voice_services.dart';
import 'package:chailish/features/ai_chat/data/models/ai_chat_models.dart';

Map<String, dynamic> assistantJson(String id, String hanzi) => {
      'id': id,
      'role': 'assistant',
      'content': hanzi,
      'pinyin': 'nǐ hǎo! nǐ shì xuésheng ma?',
      'translation_vi': 'Xin chào! Bạn là học sinh à?',
      'suggested_replies': [
        {'hanzi': '我是学生。', 'pinyin': 'wǒ shì xuésheng.', 'translation_vi': 'Tôi là học sinh.'},
      ],
      'input_method': null,
      'created_at': '2026-11-21T08:00:00Z',
    };

Map<String, dynamic> grammarJson({required bool correct}) => {
      'id': 'g1',
      'original_sentence': correct ? '我是学生。' : '我学生。',
      'corrected_sentence': '我是学生。',
      'corrected_pinyin': 'wǒ shì xuésheng.',
      'components': [
        {'text': '我', 'pinyin': 'wǒ', 'role': 'subject', 'label_vi': 'Chủ ngữ'},
        {'text': '是', 'pinyin': 'shì', 'role': 'predicate', 'label_vi': 'Vị ngữ'},
        {'text': '学生', 'pinyin': 'xuésheng', 'role': 'object', 'label_vi': 'Tân ngữ'},
      ],
      'errors': correct
          ? []
          : [
              {
                'span': '我学生',
                'correction': '我是学生',
                'error_type': 'verb_usage',
                'explanation_vi': 'Thiếu động từ 是.',
                'grammar_point_id': 'gp-shi',
              }
            ],
      'error_types': correct ? [] : ['verb_usage'],
      'grammar_point_ids': ['gp-shi'],
      'score': correct ? 100 : 70,
      'overall_comment_vi': 'Tốt lắm!',
    };

AiConversation conversation({int turnCount = 0, int maxTurns = 8, List<Map<String, dynamic>>? messages}) =>
    AiConversation.fromJson({
      'id': 'c1',
      'lesson_id': 1,
      'status': 'active',
      'turn_count': turnCount,
      'max_turns': maxTurns,
      'overall_score': null,
      'summary': null,
      'messages': messages ?? [assistantJson('a1', '你好！你是学生吗？')],
      'disclaimer_vi': 'Phân tích do AI tạo ra và có thể chưa hoàn toàn chính xác.',
    });

/// Repository giả: mỗi lần gửi trả về một StreamController để test điều khiển từng sự kiện.
class FakeAiChatRepository implements AiChatRepository {
  Object? startError;
  AiConversation startResult = conversation();
  final sent = <({String content, String inputMethod})>[];
  StreamController<AiChatStreamEvent>? current;

  @override
  Future<AiConversation> startConversation(int lessonId) async {
    if (startError != null) throw startError!;
    return startResult;
  }

  @override
  Stream<AiChatStreamEvent> sendMessage(String conversationId, String content, {String inputMethod = 'text'}) {
    sent.add((content: content, inputMethod: inputMethod));
    current = StreamController<AiChatStreamEvent>();
    return current!.stream;
  }

  @override
  Future<AiConversation> getConversation(String id) async => startResult;

  int finishCalls = 0;
  AiConversation? finishResult;

  @override
  Future<AiConversation> finishConversation(String id) async {
    finishCalls++;
    return finishResult ?? completedConversation();
  }

  /// Phát một lượt trả lời hoàn chỉnh.
  Future<void> completeTurn({bool correct = true, int turnCount = 1, bool shouldFinish = false}) async {
    final c = current!;
    c.add(const UserMessageSaved('u1'));
    c.add(const ReplyDelta('你叫'));
    c.add(const ReplyDelta('什么名字？'));
    c.add(GrammarReceived(GrammarFeedback.fromJson(grammarJson(correct: correct))));
    c.add(AssistantMessageReceived(AiChatMessage.fromJson(assistantJson('a2', '你叫什么名字？'))));
    c.add(TurnDone(turnCount: turnCount, maxTurns: 8, shouldFinish: shouldFinish));
    await c.close();
  }
}

class FakeTts implements ChatTts {
  final spoken = <(String, bool)>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text, {bool slow = false}) async => spoken.add((text, slow));

  @override
  Future<void> stop() async {}
}

class FakeSpeechInput implements ChatSpeechInput {
  void Function(String text, bool isFinal)? _onResult;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
    void Function(double level)? onSoundLevel,
    void Function(String error)? onError,
  }) async {
    _onResult = onResult;
  }

  void say(String text, {bool isFinal = true}) => _onResult?.call(text, isFinal);

  @override
  Future<void> stop() async {}
}

AiConversation completedConversation() => AiConversation.fromJson({
      'id': 'c1',
      'lesson_id': 1,
      'status': 'completed',
      'turn_count': 2,
      'max_turns': 8,
      'overall_score': 85.0,
      'summary': {
        'overall_score': 85.0,
        'turns': 2,
        'correct_sentences': 1,
        'error_counts': {'Dùng sai động từ': 1},
        'top_errors': [
          {
            'sentence': '我学生。',
            'span': '我学生',
            'correction': '我是学生',
            'error_type': 'verb_usage',
            'label_vi': 'Dùng sai động từ',
            'explanation_vi': 'Thiếu động từ 是.',
          }
        ],
        'grammar_points_to_review': ['gp-shi'],
        'comment_vi': 'Làm tốt lắm! Xem lại vài lỗi bên dưới.',
      },
      'messages': [
        assistantJson('a1', '你好！你是学生吗？'),
        {
          'id': 'u1',
          'role': 'user',
          'content': '我学生。',
          'input_method': 'text',
          'grammar_feedback': grammarJson(correct: false),
        },
        assistantJson('a2', '你叫什么名字？'),
        {
          'id': 'u2',
          'role': 'user',
          'content': '我是学生。',
          'input_method': 'voice',
          'grammar_feedback': {...grammarJson(correct: true), 'id': 'g2'},
        },
      ],
      'disclaimer_vi': 'Phân tích do AI tạo ra và có thể chưa hoàn toàn chính xác.',
    });
