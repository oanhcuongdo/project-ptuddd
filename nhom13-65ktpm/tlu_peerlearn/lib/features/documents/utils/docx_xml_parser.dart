class DocxXmlParser {
  /// Extracts clean text from word/document.xml content
  static String extractTextFromXml(String xmlContent) {
    if (xmlContent.isEmpty) return '';

    final paragraphRegex = RegExp(r'<w:p[\s>](.*?)</w:p>', dotAll: true);
    final textRegex = RegExp(r'<w:t[\s>](.*?)</w:t>', dotAll: true);

    final paragraphs = <String>[];
    final pMatches = paragraphRegex.allMatches(xmlContent);

    if (pMatches.isEmpty) {
      // Fallback: extract any <w:t> tags
      final tMatches = textRegex.allMatches(xmlContent);
      return tMatches.map((m) => _cleanEntityText(m.group(1) ?? '')).join(' ').trim();
    }

    for (final pMatch in pMatches) {
      final pBody = pMatch.group(1) ?? '';
      final tMatches = textRegex.allMatches(pBody);
      final pText = tMatches
          .map((m) => _cleanEntityText(m.group(1) ?? ''))
          .where((t) => t.isNotEmpty)
          .join('');

      if (pText.trim().isNotEmpty) {
        paragraphs.add(pText.trim());
      }
    }

    return paragraphs.join('\n');
  }

  static String _cleanEntityText(String raw) {
    return raw
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
}
