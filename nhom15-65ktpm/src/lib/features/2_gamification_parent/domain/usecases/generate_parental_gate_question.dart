import 'dart:math';

import '../entities/verbal_math_question.dart';

class GenerateParentalGateQuestion {
  static const List<String> _numberWords = [
    'Không',
    'Một',
    'Hai',
    'Ba',
    'Bốn',
    'Năm',
    'Sáu',
    'Bảy',
    'Tám',
    'Chín',
    'Mười',
    'Mười một',
    'Mười hai',
    'Mười ba',
    'Mười bốn',
    'Mười lăm',
    'Mười sáu',
    'Mười bảy',
    'Mười tám',
    'Mười chín',
    'Hai mươi',
  ];

  final Random _random;
  String? _previousQuestionText;

  GenerateParentalGateQuestion({Random? random}) : _random = random ?? Random();

  VerbalMathQuestion generate() {
    final candidates = <_QuestionOperands>[];
    for (var first = 2; first <= 9; first++) {
      for (var second = 2; second <= 9; second++) {
        candidates.add(
          _QuestionOperands(first, second, isAddition: true),
        );
      }
    }
    for (var first = 8; first <= 20; first++) {
      for (var second = 2; second <= min(9, first - 1); second++) {
        candidates.add(
          _QuestionOperands(first, second, isAddition: false),
        );
      }
    }

    final available = candidates
        .where((candidate) => candidate.questionText != _previousQuestionText)
        .toList();
    final selected = available[_random.nextInt(available.length)];
    final answer = selected.answer;
    final options = <int>{answer};

    while (options.length < 4) {
      final distractor = answer + _random.nextInt(7) - 3;
      if (distractor >= 0 && distractor <= 20) {
        options.add(distractor);
      }
    }

    final shuffledOptions = options.toList()..shuffle(_random);
    _previousQuestionText = selected.questionText;

    return VerbalMathQuestion(
      questionText: selected.questionText,
      answer: answer,
      options: shuffledOptions,
    );
  }
}

class _QuestionOperands {
  final int first;
  final int second;
  final bool isAddition;

  const _QuestionOperands(
    this.first,
    this.second, {
    required this.isAddition,
  });

  int get answer => isAddition ? first + second : first - second;

  String get questionText {
    final operation = isAddition ? 'cộng' : 'trừ';
    final firstWord = GenerateParentalGateQuestion._numberWords[first];
    final secondWord =
        GenerateParentalGateQuestion._numberWords[second].toLowerCase();
    return '$firstWord $operation $secondWord bằng mấy?';
  }
}
