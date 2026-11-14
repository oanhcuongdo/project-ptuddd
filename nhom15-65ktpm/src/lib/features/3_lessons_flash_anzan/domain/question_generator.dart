import 'dart:math';
import '../../../../shared/entities/soroban_question.dart';

class QuestionGenerator {
  static final Random _random = Random();

  /// Sinh câu hỏi theo cấp độ 1, 2, 3
  static SorobanQuestion generate(int level, {int flashSpeedMs = 1200}) {
    switch (level) {
      case 1:
        return _generateLevel1();
      case 2:
        return _generateLevel2();
      case 3:
      default:
        return _generateLevel3(flashSpeedMs: flashSpeedMs);
    }
  }

  /// Cấp độ 1: Nhận diện và cộng trừ đơn giản trực tiếp trên bàn tính (kết quả trong phạm vi 0 - 9)
  static SorobanQuestion _generateLevel1() {
    // Các phép tính trực tiếp không cần mượn: ví dụ 1+2, 5+2, 3+1, 4-2, 6+3
    final templates = [
      [1, 2],
      [2, 2],
      [5, 3],
      [6, 2],
      [4, -2],
      [7, -5],
      [3, 5],
      [8, -3],
      [5, 4],
      [9, -4],
    ];
    final selected = templates[_random.nextInt(templates.length)];
    final answer = selected.reduce((a, b) => a + b);

    return SorobanQuestion(
      id: 'lvl1_${DateTime.now().millisecondsSinceEpoch}',
      level: 1,
      operands: selected,
      expectedAnswer: answer,
      type: QuestionType.recognition,
    );
  }

  /// Cấp độ 2: Công thức Anh bạn nhỏ (Cộng trừ có liên quan đến hạt 5)
  static SorobanQuestion _generateLevel2() {
    // Ví dụ: 4 + 1 = 5 (hạ 5 gạt 4), 3 + 3 = 6, 2 + 4 = 6, 5 - 2 = 3
    final templates = [
      [4, 1], // +1 = +5 - 4
      [3, 2], // +2 = +5 - 3
      [2, 3], // +3 = +5 - 2
      [1, 4], // +4 = +5 - 1
      [5, -1], // -1 = -5 + 4
      [5, -2], // -2 = -5 + 3
      [6, -2],
      [7, -3],
      [2, 4],
      [3, 3],
    ];
    final selected = templates[_random.nextInt(templates.length)];
    final answer = selected.reduce((a, b) => a + b);

    return SorobanQuestion(
      id: 'lvl2_${DateTime.now().millisecondsSinceEpoch}',
      level: 2,
      operands: selected,
      expectedAnswer: answer,
      type: QuestionType.smallFriend,
    );
  }

  /// Cấp độ 3: Tính nhẩm nhanh Flash Anzan (Chuỗi 3 đến 4 số liên tiếp)
  static SorobanQuestion _generateLevel3({int flashSpeedMs = 1200}) {
    final templates = [
      [2, 5, 1], // = 8
      [3, 1, 5], // = 9
      [7, -2, 3], // = 8
      [5, 4, -3], // = 6
      [1, 3, 5, -2], // = 7
      [4, 5, -3, 2], // = 8
      [6, 3, -5, 4], // = 8
    ];
    final selected = templates[_random.nextInt(templates.length)];
    final answer = selected.reduce((a, b) => a + b);

    return SorobanQuestion(
      id: 'lvl3_${DateTime.now().millisecondsSinceEpoch}',
      level: 3,
      operands: selected,
      expectedAnswer: answer,
      type: QuestionType.flashAnzan,
      flashSpeedMs: flashSpeedMs,
    );
  }
}
