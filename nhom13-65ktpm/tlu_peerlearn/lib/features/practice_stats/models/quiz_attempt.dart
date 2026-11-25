class QuizAttempt {
  final String id;
  final String quizId;
  final String userId;
  final double score; // Thang 10 (BR-08)
  final int correctCount;
  final int totalCount;
  final DateTime submittedAt;
  final String? userFullName;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.submittedAt,
    this.userFullName,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'] as String? ?? '',
      quizId: json['quiz_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : DateTime.now(),
      userFullName: json['ck_profiles'] != null
          ? (json['ck_profiles'] as Map<String, dynamic>)['full_name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'user_id': userId,
      'score': score,
      'correct_count': correctCount,
      'total_count': totalCount,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }
}

class AttemptAnswer {
  final String id;
  final String attemptId;
  final String questionId;
  final int selectedIndex;
  final bool isCorrect;

  const AttemptAnswer({
    required this.id,
    required this.attemptId,
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
  });

  factory AttemptAnswer.fromJson(Map<String, dynamic> json) {
    return AttemptAnswer(
      id: json['id'] as String? ?? '',
      attemptId: json['attempt_id'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      selectedIndex: (json['selected_index'] as num?)?.toInt() ?? 0,
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }
}

class QuestionStat {
  final String questionId;
  final String questionText;
  final int correctCount;
  final int totalCount;
  final double correctRate; // 0.0 - 1.0

  const QuestionStat({
    required this.questionId,
    required this.questionText,
    required this.correctCount,
    required this.totalCount,
    required this.correctRate,
  });
}

class QuizAnalyticsSummary {
  final String quizId;
  final int totalAttempts;
  final double averageScore;
  final double highestScore;
  final List<QuestionStat> questionStats;
  final List<QuizAttempt> recentAttempts;

  const QuizAnalyticsSummary({
    required this.quizId,
    required this.totalAttempts,
    required this.averageScore,
    required this.highestScore,
    required this.questionStats,
    this.recentAttempts = const [],
  });
}

class PersonalPracticeSummary {
  final int totalQuizzesTaken;
  final double averageScore;
  final int totalFlashcardsStudied;
  final int rememberedFlashcards;

  const PersonalPracticeSummary({
    required this.totalQuizzesTaken,
    required this.averageScore,
    required this.totalFlashcardsStudied,
    required this.rememberedFlashcards,
  });
}
