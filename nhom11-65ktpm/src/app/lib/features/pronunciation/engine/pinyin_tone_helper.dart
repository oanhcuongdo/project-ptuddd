class PinyinToneHelper {
  static const Map<String, List<String>> _toneVowels = {
    'a': ['ā', 'á', 'ǎ', 'à', 'a'],
    'e': ['ē', 'é', 'ě', 'è', 'e'],
    'i': ['ī', 'í', 'ǐ', 'ì', 'i'],
    'o': ['ō', 'ó', 'ǒ', 'ò', 'o'],
    'u': ['ū', 'ú', 'ǔ', 'ù', 'u'],
    'v': ['ǖ', 'ǘ', 'ǚ', 'ǜ', 'ü'],
    'ü': ['ǖ', 'ǘ', 'ǚ', 'ǜ', 'ü'],
  };

  static String numberToneToMark(String pinyinNum) {
    final trimmed = pinyinNum.trim().toLowerCase();
    if (trimmed.isEmpty) return '';

    final toneMatch = RegExp(r'([a-zvü]+)([1-5])').firstMatch(trimmed);
    if (toneMatch == null) return trimmed;

    final base = toneMatch.group(1)!;
    final tone = int.parse(toneMatch.group(2)!);
    if (tone == 5) {
      return base.replaceAll('v', 'ü');
    }

    final toneIndex = tone - 1;

    String vowelToMark = '';
    if (base.contains('a')) {
      vowelToMark = 'a';
    } else if (base.contains('o')) {
      vowelToMark = 'o';
    } else if (base.contains('e')) {
      vowelToMark = 'e';
    } else if (base.contains('ui')) {
      vowelToMark = 'i';
    } else if (base.contains('iu')) {
      vowelToMark = 'u';
    } else {
      for (int i = base.length - 1; i >= 0; i--) {
        final char = base[i];
        if (_toneVowels.containsKey(char)) {
          vowelToMark = char;
          break;
        }
      }
    }

    if (vowelToMark.isEmpty) {
      return base.replaceAll('v', 'ü');
    }

    final markedVowel = _toneVowels[vowelToMark]![toneIndex];
    return base.replaceFirst(vowelToMark, markedVowel).replaceAll('v', 'ü');
  }

  static int extractToneNumber(String pinyin) {
    final trimmed = pinyin.trim();
    if (RegExp(r'[1-5]$').hasMatch(trimmed)) {
      return int.parse(trimmed.substring(trimmed.length - 1));
    }

    for (final vowelList in _toneVowels.values) {
      for (int i = 0; i < 4; i++) {
        if (trimmed.contains(vowelList[i])) {
          return i + 1;
        }
      }
    }
    return 5;
  }

  static String removeTone(String pinyin) {
    String res = pinyin;
    for (final entry in _toneVowels.entries) {
      final base = entry.key == 'v' ? 'ü' : entry.key;
      for (int i = 0; i < 4; i++) {
        res = res.replaceAll(entry.value[i], base);
      }
    }
    return res.replaceAll(RegExp(r'[1-5]'), '');
  }
}
