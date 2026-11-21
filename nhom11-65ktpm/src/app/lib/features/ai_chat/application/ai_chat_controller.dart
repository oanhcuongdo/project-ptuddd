import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/ai_chat_repository.dart';
import '../data/models/ai_chat_models.dart';

enum ChatPhase {
  /// Đang tạo phiên, chờ AI mở đầu.
  starting,

  /// Không mở được phiên (lỗi mạng, hết lượt...).
  startFailed,

  /// Chờ người học trả lời.
  ready,

  /// Đã gửi câu trả lời, AI đang suy nghĩ (chưa có chữ nào).
  thinking,

  /// AI đang gõ chữ.
  streaming,

  /// Đủ lượt / phiên đã kết thúc.
  finished,
}

enum GrammarStatus { none, pending, done, failed }

/// Dữ liệu một bong bóng chat trên màn hình.
class ChatBubble {
  final String id;
  final bool isAssistant;
  final String text;
  final String? pinyin;
  final String? translationVi;
  final List<SuggestedReply> suggestedReplies;
  final String? inputMethod;
  final bool isStreaming;
  final GrammarStatus grammarStatus;
  final GrammarFeedback? grammar;

  const ChatBubble({
    required this.id,
    required this.isAssistant,
    required this.text,
    this.pinyin,
    this.translationVi,
    this.suggestedReplies = const [],
    this.inputMethod,
    this.isStreaming = false,
    this.grammarStatus = GrammarStatus.none,
    this.grammar,
  });

  factory ChatBubble.fromMessage(AiChatMessage m) => ChatBubble(
        id: m.id,
        isAssistant: m.isAssistant,
        text: m.content,
        pinyin: m.pinyin,
        translationVi: m.translationVi,
        suggestedReplies: m.suggestedReplies,
        inputMethod: m.inputMethod,
        grammarStatus: m.isAssistant
            ? GrammarStatus.none
            : (m.grammarFeedback != null ? GrammarStatus.done : GrammarStatus.failed),
        grammar: m.grammarFeedback,
      );

  ChatBubble copyWith({
    String? id,
    String? text,
    bool? isStreaming,
    GrammarStatus? grammarStatus,
    GrammarFeedback? grammar,
  }) =>
      ChatBubble(
        id: id ?? this.id,
        isAssistant: isAssistant,
        text: text ?? this.text,
        pinyin: pinyin,
        translationVi: translationVi,
        suggestedReplies: suggestedReplies,
        inputMethod: inputMethod,
        isStreaming: isStreaming ?? this.isStreaming,
        grammarStatus: grammarStatus ?? this.grammarStatus,
        grammar: grammar ?? this.grammar,
      );
}

class AiChatState {
  final int? lessonId;
  final String? conversationId;
  final ChatPhase phase;
  final List<ChatBubble> bubbles;
  final int turnCount;
  final int maxTurns;
  final String? errorMessage;

  /// Câu vừa gửi bị lỗi -> trả lại ô nhập để người học gửi lại.
  final String? failedInput;
  final Set<String> revealedTranslations;
  final String disclaimer;

  const AiChatState({
    this.lessonId,
    this.conversationId,
    this.phase = ChatPhase.starting,
    this.bubbles = const [],
    this.turnCount = 0,
    this.maxTurns = 8,
    this.errorMessage,
    this.failedInput,
    this.revealedTranslations = const {},
    this.disclaimer = '',
  });

  bool get canSend => phase == ChatPhase.ready && conversationId != null;
  bool get isBusy => phase == ChatPhase.thinking || phase == ChatPhase.streaming;

  /// Câu trả lời mẫu của lượt AI gần nhất.
  List<SuggestedReply> get suggestions {
    if (phase != ChatPhase.ready) return const [];
    for (final b in bubbles.reversed) {
      if (b.isAssistant) return b.suggestedReplies;
    }
    return const [];
  }

  AiChatState copyWith({
    int? lessonId,
    String? conversationId,
    ChatPhase? phase,
    List<ChatBubble>? bubbles,
    int? turnCount,
    int? maxTurns,
    String? errorMessage,
    bool clearError = false,
    String? failedInput,
    bool clearFailedInput = false,
    Set<String>? revealedTranslations,
    String? disclaimer,
  }) =>
      AiChatState(
        lessonId: lessonId ?? this.lessonId,
        conversationId: conversationId ?? this.conversationId,
        phase: phase ?? this.phase,
        bubbles: bubbles ?? this.bubbles,
        turnCount: turnCount ?? this.turnCount,
        maxTurns: maxTurns ?? this.maxTurns,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        failedInput: clearFailedInput ? null : (failedInput ?? this.failedInput),
        revealedTranslations: revealedTranslations ?? this.revealedTranslations,
        disclaimer: disclaimer ?? this.disclaimer,
      );
}

final aiChatControllerProvider =
    NotifierProvider.autoDispose<AiChatController, AiChatState>(AiChatController.new);

class AiChatController extends Notifier<AiChatState> {
  static const _pendingUserId = '__pending_user__';
  static const _pendingAiId = '__pending_ai__';

  StreamSubscription<AiChatStreamEvent>? _subscription;

  AiChatRepository get _repo => ref.read(aiChatRepositoryProvider);

  @override
  AiChatState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const AiChatState();
  }

  String _messageOf(Object error) {
    if (error is ApiException) return error.message;
    if (error is NetworkException) return error.message;
    return 'Đã có lỗi xảy ra, vui lòng thử lại.';
  }

  Future<void> start(int lessonId) async {
    state = AiChatState(lessonId: lessonId, phase: ChatPhase.starting);
    try {
      final conv = await _repo.startConversation(lessonId);
      if (!ref.mounted) return;
      state = state.copyWith(
        conversationId: conv.id,
        phase: conv.isCompleted ? ChatPhase.finished : ChatPhase.ready,
        bubbles: conv.messages.map(ChatBubble.fromMessage).toList(),
        turnCount: conv.turnCount,
        maxTurns: conv.maxTurns,
        disclaimer: conv.disclaimerVi,
        clearError: true,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(phase: ChatPhase.startFailed, errorMessage: _messageOf(e));
    }
  }

  Future<void> retryStart() async {
    final lessonId = state.lessonId;
    if (lessonId != null) await start(lessonId);
  }

  void toggleTranslation(String bubbleId) {
    final revealed = {...state.revealedTranslations};
    if (!revealed.remove(bubbleId)) revealed.add(bubbleId);
    state = state.copyWith(revealedTranslations: revealed);
  }

  /// Đánh dấu phiên đã kết thúc (khi người học mở màn hình tổng kết).
  void markFinished() {
    if (!state.isBusy) state = state.copyWith(phase: ChatPhase.finished);
  }

  void clearError() => state = state.copyWith(clearError: true, clearFailedInput: true);

  /// Gửi câu trả lời; [inputMethod] là `text` (gõ phím) hoặc `voice` (nói).
  Future<void> send(String text, {String inputMethod = 'text'}) async {
    final content = text.trim();
    final conversationId = state.conversationId;
    if (content.isEmpty || conversationId == null || !state.canSend) return;

    final completer = Completer<void>();
    state = state.copyWith(
      phase: ChatPhase.thinking,
      clearError: true,
      clearFailedInput: true,
      bubbles: [
        ...state.bubbles,
        ChatBubble(
          id: _pendingUserId,
          isAssistant: false,
          text: content,
          inputMethod: inputMethod,
          grammarStatus: GrammarStatus.pending,
        ),
        const ChatBubble(id: _pendingAiId, isAssistant: true, text: '', isStreaming: true),
      ],
    );

    var userBubbleId = _pendingUserId;
    var finished = false;

    void fail(String message) {
      finished = true;
      state = state.copyWith(
        phase: ChatPhase.ready,
        errorMessage: message,
        failedInput: content,
        bubbles: state.bubbles
            .where((b) => b.id != userBubbleId && b.id != _pendingAiId)
            .toList(),
      );
    }

    void updateBubble(String id, ChatBubble Function(ChatBubble) update) {
      state = state.copyWith(
        bubbles: [for (final b in state.bubbles) b.id == id ? update(b) : b],
      );
    }

    _subscription = _repo.sendMessage(conversationId, content, inputMethod: inputMethod).listen(
      (event) {
        if (!ref.mounted) return;
        switch (event) {
          case UserMessageSaved(:final id):
            updateBubble(userBubbleId, (b) => b.copyWith(id: id));
            userBubbleId = id;
          case ReplyDelta(:final text):
            updateBubble(_pendingAiId, (b) => b.copyWith(text: b.text + text));
            if (state.phase != ChatPhase.streaming) {
              state = state.copyWith(phase: ChatPhase.streaming);
            }
          case GrammarReceived(:final feedback):
            updateBubble(
              userBubbleId,
              (b) => b.copyWith(grammar: feedback, grammarStatus: GrammarStatus.done),
            );
          case GrammarFailed():
            updateBubble(userBubbleId, (b) => b.copyWith(grammarStatus: GrammarStatus.failed));
          case AssistantMessageReceived(:final message):
            state = state.copyWith(
              bubbles: [
                for (final b in state.bubbles)
                  b.id == _pendingAiId ? ChatBubble.fromMessage(message) : b,
              ],
            );
          case TurnDone(:final turnCount, :final maxTurns, :final shouldFinish):
            finished = true;
            state = state.copyWith(
              turnCount: turnCount,
              maxTurns: maxTurns,
              phase: shouldFinish ? ChatPhase.finished : ChatPhase.ready,
            );
          case StreamFailed(:final message):
            fail(message);
        }
      },
      onError: (Object e) {
        if (ref.mounted) fail(_messageOf(e));
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        if (ref.mounted && !finished) {
          fail('Mất kết nối với trợ lý AI, vui lòng gửi lại.');
        }
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );
    return completer.future;
  }
}
