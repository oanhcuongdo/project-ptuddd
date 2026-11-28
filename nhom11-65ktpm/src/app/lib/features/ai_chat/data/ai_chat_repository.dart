import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'models/ai_chat_models.dart';

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return AiChatRepository(ref.watch(apiClientProvider));
});

/// Các sự kiện server gửi về khi người học trả lời (SSE).
sealed class AiChatStreamEvent {
  const AiChatStreamEvent();
}

class UserMessageSaved extends AiChatStreamEvent {
  final String id;
  const UserMessageSaved(this.id);
}

class ReplyDelta extends AiChatStreamEvent {
  final String text;
  const ReplyDelta(this.text);
}

class GrammarReceived extends AiChatStreamEvent {
  final GrammarFeedback feedback;
  const GrammarReceived(this.feedback);
}

class GrammarFailed extends AiChatStreamEvent {
  final String message;
  const GrammarFailed(this.message);
}

class AssistantMessageReceived extends AiChatStreamEvent {
  final AiChatMessage message;
  const AssistantMessageReceived(this.message);
}

class TurnDone extends AiChatStreamEvent {
  final int turnCount;
  final int maxTurns;
  final bool shouldFinish;
  const TurnDone({required this.turnCount, required this.maxTurns, required this.shouldFinish});
}

class StreamFailed extends AiChatStreamEvent {
  final String message;
  final bool retryable;
  const StreamFailed(this.message, {this.retryable = true});
}

class AiChatRepository {
  final ApiClient _api;

  AiChatRepository(this._api);

  Future<AiConversation> startConversation(int lessonId) async {
    final json = await _api.post('/ai/conversations', body: {'lesson_id': lessonId});
    return AiConversation.fromJson(json as Map<String, dynamic>);
  }

  Future<AiConversation> getConversation(String id) async {
    final json = await _api.get('/ai/conversations/$id');
    return AiConversation.fromJson(json as Map<String, dynamic>);
  }

  Future<AiConversation> finishConversation(String id) async {
    final json = await _api.post('/ai/conversations/$id/finish');
    return AiConversation.fromJson(json as Map<String, dynamic>);
  }

  /// Gửi câu trả lời và nhận từng sự kiện phản hồi (gõ chữ, phân tích ngữ pháp...).
  Stream<AiChatStreamEvent> sendMessage(
    String conversationId,
    String content, {
    String inputMethod = 'text',
  }) async* {
    final events = _api.postStream(
      '/ai/conversations/$conversationId/messages',
      body: {'content': content, 'input_method': inputMethod},
    );
    await for (final event in events) {
      final data = event.json;
      switch (event.event) {
        case 'user_message':
          yield UserMessageSaved(data['id'] as String);
        case 'delta':
          yield ReplyDelta(data['text'] as String? ?? '');
        case 'grammar':
          yield GrammarReceived(GrammarFeedback.fromJson(data));
        case 'grammar_error':
          yield GrammarFailed(data['message'] as String? ?? 'Không phân tích được ngữ pháp.');
        case 'message':
          yield AssistantMessageReceived(AiChatMessage.fromJson(data));
        case 'done':
          yield TurnDone(
            turnCount: (data['turn_count'] as num).toInt(),
            maxTurns: (data['max_turns'] as num).toInt(),
            shouldFinish: data['should_finish'] as bool? ?? false,
          );
        case 'error':
          yield StreamFailed(
            data['message'] as String? ?? 'Đã có lỗi xảy ra.',
            retryable: data['retryable'] as bool? ?? true,
          );
      }
    }
  }
}
