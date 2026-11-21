import 'dart:math';

import 'package:soroban_kids_app/shared/entities/soroban_question.dart';

/// Difficulty levels implemented by the arithmetic generator.
enum QuestionLevel {
  basic(1),
  friendRules(2),
  flashAnzan(3);

  const QuestionLevel(this.value);

  final int value;

  static QuestionLevel fromValue(int value) {
    return QuestionLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => throw ArgumentError.value(value, 'value', 'Unknown level'),
    );
  }
}

/// Creates addition and subtraction questions for the lesson screens.
class QuestionGenerator {
  QuestionGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Generates a question for [level]. Kept compatible with screens that pass
  /// the level as an integer.
  static SorobanQuestion generate(int level) {
    return QuestionGenerator().generateForLevel(
      QuestionLevel.fromValue(level),
    );
  }

  SorobanQuestion generateForLevel(
    QuestionLevel level, {
    ArithmeticOperation? operation,
    QuestionType? questionType,
    int flashTermCount = 3,
    int flashSpeedMs = 1200,
  }) {
    switch (level) {
      case QuestionLevel.basic:
        return _generateBasic(operation: operation);
      case QuestionLevel.friendRules:
        return _generateFriendRules(
          operation: operation,
          questionType: questionType,
        );
      case QuestionLevel.flashAnzan:
        return _generateFlashAnzan(
          termCount: flashTermCount,
          flashSpeedMs: flashSpeedMs,
        );
    }
  }

  SorobanQuestion _generateFlashAnzan({
    required int termCount,
    required int flashSpeedMs,
  }) {
    if (termCount < 2) {
      throw ArgumentError.value(
        termCount,
        'flashTermCount',
        'Flash Anzan requires at least 2 numbers.',
      );
    }
    if (flashSpeedMs < 500 || flashSpeedMs > 1500) {
      throw ArgumentError.value(
        flashSpeedMs,
        'flashSpeedMs',
        'Flash speed must be between 500 and 1500 milliseconds.',
      );
    }

    // The first displayed number starts the running total; later numbers are
    // signed single-digit additions/subtractions. Keep every intermediate sum
    // in the supported 0-99 range.
    final operands = <int>[_random.nextInt(100)];
    var runningTotal = operands.first;

    while (operands.length < termCount) {
      final validChanges = <int>[];
      for (var value = 1; value <= 9; value++) {
        if (runningTotal + value <= 99) validChanges.add(value);
        if (runningTotal - value >= 0) validChanges.add(-value);
      }

      final change = validChanges[_random.nextInt(validChanges.length)];
      operands.add(change);
      runningTotal += change;
    }

    return SorobanQuestion(
      id: 'level3_flash_anzan_${DateTime.now().microsecondsSinceEpoch}',
      level: QuestionLevel.flashAnzan.value,
      operands: operands,
      expectedAnswer: runningTotal,
      type: QuestionType.flashAnzan,
      flashSpeedMs: flashSpeedMs,
    );
  }

  SorobanQuestion _generateFriendRules({
    ArithmeticOperation? operation,
    QuestionType? questionType,
  }) {
    final selectedOperation = operation ?? _randomOperation();
    final selectedType = questionType ??
        (_random.nextBool()
            ? QuestionType.smallFriend
            : QuestionType.bigFriend);

    if (selectedType != QuestionType.smallFriend &&
        selectedType != QuestionType.bigFriend) {
      throw ArgumentError.value(
        selectedType,
        'questionType',
        'Level 2 supports only smallFriend and bigFriend questions.',
      );
    }

    // Reservoir-sample valid operands instead of storing a fixed question list.
    List<int>? selectedOperands;
    var validPairCount = 0;
    for (var first = 0; first <= 99; first++) {
      for (var second = 1; second <= 9; second++) {
        if (!_usesFriendRule(
          type: selectedType,
          operation: selectedOperation,
          first: first,
          second: second,
        )) {
          continue;
        }

        validPairCount++;
        if (_random.nextInt(validPairCount) == 0) {
          selectedOperands = [first, second];
        }
      }
    }

    final operands = selectedOperands;
    if (operands == null) {
      throw StateError(
        'No valid operands for ${selectedType.name} ${selectedOperation.name}.',
      );
    }

    final first = operands[0];
    final second = operands[1];
    final answer = selectedOperation == ArithmeticOperation.addition
        ? first + second
        : first - second;

    return SorobanQuestion(
      id: 'level2_${selectedType.name}_${DateTime.now().microsecondsSinceEpoch}',
      level: QuestionLevel.friendRules.value,
      operands: operands,
      operation: selectedOperation,
      expectedAnswer: answer,
      type: selectedType,
    );
  }

  bool _usesFriendRule({
    required QuestionType type,
    required ArithmeticOperation operation,
    required int first,
    required int second,
  }) {
    final units = first % 10;

    switch (type) {
      case QuestionType.smallFriend:
        if (second >= 5) return false;
        if (operation == ArithmeticOperation.addition) {
          // Cross the 5 boundary without carrying to the next decade.
          return units < 5 && units + second >= 5 && first + second <= 99;
        }
        // Cross down from 5-9 to 0-4 without borrowing from the next decade.
        return units >= 5 && units - second < 5;
      case QuestionType.bigFriend:
        if (operation == ArithmeticOperation.addition) {
          // Use the complement to 10 and keep the answer in the 0-99 range.
          return units + second >= 10 && first + second <= 99;
        }
        // Borrow across a decade while keeping the result non-negative.
        return units < second && first >= second;
      case QuestionType.recognition:
      case QuestionType.flashAnzan:
        return false;
    }
  }

  ArithmeticOperation _randomOperation() => _random.nextBool()
      ? ArithmeticOperation.addition
      : ArithmeticOperation.subtraction;

  SorobanQuestion _generateBasic({ArithmeticOperation? operation}) {
    final selectedOperation = operation ??
        (_random.nextInt(2) == 0
            ? ArithmeticOperation.addition
            : ArithmeticOperation.subtraction);
    final firstOperand = _random.nextInt(10);
    final secondOperand = _random.nextInt(
      selectedOperation == ArithmeticOperation.addition
          ? 10 - firstOperand
          : firstOperand + 1,
    );

    final answer = selectedOperation == ArithmeticOperation.addition
        ? firstOperand + secondOperand
        : firstOperand - secondOperand;

    return SorobanQuestion(
      id: 'level1_${DateTime.now().microsecondsSinceEpoch}',
      level: QuestionLevel.basic.value,
      operands: [firstOperand, secondOperand],
      operation: selectedOperation,
      expectedAnswer: answer,
      type: QuestionType.recognition,
    );
  }
}
