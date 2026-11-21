import 'package:equatable/equatable.dart';
import '../../../../core/services/audio_service.dart';

enum HandType { rightHand, leftHand }

/// Trạng thái một bàn tay trong hệ thống Finger Math chuẩn 2 bàn tay:
/// - Tay Phải (Right Hand - RH): Đại diện cho HÀNG ĐƠN VỊ (từ 0 đến 9)
///   + Ngón cái = 5
///   + Mỗi ngón dài (trỏ, giữa, áp út, út) = 1
/// - Tay Trái (Left Hand - LH): Đại diện cho HÀNG CHỤC (từ 10 đến 90)
///   + Ngón cái = 50
///   + Mỗi ngón dài (trỏ, giữa, áp út, út) = 10
class FingerHandState extends Equatable {
  final HandType handType; // rightHand: Hàng đơn vị (0-9), leftHand: Hàng chục (10-90)
  final bool isThumbExtended; // Ngón cái xòe (5 ở tay phải, 50 ở tay trái)
  final int extendedFingersCount; // Số ngón dài xòe (0..4: trỏ, giữa, áp út, út)

  const FingerHandState({
    required this.handType,
    this.isThumbExtended = false,
    this.extendedFingersCount = 0,
  });

  /// Giá trị chữ số trên bàn tay (0 đến 9)
  int get digitValue => (isThumbExtended ? 5 : 0) + extendedFingersCount;

  /// Giá trị thực tế theo hệ thập phân (Tay Phải: 0..9, Tay Trái: 0..90)
  int get actualValue {
    final multiplier = handType == HandType.rightHand ? 1 : 10;
    return digitValue * multiplier;
  }

  /// Tên gọi bàn tay
  String get handName => handType == HandType.rightHand ? 'Tay Phải' : 'Tay Trái';

  /// Mô tả chi tiết trực quan thao tác các ngón tay theo chuẩn Finger Math
  String get fingerDescription {
    final isRight = handType == HandType.rightHand;
    final unitVal = isRight ? 1 : 10;
    final thumbVal = isRight ? 5 : 50;

    switch (digitValue) {
      case 0:
        return '$handName: Nắm tay (0)';
      case 1:
        return '$handName: 1 ngón trỏ ($unitVal)';
      case 2:
        return '$handName: 2 ngón trỏ + giữa (${2 * unitVal})';
      case 3:
        return '$handName: 3 ngón trỏ + giữa + áp út (${3 * unitVal})';
      case 4:
        return '$handName: 4 ngón dài (${4 * unitVal})';
      case 5:
        return '$handName: Ngón cái ($thumbVal)';
      case 6:
        return '$handName: Ngón cái ($thumbVal) + 1 ngón trỏ ($unitVal) = ${6 * unitVal}';
      case 7:
        return '$handName: Ngón cái ($thumbVal) + 2 ngón (${2 * unitVal}) = ${7 * unitVal}';
      case 8:
        return '$handName: Ngón cái ($thumbVal) + 3 ngón (${3 * unitVal}) = ${8 * unitVal}';
      case 9:
        return '$handName: Cả 5 ngón xòe = ${9 * unitVal}';
      default:
        return '$handName: $actualValue';
    }
  }

  /// Ký hiệu rút gọn
  String get shortNotation {
    final prefix = handType == HandType.rightHand ? 'TP' : 'TT';
    if (digitValue == 0) return '$prefix: Nắm (0)';
    if (digitValue == 5) return '$prefix: Ngón cái ($actualValue)';
    if (digitValue < 5) return '$prefix: $extendedFingersCount ngón ($actualValue)';
    return '$prefix: Cái + $extendedFingersCount ngón ($actualValue)';
  }

  FingerHandState copyWith({
    HandType? handType,
    bool? isThumbExtended,
    int? extendedFingersCount,
  }) {
    return FingerHandState(
      handType: handType ?? this.handType,
      isThumbExtended: isThumbExtended ?? this.isThumbExtended,
      extendedFingersCount: extendedFingersCount ?? this.extendedFingersCount,
    );
  }

  /// Khởi tạo trạng thái bàn tay từ giá trị chữ số (0 đến 9)
  factory FingerHandState.fromValue(int value, {HandType handType = HandType.rightHand}) {
    final clamped = value.clamp(0, 9);
    final thumb = clamped >= 5;
    final fingers = clamped % 5;
    return FingerHandState(
      handType: handType,
      isThumbExtended: thumb,
      extendedFingersCount: fingers,
    );
  }

  @override
  List<Object?> get props => [handType, isThumbExtended, extendedFingersCount];
}

/// Loại công thức toán tư duy Finger Math
enum FormulaCategory {
  direct, // Tính trực tiếp (không dùng công thức)
  smallFriendAddition, // Anh bạn nhỏ cộng (+4 = +5 - 1...)
  smallFriendSubtraction, // Anh bạn nhỏ trừ (-4 = -5 + 1...)
  bigFriendAddition, // Anh bạn lớn cộng (+9 = +10 - 1, phối hợp 2 tay)
  bigFriendSubtraction, // Anh bạn lớn trừ (-9 = -10 + 1, phối hợp 2 tay)
}

/// Helper phân tích công thức Anh Bạn Nhỏ và Anh Bạn Lớn
class FingerMathFormulaHelper {
  /// Tìm cặp Anh Bạn Nhỏ (tổng bằng 5)
  static int getSmallFriend(int n) => 5 - n;

  /// Tìm cặp Anh Bạn Lớn (tổng bằng 10)
  static int getBigFriend(int n) => 10 - n;

  /// Tạo gợi ý công thức và hành động thao tác tay
  static String getStepInstruction({
    required int currentValue,
    required int operand, // số cần cộng (dương) hoặc trừ (âm)
  }) {
    if (operand == 0) return 'Giữ nguyên 2 bàn tay.';

    final isAdd = operand > 0;
    final absVal = operand.abs();

    // 1. Phép cộng
    if (isAdd) {
      final unitCurrent = currentValue % 10;
      final unitResult = unitCurrent + absVal;

      // TH1: Vượt qua 10 -> Cần dùng ANH BẠN LỚN (phối hợp Tay Trái & Tay Phải)
      if (unitResult >= 10 && absVal <= 9) {
        final bigFriend = getBigFriend(absVal);
        return 'Công thức Anh Bạn Lớn (+$absVal = +10 - $bigFriend):\n'
            '👉 Tay Trái: Bung 1 ngón (+10)\n'
            '👉 Tay Phải: Gập $bigFriend ngón (-$bigFriend)';
      }

      // TH2: Cộng trong phạm vi 5 nhưng thiếu ngón dài -> ANH BẠN NHỎ
      if (unitCurrent < 5 && unitResult >= 5 && absVal < 5) {
        final smallFriend = getSmallFriend(absVal);
        return 'Công thức Anh Bạn Nhỏ (+$absVal = +5 - $smallFriend):\n'
            '👉 Tay Phải: Xòe ngón cái (+5)\n'
            '👉 Tay Phải: Gập $smallFriend ngón dài (-$smallFriend)';
      }

      return 'Cộng trực tiếp: Bung thêm $absVal ngón trên Tay Phải.';
    }

    // 2. Phép trừ
    final unitCurrent = currentValue % 10;

    // TH1: Không đủ ngón ở hàng đơn vị -> Cần dùng ANH BẠN LỚN trừ (mượn 10 từ Tay Trái)
    if (unitCurrent < absVal && absVal <= 9) {
      final bigFriend = getBigFriend(absVal);
      return 'Công thức Anh Bạn Lớn (-$absVal = -10 + $bigFriend):\n'
          '👉 Tay Trái: Gập 1 ngón (-10)\n'
          '👉 Tay Phải: Bung $bigFriend ngón (+$bigFriend)';
    }

    // TH2: Trừ trong phạm vi 5 nhưng không đủ ngón dài -> ANH BẠN NHỎ trừ
    if (unitCurrent >= 5 && (unitCurrent - absVal) < 5 && absVal < 5) {
      final smallFriend = getSmallFriend(absVal);
      return 'Công thức Anh Bạn Nhỏ (-$absVal = -5 + $smallFriend):\n'
          '👉 Tay Phải: Gập ngón cái (-5)\n'
          '👉 Tay Phải: Bung $smallFriend ngón dài (+$smallFriend)';
    }

    return 'Trừ trực tiếp: Gập bớt $absVal ngón trên Tay Phải.';
  }

  /// Tạo hướng dẫn giải chi tiết từng bước cho bài toán Finger Math
  static FingerMathGuidance generateFullGuidance({
    required List<int> operands,
    required int expectedAnswer,
  }) {
    if (operands.isEmpty) {
      return FingerMathGuidance(
        steps: ['Bắt đầu với 2 bàn tay nắm lại (0).'],
        spokenText: 'Bắt đầu với hai bàn tay nắm lại bằng không.',
        expectedAnswer: expectedAnswer,
      );
    }

    final steps = <String>[];
    final spokenParts = <String>[];

    int runningTotal = 0;

    // Bước 1: Số đầu tiên
    final firstOp = operands.first;
    runningTotal = firstOp;
    if (firstOp < 10) {
      if (firstOp == 0) {
        steps.add('👉 Bước 1: Bắt đầu từ 0 (Tay Phải nắm lại).');
        spokenParts.add('Bước một: Bắt đầu từ không, tay phải nắm lại.');
      } else if (firstOp < 5) {
        steps.add('👉 Bước 1: Bắt đầu từ $firstOp (Tay Phải bung $firstOp ngón dài).');
        spokenParts.add('Bước một: Bắt đầu từ số $firstOp, tay phải bung $firstOp ngón dài.');
      } else if (firstOp == 5) {
        steps.add('👉 Bước 1: Bắt đầu từ 5 (Tay Phải xòe ngón cái = 5).');
        spokenParts.add('Bước một: Bắt đầu từ số năm, tay phải xòe ngón cái.');
      } else {
        final rem = firstOp - 5;
        steps.add('👉 Bước 1: Bắt đầu từ $firstOp (Tay Phải xòe ngón cái 5 + $rem ngón dài).');
        spokenParts.add('Bước một: Bắt đầu từ số $firstOp, tay phải xòe ngón cái năm và $rem ngón dài.');
      }
    } else {
      final tens = firstOp ~/ 10;
      final units = firstOp % 10;
      steps.add('👉 Bước 1: Bắt đầu từ $firstOp (Tay Trái bung $tens ngón = ${tens * 10}, Tay Phải $units ngón).');
      spokenParts.add('Bước một: Bắt đầu từ số $firstOp, tay trái bung $tens ngón chục, tay phải $units ngón đơn vị.');
    }

    // Các bước tiếp theo
    for (int i = 1; i < operands.length; i++) {
      final op = operands[i];
      final isAdd = op > 0;
      final absVal = op.abs();
      final stepNum = i + 1;

      final instruction = getStepInstruction(
        currentValue: runningTotal,
        operand: op,
      );

      final prefix = isAdd ? 'Cộng $absVal' : 'Trừ $absVal';
      steps.add('👉 Bước $stepNum: $prefix:\n$instruction');

      // Tạo câu nói tự nhiên cho TTS
      final spokenPrefix = isAdd ? 'cộng $absVal' : 'trừ $absVal';
      if (instruction.contains('Anh Bạn Nhỏ')) {
        spokenParts.add('Bước $stepNum: $spokenPrefix, áp dụng công thức anh bạn nhỏ.');
      } else if (instruction.contains('Anh Bạn Lớn')) {
        spokenParts.add('Bước $stepNum: $spokenPrefix, áp dụng công thức anh bạn lớn.');
      } else {
        spokenParts.add('Bước $stepNum: $spokenPrefix, thao tác trực tiếp trên các ngón tay.');
      }

      runningTotal += op;
    }

    // Kết luận
    final tensAns = expectedAnswer ~/ 10;
    final unitsAns = expectedAnswer % 10;
    String finalDesc;
    if (expectedAnswer < 10) {
      finalDesc = 'Tay Phải giữ $expectedAnswer';
    } else {
      finalDesc = 'Tay Trái giữ ${tensAns * 10} và Tay Phải giữ $unitsAns';
    }
    steps.add('✨ Kết quả: $finalDesc ➡️ Đáp án đúng là $expectedAnswer.');
    spokenParts.add('Kết quả chính xác là $expectedAnswer bé nhé!');

    return FingerMathGuidance(
      steps: steps,
      spokenText: AudioService.normalizeToVietnamese(spokenParts.join(' ')),
      expectedAnswer: expectedAnswer,
    );
  }
}

/// Dữ liệu hướng dẫn từng bước
class FingerMathGuidance {
  final List<String> steps;
  final String spokenText;
  final int expectedAnswer;

  const FingerMathGuidance({
    required this.steps,
    required this.spokenText,
    required this.expectedAnswer,
  });
}
