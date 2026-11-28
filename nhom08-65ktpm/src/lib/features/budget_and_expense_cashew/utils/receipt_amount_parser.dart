/// Extracts a likely payable amount from OCR'd receipt text.
abstract final class ReceiptAmountParser {
  static final _amountPattern = RegExp(
    r'(?<!\d)\d{1,3}(?:[.,\s]\d{3})+(?!\d)|(?<!\d)\d{4,}(?!\d)',
  );
  static final _totalLabel = RegExp(
    r't[oổ]ng|th[aà]nh\s*ti[eề]n|c[oộ]ng\s*ti[eề]n|total|amount\s*due|grand\s*total',
    caseSensitive: false,
  );

  static int? extractAmount(String rawText) {
    final labeledAmounts = <int>[];
    final allAmounts = <int>[];
    for (final line in rawText.split(RegExp(r'[\r\n]+'))) {
      final matches = _amountPattern.allMatches(line);
      for (final match in matches) {
        final value = int.tryParse(
          match.group(0)!.replaceAll(RegExp(r'\D'), ''),
        );
        if (value == null || value <= 0) continue;
        allAmounts.add(value);
        if (_totalLabel.hasMatch(line)) labeledAmounts.add(value);
      }
    }
    final candidates = labeledAmounts.isNotEmpty ? labeledAmounts : allAmounts;
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.last;
  }
}
