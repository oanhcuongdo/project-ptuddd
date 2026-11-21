import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/features/question_generator/domain/question_generator.dart';
import 'package:soroban_kids_app/shared/entities/soroban_question.dart';

void main() {
  group('QuestionGenerator Level 1 addition', () {
    test('keeps operands and result in range and calculates the sum', () {
      final generator = QuestionGenerator(random: Random(1));

      for (var i = 0; i < 200; i++) {
        final question = generator.generateForLevel(
          QuestionLevel.basic,
          operation: ArithmeticOperation.addition,
        );

        expect(question.operands, hasLength(2));
        expect(question.operands[0], inInclusiveRange(0, 9));
        expect(question.operands[1], inInclusiveRange(0, 9));
        expect(question.operands[0] + question.operands[1], lessThanOrEqualTo(9));
        expect(question.expectedAnswer, question.operands[0] + question.operands[1]);
        expect(question.expectedAnswer, inInclusiveRange(0, 9));
        expect(question.level, QuestionLevel.basic.value);
        expect(question.operation, ArithmeticOperation.addition);
      }
    });
  });

  group('QuestionGenerator Level 1 subtraction', () {
    test('keeps operands and result in range and calculates the difference', () {
      final generator = QuestionGenerator(random: Random(2));

      for (var i = 0; i < 200; i++) {
        final question = generator.generateForLevel(
          QuestionLevel.basic,
          operation: ArithmeticOperation.subtraction,
        );

        expect(question.operands, hasLength(2));
        expect(question.operands[0], inInclusiveRange(0, 9));
        expect(question.operands[1], inInclusiveRange(0, 9));
        expect(question.operands[0], greaterThanOrEqualTo(question.operands[1]));
        expect(question.expectedAnswer, question.operands[0] - question.operands[1]);
        expect(question.expectedAnswer, inInclusiveRange(0, 9));
        expect(question.operation, ArithmeticOperation.subtraction);
      }
    });
  });

  group('QuestionGenerator Level 1 random operation', () {
    test('generates questions and selects only addition or subtraction', () {
      final generator = QuestionGenerator(random: Random(3));

      for (var i = 0; i < 200; i++) {
        final question = generator.generateForLevel(QuestionLevel.basic);

        expect(question.operation, isIn(ArithmeticOperation.values));
        expect(question.type, QuestionType.recognition);
        expect(question.operands, hasLength(2));
        expect(question.operands.every((value) => value >= 0 && value <= 9), isTrue);
        expect(question.expectedAnswer, inInclusiveRange(0, 9));
        if (question.operation == ArithmeticOperation.addition) {
          expect(question.expectedAnswer, question.operands[0] + question.operands[1]);
        } else {
          expect(question.expectedAnswer, question.operands[0] - question.operands[1]);
          expect(question.operands[0], greaterThanOrEqualTo(question.operands[1]));
        }
      }
    });
  });

  group('QuestionGenerator Level 1 boundary cases', () {
    test('generates 0 + 0 = 0', () {
      final question = QuestionGenerator(random: _SequenceRandom([0, 0]))
          .generateForLevel(
        QuestionLevel.basic,
        operation: ArithmeticOperation.addition,
      );

      expect(question.operands, [0, 0]);
      expect(question.operation, ArithmeticOperation.addition);
      expect(question.expectedAnswer, 0);
      expect(question.formulaExpression, '0 + 0');
    });

    test('generates 0 + 9 = 9', () {
      final question = QuestionGenerator(random: _SequenceRandom([0, 9]))
          .generateForLevel(
        QuestionLevel.basic,
        operation: ArithmeticOperation.addition,
      );

      expect(question.operands, [0, 9]);
      expect(question.expectedAnswer, 9);
    });

    test('generates 9 - 0 = 9', () {
      final question = QuestionGenerator(random: _SequenceRandom([9, 0]))
          .generateForLevel(
        QuestionLevel.basic,
        operation: ArithmeticOperation.subtraction,
      );

      expect(question.operands, [9, 0]);
      expect(question.expectedAnswer, 9);
      expect(question.formulaExpression, '9 - 0');
    });

    test('generates 9 - 9 = 0', () {
      final question = QuestionGenerator(random: _SequenceRandom([9, 9]))
          .generateForLevel(
        QuestionLevel.basic,
        operation: ArithmeticOperation.subtraction,
      );

      expect(question.operands, [9, 9]);
      expect(question.expectedAnswer, 0);
    });
  });
}

class _SequenceRandom implements Random {
  _SequenceRandom(this._values);

  final List<int> _values;
  var _index = 0;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => nextInt(1000000) / 1000000;

  @override
  int nextInt(int max) {
    if (_index >= _values.length) {
      throw StateError('No deterministic random values remain.');
    }
    final value = _values[_index++];
    if (value < 0 || value >= max) {
      throw RangeError.range(value, 0, max - 1, 'value');
    }
    return value;
  }
}
