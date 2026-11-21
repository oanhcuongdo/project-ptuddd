class QuizQuestionItem {
  final String id;
  final String quizId;
  final String questionText;
  final List<String> options; // Exactly 4 options
  final int correctIndex; // 0, 1, 2, or 3
  final String? explanation;
  final String? topic;
  final String? difficulty;

  const QuizQuestionItem({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.topic,
    this.difficulty,
  });

  factory QuizQuestionItem.fromJson(Map<String, dynamic> json) {
    return QuizQuestionItem(
      id: json['id'] as String? ?? '',
      quizId: json['quiz_id'] as String? ?? '',
      questionText: json['question_text'] as String,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctIndex: (json['correct_index'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String?,
      topic: json['topic'] as String?,
      difficulty: json['difficulty'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'options': options,
      'correct_index': correctIndex,
      'explanation': explanation,
      'topic': topic,
      'difficulty': difficulty,
    };
  }

  QuizQuestionItem copyWith({
    String? questionText,
    List<String>? options,
    int? correctIndex,
    String? explanation,
  }) {
    return QuizQuestionItem(
      id: id,
      quizId: quizId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
      topic: topic,
      difficulty: difficulty,
    );
  }
}
