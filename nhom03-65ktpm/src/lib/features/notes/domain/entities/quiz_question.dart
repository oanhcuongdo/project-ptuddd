class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  factory QuizQuestion.fromJson(Map<String, Object?> json) {
    final question = json['question'];
    final rawOptions = json['options'];
    final correctIndex = json['correctIndex'];
    final explanation = json['explanation'];
    if (question is! String ||
        rawOptions is! List<Object?> ||
        rawOptions.any((Object? option) => option is! String) ||
        correctIndex is! int ||
        explanation is! String) {
      throw const FormatException('Cấu trúc câu hỏi không hợp lệ.');
    }
    final options = rawOptions.cast<String>();
    if (question.trim().isEmpty ||
        explanation.trim().isEmpty ||
        options.length != 4 ||
        options.any((String option) => option.trim().isEmpty) ||
        options
                .map((String option) => option.trim().toLowerCase())
                .toSet()
                .length !=
            4 ||
        correctIndex < 0 ||
        correctIndex >= options.length) {
      throw const FormatException('Cấu trúc câu hỏi không hợp lệ.');
    }
    return QuizQuestion(
      question: question.trim(),
      options: options.map((String option) => option.trim()).toList(),
      correctIndex: correctIndex,
      explanation: explanation.trim(),
    );
  }
}
