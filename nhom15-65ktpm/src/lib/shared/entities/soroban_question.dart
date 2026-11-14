import 'package:equatable/equatable.dart';

enum QuestionType { recognition, smallFriend, bigFriend, flashAnzan }

class SorobanQuestion extends Equatable {
  final String id;
  final int level;
  final List<int> operands;
  final int expectedAnswer;
  final QuestionType type;
  final int flashSpeedMs; // Dành cho Flash Anzan (500 - 2000 ms)

  const SorobanQuestion({
    required this.id,
    required this.level,
    required this.operands,
    required this.expectedAnswer,
    required this.type,
    this.flashSpeedMs = 1200,
  });

  String get formulaExpression {
    if (operands.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < operands.length; i++) {
      final val = operands[i];
      if (i == 0) {
        buffer.write('$val');
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

  @override
  List<Object?> get props => [
        id,
        level,
        operands,
        expectedAnswer,
        type,
        flashSpeedMs,
      ];
}
