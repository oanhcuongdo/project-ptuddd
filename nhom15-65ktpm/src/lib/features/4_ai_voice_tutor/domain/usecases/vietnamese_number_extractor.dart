import 'package:equatable/equatable.dart';

enum ExtractionType {
  number,
  unknown, // Trẻ nói từ chối / không biết (ví dụ: "con không biết", "chịu", "khó quá")
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
  bool get isEmpty => type == ExtractionType.empty;

  @override
  List<Object?> get props => [type, value, rawSpeech, normalizedSpeech];
}

/// Bộ phân tích và trích xuất số tiếng Việt cho trẻ em mầm non:
/// 1. Chuẩn hóa & loại bỏ từ đệm, từ xưng hô lễ phép ("dạ thưa cô", "ạ", "con tính ra", "bằng",...)
/// 2. Bóc tách số dạng chữ số (0-999) & số dạng chữ (hàng chục, hàng trăm, phương ngữ như "lăm", "nhăm", "mốt", "hăm mốt", "tư", "linh", "lẻ")
/// 3. Nhận diện các câu từ chối / chưa biết ("con không biết", "chịu", "khó quá", "bỏ qua") để trả về ExtractionResult.unknown và kích hoạt gợi ý
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
        .replaceAll(RegExp(r'[,.\-?!;:]'), ' ')
        .trim();

    // 2. Kiểm tra mẫu từ chối / không biết của trẻ em
    final refusalPatterns = [
      'không biết',
      'con không biết',
      'chưa biết',
      'không nhớ',
      'không rõ',
      'không hiểu',
      'chịu',
      'con chịu',
      'khó quá',
      'khó thế',
      'bỏ qua',
      'chưa tính ra',
      'chưa tính được',
      'không làm được',
    ];

    for (final pattern in refusalPatterns) {
      if (normalized.contains(pattern)) {
        return ExtractionResult.unknown(
          rawSpeech: rawSpeech,
          normalizedSpeech: normalized,
        );
      }
    }

    // 3. Kiểm tra nếu có chữ số trực tiếp trong câu (ví dụ STT trả về "15" hoặc "bằng 25")
    final digitMatch = RegExp(r'\b\d+\b').firstMatch(rawSpeech);
    if (digitMatch != null) {
      final parsed = int.tryParse(digitMatch.group(0)!);
      if (parsed != null) {
        return ExtractionResult.number(
          value: parsed,
          rawSpeech: rawSpeech,
          normalizedSpeech: normalized,
        );
      }
    }

    // 4. Chuẩn hóa các biến thể phương ngữ thông dụng
    // "hăm mốt" -> "hai mươi mốt", "hăm nhăm" -> "hai mươi lăm", "hăm" -> "hai mươi"
    normalized = normalized.replaceAll('hăm mốt', 'hai mươi mốt');
    normalized = normalized.replaceAll('hăm nhăm', 'hai mươi lăm');
    normalized = normalized.replaceAll('hăm lăm', 'hai mươi lăm');
    normalized = normalized.replaceAll('hăm tư', 'hai mươi bốn');
    normalized = normalized.replaceAllMapped(
      RegExp(r'\bhăm\b'),
      (match) => 'hai mươi',
    );

    // 5. Loại bỏ từ đệm, từ xưng hô thông dụng của trẻ em
    final fillerWords = [
      'dạ thưa cô',
      'dạ thưa thầy',
      'thưa cô',
      'thưa thầy',
      'dạ cô',
      'dạ thầy',
      'dạ',
      'thưa',
      'ạ cô',
      'ạ thầy',
      'ạ',
      'con tính ra',
      'con nghĩ là',
      'con tính là',
      'con nghĩ',
      'con',
      'em tính ra',
      'em',
      'cháu',
      'kết quả là',
      'kết quả',
      'đáp án là',
      'đáp án',
      'bằng',
      'là',
      'số',
      'câu',
      'nè cô',
      'nè',
      'nhé',
      'chào cô',
      'chào thầy',
    ];

    for (final filler in fillerWords) {
      normalized = normalized.replaceAll(filler, ' ');
    }

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return ExtractionResult.empty(rawSpeech: rawSpeech);
    }

    // 6. Phân tích ngữ nghĩa số tiếng Việt
    final parsedValue = _parseTokens(tokens);
    if (parsedValue != null) {
      return ExtractionResult.number(
        value: parsedValue,
        rawSpeech: rawSpeech,
        normalizedSpeech: normalized,
      );
    }

    return ExtractionResult.empty(rawSpeech: rawSpeech);
  }

  /// Hàm tiện ích tương thích ngược trực tiếp trả về int?
  static int? extractNumber(String rawSpeech) {
    return extract(rawSpeech).value;
  }

  static int? _parseTokens(List<String> words) {
    // Trường hợp 1 từ: "năm" -> 5, "mười" -> 10, "không" -> 0, "trăm" -> 100
    if (words.length == 1) {
      final w = words.first;
      if (w == 'mười' || w == 'chục') return 10;
      if (w == 'trăm') return 100;
      if (_unitWords.containsKey(w)) return _unitWords[w];
      return null;
    }

    // Trường hợp hàng trăm: ví dụ "một trăm", "một trăm linh năm", "hai trăm hai mươi mốt"
    if (words.contains('trăm')) {
      final tramIndex = words.indexOf('trăm');
      int hundreds = 1;
      if (tramIndex > 0) {
        hundreds = _unitWords[words[tramIndex - 1]] ?? 1;
      }

      final remainderWords = words.sublist(tramIndex + 1);
      if (remainderWords.isEmpty) {
        return hundreds * 100;
      }

      // Xử lý "linh" hoặc "lẻ": ví dụ "linh năm" -> 5
      if (remainderWords.first == 'linh' || remainderWords.first == 'lẻ') {
        if (remainderWords.length > 1) {
          final unit = _unitWords[remainderWords[1]];
          if (unit != null) return hundreds * 100 + unit;
        }
        return hundreds * 100;
      }

      final remValue = _parseTokens(remainderWords);
      if (remValue != null) {
        return hundreds * 100 + remValue;
      }
      return hundreds * 100;
    }

    // Trường hợp 2 từ:
    // "mười một" -> 11, "mười lăm" -> 15
    // "hai mươi" -> 20, "hai mốt" -> 21, "ba lăm" -> 35, "hai nhăm" -> 25, "bốn tư" -> 44
    if (words.length == 2) {
      final w1 = words[0];
      final w2 = words[1];

      if (w1 == 'mười') {
        final unit = _unitWords[w2];
        if (unit != null) return 10 + unit;
      }

      final tens = _unitWords[w1];
      if (tens != null) {
        if (w2 == 'mươi' || w2 == 'chục') return tens * 10;
        final unit = _unitWords[w2];
        if (unit != null) return tens * 10 + unit;
      }
      return null;
    }

    // Trường hợp 3 từ:
    // "hai mươi mốt" -> 21, "ba mươi lăm" -> 35, "bốn mươi tư" -> 44
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
