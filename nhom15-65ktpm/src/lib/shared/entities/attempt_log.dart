import 'package:equatable/equatable.dart';

class AttemptLog extends Equatable {
  final String questionId;
  final int userAnswer;
  final bool isCorrect;
  final int responseTimeMs;
  final String answeredVia; // 'voice' hoặc 'abacus_touch'
  final String timestamp;

  const AttemptLog({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.answeredVia,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'responseTimeMs': responseTimeMs,
      'answeredVia': answeredVia,
      'timestamp': timestamp,
    };
  }

  factory AttemptLog.fromMap(Map<String, dynamic> map) {
    return AttemptLog(
      questionId: map['questionId'] ?? '',
      userAnswer: map['userAnswer'] ?? 0,
      isCorrect: map['isCorrect'] ?? false,
      responseTimeMs: map['responseTimeMs'] ?? 0,
      answeredVia: map['answeredVia'] ?? 'abacus_touch',
      timestamp: map['timestamp'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        questionId,
        userAnswer,
        isCorrect,
        responseTimeMs,
        answeredVia,
        timestamp,
      ];
}
