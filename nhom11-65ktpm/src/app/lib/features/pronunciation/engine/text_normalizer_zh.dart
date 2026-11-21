class TextNormalizerZh {
  static const Map<String, String> _numberToHanzi = {
    '0': '零',
    '1': '一',
    '2': '二',
    '3': '三',
    '4': '四',
    '5': '五',
    '6': '六',
    '7': '七',
    '8': '八',
    '9': '九',
    '10': '十',
  };

  static String normalize(String input) {
    if (input.isEmpty) return '';

    String text = input.trim();

    _numberToHanzi.forEach((digit, hanzi) {
      text = text.replaceAll(digit, hanzi);
    });

    final punctuationRegex = RegExp(r'[，。！？、；：“”‘’（）《》〈〉【】…—\.,!?;:\(\)\[\]"\'\-]');
    text = text.replaceAll(punctuationRegex, '');

    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  static bool isChineseChar(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return code >= 0x4E00 && code <= 0x9FA5;
  }
}
