class TopicKeywordExtractor {
  static const _stopWords = {
    'và', 'là', 'của', 'có', 'trong', 'được', 'các', 'cho', 'với',
    'một', 'những', 'này', 'đó', 'từ', 'khi', 'thì', 'ở', 'đến', 'để',
    'sẽ', 'không', 'như', 'về', 'người', 'ra', 'vào', 'lại', 'qua',
    'theo', 'nên', 'do', 'cũng', 'bởi', 'bị', 'rằng', 'the', 'and', 'is', 'in', 'to', 'of'
  };

  /// Extracts the most frequent relevant keywords to suggest topics
  static List<String> extractKeywords(String text, {int topN = 5}) {
    if (text.trim().isEmpty) return [];

    final clean = text.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9\sàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]'), ' ');
    final tokens = clean.split(RegExp(r'\s+')).where((w) => w.length > 2 && !_stopWords.contains(w));

    final freq = <String, int>{};
    for (final token in tokens) {
      freq[token] = (freq[token] ?? 0) + 1;
    }

    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(topN).map((e) => _capitalize(e.key)).toList();
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
