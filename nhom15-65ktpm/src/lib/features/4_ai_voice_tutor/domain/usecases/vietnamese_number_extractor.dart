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

  /// Bóc tách số nguyên từ chuỗi giọng nói của trẻ em
  /// Ví dụ: "dạ thưa cô bằng mười lăm ạ" -> 15
  /// "con tính ra hai mươi mốt" -> 21
  /// "số năm" -> 5
  static int? extractNumber(String rawSpeech) {
    if (rawSpeech.trim().isEmpty) return null;

    // 1. Kiểm tra nếu có số dạng chữ số trực tiếp (ví dụ STT trả về "15" hoặc "bằng 15")
    final digitMatch = RegExp(r'\b\d+\b').firstMatch(rawSpeech);
    if (digitMatch != null) {
      return int.tryParse(digitMatch.group(0)!);
    }

    // 2. Chuẩn hóa câu nói: chuyển chữ thường, loại bỏ dấu câu
    String normalized = rawSpeech
        .toLowerCase()
        .replaceAll(RegExp(r'[,.\-?!;:]'), ' ')
        .trim();

    // 3. Loại bỏ các cụm từ phủ định (ví dụ "không biết", "không nhớ")
    final negativePhrases = [
      'không biết',
      'không nhớ',
      'không rõ',
      'không hiểu',
      'chưa biết',
      'chưa tính ra',
    ];
    for (final neg in negativePhrases) {
      normalized = normalized.replaceAll(neg, ' ');
    }

    // 4. Loại bỏ các từ đệm, từ xưng hô thông dụng của trẻ em
    final fillerWords = [
      'dạ', 'ạ', 'thưa cô', 'thưa thầy', 'thưa', 'con', 'em', 'cháu',
      'nghĩ là', 'tính ra', 'kết quả là', 'kết quả', 'bằng', 'là',
      'đáp án là', 'đáp án', 'số', 'câu', 'nè', 'nè cô', 'chào cô', 'chào thầy'
    ];

    for (final filler in fillerWords) {
      normalized = normalized.replaceAll(filler, ' ');
    }

    final words = normalized
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return null;

    // 5. Phân tích ngữ nghĩa số tiếng Việt (hỗ trợ số từ 0 đến 99)
    return _parseVietnameseWords(words);
  }

  static int? _parseVietnameseWords(List<String> words) {
    // Trường hợp 1 từ: ví dụ "năm" -> 5, "mười" -> 10, "không" -> 0
    if (words.length == 1) {
      final w = words.first;
      if (w == 'mười' || w == 'chục') return 10;
      if (_unitWords.containsKey(w)) return _unitWords[w];
      return null;
    }

    // Trường hợp 2 từ:
    // "mười một" -> 11, "mười lăm" -> 15
    // "hai mươi" -> 20, "hai mốt" -> 21, "ba lăm" -> 35
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
    }

    // Trường hợp 3 từ: ví dụ "hai mươi mốt" -> 21, "năm mươi lăm" -> 55
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

    // Quét tìm từ số đầu tiên nếu là chuỗi dài hơn, loại trừ từ 'không' nếu nằm trong ngữ cảnh câu hỗn hợp
    for (final w in words) {
      if (w != 'không' && _unitWords.containsKey(w)) {
        return _unitWords[w];
      }
    }

    return null;
  }
}
