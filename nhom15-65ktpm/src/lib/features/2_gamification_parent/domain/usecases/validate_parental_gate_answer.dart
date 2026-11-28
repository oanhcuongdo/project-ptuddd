import '../../../4_ai_voice_tutor/domain/usecases/vietnamese_number_extractor.dart';
import '../entities/verbal_math_question.dart';

enum ParentalGateAnswerStatus {
  empty,
  invalid,
  correct,
  incorrect,
}

class ValidateParentalGateAnswer {
  const ValidateParentalGateAnswer();

  ParentalGateAnswerStatus validateInput({
    required VerbalMathQuestion question,
    required String input,
  }) {
    if (input.trim().isEmpty) return ParentalGateAnswerStatus.empty;
    final answer = parseInput(input);
    if (answer == null) return ParentalGateAnswerStatus.invalid;
    return validateValue(question: question, value: answer);
  }

  int? parseInput(String input) {
    final normalized =
        input.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized) ??
        VietnameseNumberExtractor.extractNumber(normalized);
  }

  ParentalGateAnswerStatus validateValue({
    required VerbalMathQuestion question,
    required int value,
  }) {
    return value == question.answer
        ? ParentalGateAnswerStatus.correct
        : ParentalGateAnswerStatus.incorrect;
  }
}
