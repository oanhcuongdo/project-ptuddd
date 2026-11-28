import 'package:equatable/equatable.dart';

enum ExtractionType {
  number,
  unknown, // Trẻ nói từ chối / không biết (ví dụ: "con không biết", "chịu", "khó quá", "bỏ qua")
  unrecognized, // Chuỗi không nhận diện được số hợp lệ
  empty,
}

class ExtractionResult extends Equatable {
  final ExtractionType type;
  final int? value;
  final String rawSpeech;
  final String normalizedSpeech;

  const ExtractionResult({
    required this.type,
    this.value,
    required this.rawSpeech,
    required this.normalizedSpeech,
  });

  const ExtractionResult.number({
    required int value,
    required String rawSpeech,
    required String normalizedSpeech,
  }) : this(
          type: ExtractionType.number,
          value: value,
          rawSpeech: rawSpeech,
          normalizedSpeech: normalizedSpeech,
        );

  const ExtractionResult.unknown({
    required String rawSpeech,
    required String normalizedSpeech,
  }) : this(
          type: ExtractionType.unknown,
          value: null,
          rawSpeech: rawSpeech,
          normalizedSpeech: normalizedSpeech,
        );

  const ExtractionResult.unrecognized({
    required String rawSpeech,
    required String normalizedSpeech,
  }) : this(
          type: ExtractionType.unrecognized,
          value: null,
          rawSpeech: rawSpeech,
          normalizedSpeech: normalizedSpeech,
        );

  const ExtractionResult.empty({
    required String rawSpeech,
  }) : this(
          type: ExtractionType.empty,
          value: null,
          rawSpeech: rawSpeech,
          normalizedSpeech: '',
        );

  bool get isNumber => type == ExtractionType.number;
  bool get isUnknown => type == ExtractionType.unknown;
  bool get isUnrecognized => type == ExtractionType.unrecognized;
  bool get isEmpty => type == ExtractionType.empty;

  @override
  List<Object?> get props => [type, value, rawSpeech, normalizedSpeech];
}

/// Bộ phân tích và trích xuất số tiếng Việt cho trẻ em:
/// 1. Chuẩn hóa & loại bỏ từ đệm, từ xưng hô lễ phép ("dạ", "thưa cô", "thưa thầy", "kết quả là", "đáp án là", "bằng", "là", "ạ", "ơi",...)
/// 2. Bóc tách số dạng chữ số lẫn chữ viết trong phạm vi số nguyên 0 đến 99.
///    - Nếu số ngoài phạm vi 0-99 (hoặc số âm) thì trả về null.
/// 3. Nhận diện chuẩn các biến thể vùng miền: "lăm" -> 5, "nhăm" -> 5, "mốt" -> 1, "tư" -> 4, "hăm" -> 20.
/// 4. Nhận diện câu từ chối: "con không biết", "không biết", "chịu", "bỏ qua", "khó quá" -> bắt buộc trả về null (ExtractionResult.unknown).
class VietnameseNumberExtractor {
  static const Map<String, int> _unitWords = {
    'không': 0,
    'mot': 1,
    'một': 1,
    'mốt': 1,
    'hai': 2,
    'ba': 3,
    'bon': 4,
    'bốn': 4,
    'tư': 4,
    'nam': 5,
    'năm': 5,
    'lăm': 5,
    'nhăm': 5,
    'sau': 6,
    'sáu': 6,
    'bay': 7,
    'bảy': 7,
    'bẩy': 7,
    'tam': 8,
    'tám': 8,
    'chin': 9,
    'chín': 9,
  };

  /// Trích xuất chi tiết kết quả xử lý chuỗi transcript tiếng Việt
  static ExtractionResult extract(String rawSpeech) {
    if (rawSpeech.trim().isEmpty) {
      return ExtractionResult.empty(rawSpeech: rawSpeech);
    }

    // 1. Chuẩn hóa văn bản cơ bản
    String normalized = rawSpeech
        .toLowerCase()
        .replaceAll(RegExp(r'[,.?!;:]'), ' ')
        .trim();

    // 2. Xử lý câu từ chối: "con không biết", "không biết", "chịu", "bỏ qua", "khó quá"
    // Bắt buộc trả về null (ExtractionResult.unknown) để kích hoạt gợi ý thay vì tính là trả lời sai
    final refusalPatterns = [
      'không biết',
      'con không biết',
      'chưa biết',
      'không nhớ',
      'không rõ',
      'không hiểu',
      'con không hiểu',
      'chịu',
      'con chịu',
      'chịu thôi',
      'khó quá',
      'khó thế',
      'khó vậy',
      'bỏ qua',
      'qua câu khác',
      'chưa tính ra',
      'chưa tính được',
      'không làm được',
      'con không làm được',
      'không giải được',
    ];

    for (final pattern in refusalPatterns) {
      if (normalized.contains(pattern)) {
        return ExtractionResult.unknown(
          rawSpeech: rawSpeech,
          normalizedSpeech: normalized,
        );
      }
    }

    // 3. Nếu câu chứa số âm (dạng -5 hoặc "âm ...", "trừ ...") -> ngoài phạm vi 0-99 -> trả về null
    if (rawSpeech.contains(RegExp(r'-\s*\d+')) ||
        normalized.contains('âm ') ||
        normalized.contains('trừ ') ||
        normalized.startsWith('-')) {
      return ExtractionResult.empty(rawSpeech: rawSpeech);
    }

    // 4. Kiểm tra nếu có chữ số trực tiếp trong câu (ví dụ STT trả về "25", "dạ bằng 25")
    final digitMatch = RegExp(r'\b\d+\b').firstMatch(rawSpeech);
    if (digitMatch != null) {
      final parsed = int.tryParse(digitMatch.group(0)!);
      if (parsed != null) {
        // Chỉ chấp nhận trong phạm vi 0 đến 99, ngoài phạm vi trả về null
        if (parsed >= 0 && parsed <= 99) {
          return ExtractionResult.number(
            value: parsed,
            rawSpeech: rawSpeech,
            normalizedSpeech: normalized,
          );
        } else {
          return ExtractionResult.empty(rawSpeech: rawSpeech);
        }
      }
    }

    // Kiểm tra các từ chỉ hàng trăm, hàng nghìn, triệu, tỷ -> ngoài phạm vi 0-99
    final paddedCheck = ' $normalized ';
    if (paddedCheck.contains(' trăm ') ||
        paddedCheck.contains(' nghìn ') ||
        paddedCheck.contains(' ngàn ') ||
        paddedCheck.contains(' triệu ') ||
        paddedCheck.contains(' tỷ ')) {
      return ExtractionResult.empty(rawSpeech: rawSpeech);
    }

    // 5. Chuẩn hóa các biến thể phương ngữ thông dụng
    // "hăm mốt" -> "hai mươi mốt", "hăm nhăm" -> "hai mươi lăm", "hăm" -> "hai mươi"
    normalized = normalized.replaceAll('hăm mốt', 'hai mươi mốt');
    normalized = normalized.replaceAll('hăm nhăm', 'hai mươi lăm');
    normalized = normalized.replaceAll('hăm lăm', 'hai mươi lăm');
    normalized = normalized.replaceAll('hăm tư', 'hai mươi bốn');
    normalized = normalized.replaceAll('hăm hai', 'hai mươi hai');
    normalized = normalized.replaceAll('hăm ba', 'hai mươi ba');
    normalized = normalized.replaceAllMapped(
      RegExp(r'\bhăm\b'),
      (match) => 'hai mươi',
    );

    // 6. Loại bỏ từ đệm, từ xưng hô thông dụng của trẻ em
    // Sắp xếp giảm dần theo độ dài để tránh cắt cụm từ
    final fillerWords = [
      'dạ thưa cô bằng',
      'dạ thưa thầy bằng',
      'thưa cô bằng',
      'thưa thầy bằng',
      'dạ thưa cô',
      'dạ thưa thầy',
      'cho con hỏi',
      'kết quả là bằng',
      'đáp án là bằng',
      'kết quả là',
      'đáp án là',
      'kết quả bằng',
      'đáp án bằng',
      'con tính ra',
      'em tính ra',
      'con nghĩ là',
      'con tính là',
      'thưa cô',
      'thưa thầy',
      'chào cô',
      'chào thầy',
      'cô ơi',
      'thầy ơi',
      'ơi cô',
      'ơi thầy',
      'kết quả',
      'đáp án',
      'dạ cô',
      'dạ thầy',
      'ạ cô',
      'ạ thầy',
      'con nghĩ',
      'nè cô',
      'bằng',
      'thưa',
      'cháu',
      'con',
      'em',
      'nhé',
      'nè',
      'dạ',
      'ạ',
      'ơi',
      'là',
      'số',
      'câu',
    ];

    String padded = ' $normalized ';
    for (final filler in fillerWords) {
      while (padded.contains(' $filler ')) {
        padded = padded.replaceAll(' $filler ', ' ');
      }
    }
    normalized = padded.replaceAll(RegExp(r'\s+'), ' ').trim();

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return ExtractionResult.empty(rawSpeech: rawSpeech);
    }

    // 7. Phân tích ngữ nghĩa số tiếng Việt (phạm vi 0 đến 99)
    final parsedValue = _parseTokens(tokens);
    if (parsedValue != null) {
      // Kiểm tra phạm vi 0 đến 99
      if (parsedValue >= 0 && parsedValue <= 99) {
        return ExtractionResult.number(
          value: parsedValue,
          rawSpeech: rawSpeech,
          normalizedSpeech: normalized,
        );
      } else {
        return ExtractionResult.empty(rawSpeech: rawSpeech);
      }
    }

    return ExtractionResult.unrecognized(
      rawSpeech: rawSpeech,
      normalizedSpeech: normalized,
    );
  }

  /// Hàm tiện ích chính nhận vào chuỗi tiếng Việt và trả về int? trong phạm vi 0 đến 99.
  /// Bắt buộc trả về null nếu trẻ từ chối trả lời (isUnknown) hoặc số ngoài phạm vi 0-99.
  static int? extractNumber(String rawSpeech) {
    return extract(rawSpeech).value;
  }

  static int? _parseTokens(List<String> words) {
    // Nếu chứa các từ ngoài phạm vi 0-99 (trăm, nghìn, ngàn, triệu, tỷ) -> trả về null
    if (words.contains('trăm') ||
        words.contains('nghìn') ||
        words.contains('ngàn') ||
        words.contains('triệu') ||
        words.contains('tỷ')) {
      return null;
    }

    // Trường hợp 1 từ: 0..10
    // "không" -> 0, "năm" -> 5, "mười" / "chục" -> 10, "lăm"/"nhăm" -> 5, "mốt" -> 1, "tư" -> 4
    if (words.length == 1) {
      final w = words.first;
      if (w == 'mười' || w == 'chục') return 10;
      if (_unitWords.containsKey(w)) return _unitWords[w];
      return null;
    }

    // Trường hợp 2 từ:
    // "linh" / "lẻ": ví dụ "linh năm" -> 5, "lẻ bảy" -> 7
    if (words.length == 2 && (words[0] == 'linh' || words[0] == 'lẻ')) {
      return _unitWords[words[1]];
    }

    // "mười một" -> 11, "mười lăm" / "mười nhăm" -> 15, "mười tư" -> 14
    if (words.length == 2 && words[0] == 'mười') {
      final unit = _unitWords[words[1]];
      if (unit != null) return 10 + unit;
      return null;
    }

    // "hai mươi" -> 20, "hai chục" -> 20, "hai mốt" -> 21, "ba lăm" -> 35, "hai nhăm" -> 25, "bốn tư" -> 44, "chín chín" -> 99
    if (words.length == 2) {
      final tens = _unitWords[words[0]];
      if (tens != null) {
        if (words[1] == 'mươi' || words[1] == 'chục') return tens * 10;
        final unit = _unitWords[words[1]];
        if (unit != null) return tens * 10 + unit;
      }
      return null;
    }

    // Trường hợp 3 từ:
    // "hai mươi mốt" -> 21, "ba mươi lăm" -> 35, "hai mươi nhăm" -> 25, "bốn mươi tư" -> 44, "chín mươi chín" -> 99
    if (words.length == 3) {
      final w1 = words[0];
      final w2 = words[1];
      final w3 = words[2];

      if (w2 == 'mươi' || w2 == 'chục') {
        final tens = _unitWords[w1];
        final unit = _unitWords[w3];
        if (tens != null && unit != null) {
          return tens * 10 + unit;
        }
      }
    }

    return null;
  }
}
