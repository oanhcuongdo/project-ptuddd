/// Model dữ liệu cho trợ lý ôn bài AI, khớp với API `/api/ai/*` của server
/// (xem `nhom11-65ktpm/docs/api-tro-ly-ai.md`).
library;

List<Map<String, dynamic>> _mapList(Object? value) =>
    (value as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

class SuggestedReply {
  final String hanzi;
  final String pinyin;
  final String translationVi;

  const SuggestedReply({required this.hanzi, required this.pinyin, required this.translationVi});

  factory SuggestedReply.fromJson(Map<String, dynamic> json) => SuggestedReply(
        hanzi: json['hanzi'] as String? ?? '',
        pinyin: json['pinyin'] as String? ?? '',
        translationVi: json['translation_vi'] as String? ?? '',
      );
}

class SentenceComponent {
  final String text;
  final String pinyin;
  final String role;
  final String labelVi;

  const SentenceComponent({
    required this.text,
    required this.pinyin,
    required this.role,
    required this.labelVi,
  });

  factory SentenceComponent.fromJson(Map<String, dynamic> json) => SentenceComponent(
        text: json['text'] as String? ?? '',
        pinyin: json['pinyin'] as String? ?? '',
        role: json['role'] as String? ?? 'other',
        labelVi: json['label_vi'] as String? ?? '',
      );
}

class GrammarErrorItem {
  final String span;
  final String correction;
  final String errorType;
  final String explanationVi;
  final String? grammarPointId;

  const GrammarErrorItem({
    required this.span,
    required this.correction,
    required this.errorType,
    required this.explanationVi,
    this.grammarPointId,
  });

  factory GrammarErrorItem.fromJson(Map<String, dynamic> json) => GrammarErrorItem(
        span: json['span'] as String? ?? '',
        correction: json['correction'] as String? ?? '',
        errorType: json['error_type'] as String? ?? 'other',
        explanationVi: json['explanation_vi'] as String? ?? '',
        grammarPointId: json['grammar_point_id'] as String?,
      );
}

class GrammarFeedback {
  final String id;
  final String originalSentence;
  final String? correctedSentence;
  final String? correctedPinyin;
  final List<SentenceComponent> components;
  final List<GrammarErrorItem> errors;
  final List<String> grammarPointIds;
  final int score;
  final String? overallCommentVi;

  const GrammarFeedback({
    required this.id,
    required this.originalSentence,
    required this.correctedSentence,
    required this.correctedPinyin,
    required this.components,
    required this.errors,
    required this.grammarPointIds,
    required this.score,
    required this.overallCommentVi,
  });

  bool get isCorrect => errors.isEmpty;

  factory GrammarFeedback.fromJson(Map<String, dynamic> json) => GrammarFeedback(
        id: json['id'] as String,
        originalSentence: json['original_sentence'] as String? ?? '',
        correctedSentence: json['corrected_sentence'] as String?,
        correctedPinyin: json['corrected_pinyin'] as String?,
        components: _mapList(json['components']).map(SentenceComponent.fromJson).toList(),
        errors: _mapList(json['errors']).map(GrammarErrorItem.fromJson).toList(),
        grammarPointIds: (json['grammar_point_ids'] as List<dynamic>? ?? const []).cast<String>(),
        score: (json['score'] as num?)?.toInt() ?? 0,
        overallCommentVi: json['overall_comment_vi'] as String?,
      );
}

class AiChatMessage {
  final String id;
  final String role; // user | assistant
  final String content;
  final String? pinyin;
  final String? translationVi;
  final List<SuggestedReply> suggestedReplies;
  final String? inputMethod;
  final GrammarFeedback? grammarFeedback;

  const AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.pinyin,
    this.translationVi,
    this.suggestedReplies = const [],
    this.inputMethod,
    this.grammarFeedback,
  });

  bool get isAssistant => role == 'assistant';

  factory AiChatMessage.fromJson(Map<String, dynamic> json) => AiChatMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String? ?? '',
        pinyin: json['pinyin'] as String?,
        translationVi: json['translation_vi'] as String?,
        suggestedReplies: _mapList(json['suggested_replies']).map(SuggestedReply.fromJson).toList(),
        inputMethod: json['input_method'] as String?,
        grammarFeedback: json['grammar_feedback'] == null
            ? null
            : GrammarFeedback.fromJson(json['grammar_feedback'] as Map<String, dynamic>),
      );
}

class ConversationSummary {
  final double? overallScore;
  final int turns;
  final int correctSentences;
  final Map<String, int> errorCounts;
  final List<Map<String, dynamic>> topErrors;
  final List<String> grammarPointsToReview;
  final String commentVi;

  const ConversationSummary({
    required this.overallScore,
    required this.turns,
    required this.correctSentences,
    required this.errorCounts,
    required this.topErrors,
    required this.grammarPointsToReview,
    required this.commentVi,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) => ConversationSummary(
        overallScore: (json['overall_score'] as num?)?.toDouble(),
        turns: (json['turns'] as num?)?.toInt() ?? 0,
        correctSentences: (json['correct_sentences'] as num?)?.toInt() ?? 0,
        errorCounts: (json['error_counts'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        topErrors: _mapList(json['top_errors']),
        grammarPointsToReview:
            (json['grammar_points_to_review'] as List<dynamic>? ?? const []).cast<String>(),
        commentVi: json['comment_vi'] as String? ?? '',
      );
}

class AiConversation {
  final String id;
  final int? lessonId;
  final String status;
  final int turnCount;
  final int maxTurns;
  final double? overallScore;
  final ConversationSummary? summary;
  final List<AiChatMessage> messages;
  final String disclaimerVi;

  const AiConversation({
    required this.id,
    required this.lessonId,
    required this.status,
    required this.turnCount,
    required this.maxTurns,
    required this.overallScore,
    required this.summary,
    required this.messages,
    required this.disclaimerVi,
  });

  bool get isCompleted => status == 'completed';

  factory AiConversation.fromJson(Map<String, dynamic> json) => AiConversation(
        id: json['id'] as String,
        lessonId: (json['lesson_id'] as num?)?.toInt(),
        status: json['status'] as String? ?? 'active',
        turnCount: (json['turn_count'] as num?)?.toInt() ?? 0,
        maxTurns: (json['max_turns'] as num?)?.toInt() ?? 8,
        overallScore: (json['overall_score'] as num?)?.toDouble(),
        summary: json['summary'] == null
            ? null
            : ConversationSummary.fromJson(json['summary'] as Map<String, dynamic>),
        messages: _mapList(json['messages']).map(AiChatMessage.fromJson).toList(),
        disclaimerVi: json['disclaimer_vi'] as String? ?? '',
      );
}
