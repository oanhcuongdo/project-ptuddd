import 'dart:convert';
import 'dart:typed_data';

class TextExtractor {
  static const int maxCharacters = 15000; // BR-04

  /// Truncates raw text to maximum allowable characters (15,000 chars)
  static String truncateToLimit(String text, {int limit = maxCharacters}) {
    if (text.length <= limit) {
      return text;
    }
    return text.substring(0, limit);
  }

  /// Sanitizes text by removing excessive consecutive whitespaces/newlines
  static String cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\r\n|\r'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
  }

  /// Extracts text from utf8 byte buffer with limit enforcement
  static String extractFromBytes(Uint8List bytes, {int limit = maxCharacters}) {
    try {
      final decoded = utf8.decode(bytes, allowMalformed: true);
      final cleaned = cleanText(decoded);
      return truncateToLimit(cleaned, limit: limit);
    } catch (_) {
      return '';
    }
  }

  /// Validates extracted text is sufficient for AI generation (at least 50 characters)
  static bool hasSufficientContent(String text, {int minLength = 50}) {
    return text.trim().length >= minLength;
  }
}
