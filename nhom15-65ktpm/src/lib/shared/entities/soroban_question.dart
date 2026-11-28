import 'package:equatable/equatable.dart';

enum QuestionType { recognition, smallFriend, bigFriend, flashAnzan }

enum ArithmeticOperation { addition, subtraction }

class SorobanQuestion extends Equatable {
  final String id;
  final int level;
  final List<int> operands;
  final ArithmeticOperation? operation;
  final int expectedAnswer;
  final QuestionType type;
  final int flashSpeedMs; // Dành cho Flash Anzan (1000 - 2500 ms)

  const SorobanQuestion({
    required this.id,
    required this.level,
    required this.operands,
    this.operation,
    required this.expectedAnswer,
    required this.type,
    this.flashSpeedMs = 2500,
  });

  String get formulaExpression {
    if (operands.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < operands.length; i++) {
      final val = operands[i];
      if (i == 0) {
        buffer.write('$val');
      } else if (i == 1 && operation != null) {
        final operator = operation == ArithmeticOperation.addition ? '+' : '-';
        buffer.write(' $operator ${val.abs()}');
      } else {
        if (val >= 0) {
          buffer.write(' + $val');
        } else {
          buffer.write(' - ${val.abs()}');
        }
      }
    }
    return buffer.toString();
  }

  /// Chuỗi đọc phát âm tiếng Việt đầy đủ dấu phép tính ("cộng", "trừ", "bằng")
  String get spokenExpression {
    if (operands.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < operands.length; i++) {
      final val = operands[i];
      if (i == 0) {
        buffer.write('$val');
      } else if (i == 1 && operation != null) {
        final operator =
            operation == ArithmeticOperation.addition ? 'cộng' : 'trừ';
        buffer.write(' $operator ${val.abs()}');
      } else {
        if (val >= 0) {
          buffer.write(' cộng $val');
        } else {
          buffer.write(' trừ ${val.abs()}');
        }
      }
    }
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
        id,
        level,
        operands,
        operation,
        expectedAnswer,
        type,
        flashSpeedMs,
      ];
}

/// Bí danh chuẩn cho Finger Math
typedef FingerMathQuestion = SorobanQuestion;
