import '../../../chat_online/services/translation_service.dart';

/// Dữ liệu đã giải mã của một tin nhắn Song ngữ (Bilingual Send).
class BilingualMessageData {
  final String primaryText;
  final String secondaryText;

  const BilingualMessageData({
    required this.primaryText,
    required this.secondaryText,
  });
}

/// Dữ liệu đã giải mã của một tin nhắn Sửa lỗi câu trực tiếp (Inline Correction).
class InlineCorrectionData {
  final String originalText;
  final String correctedText;
  final String note;

  const InlineCorrectionData({
    required this.originalText,
    required this.correctedText,
    this.note = '',
  });

  bool get hasNote => note.trim().isNotEmpty;
}

/// Helper xử lý tách từ đơn (Word Chips), mã hóa & giải mã tin nhắn Song ngữ
/// và tin nhắn Sửa lỗi câu (Inline Correction) tương thích 100% với bảng `messages`.
class ChatTranslateHelper {
  ChatTranslateHelper._();

  static const String _bilingualPrefix = '[[BT_BILINGUAL]]';
  static const String _bilingualSubSeparator = '\n[[BT_SUB]]\n';

  static const String _correctionPrefix = '[[BT_CORRECTION]]';
  static const String _origMarker = '\n[[ORIG]]';
  static const String _fixMarker = '\n[[FIX]]';
  static const String _noteMarker = '\n[[NOTE]]';

  /// Đóng gói tin nhắn Song ngữ để gửi qua bảng `messages`
  static String encodeBilingual({
    required String primaryText,
    required String secondaryText,
  }) {
    final primary = primaryText.trim();
    final secondary = secondaryText.trim();
    if (secondary.isEmpty || secondary == primary) return primary;
    return '$_bilingualPrefix\n$primary$_bilingualSubSeparator$secondary';
  }

  /// Giải mã tin nhắn Song ngữ (trả về `null` nếu là tin nhắn thường)
  static BilingualMessageData? parseBilingual(String rawContent) {
    if (!rawContent.startsWith(_bilingualPrefix)) return null;
    final body = rawContent.substring(_bilingualPrefix.length).trimLeft();
    final sepIndex = body.indexOf(_bilingualSubSeparator);
    if (sepIndex < 0) return null;

    final primary = body.substring(0, sepIndex).trim();
    final secondary =
        body.substring(sepIndex + _bilingualSubSeparator.length).trim();
    if (primary.isEmpty || secondary.isEmpty) return null;

    return BilingualMessageData(
      primaryText: primary,
      secondaryText: secondary,
    );
  }

  /// Đóng gói tin nhắn Sửa lỗi câu trực tiếp (Inline Correction)
  static String encodeCorrection({
    required String originalText,
    required String correctedText,
    String note = '',
  }) {
    return '$_correctionPrefix'
        '$_origMarker${originalText.trim()}'
        '$_fixMarker${correctedText.trim()}'
        '$_noteMarker${note.trim()}';
  }

  /// Giải mã tin nhắn Sửa lỗi câu (trả về `null` nếu không phải tin nhắn sửa lỗi)
  static InlineCorrectionData? parseCorrection(String rawContent) {
    if (!rawContent.startsWith(_correctionPrefix)) return null;
    final origIdx = rawContent.indexOf(_origMarker);
    final fixIdx = rawContent.indexOf(_fixMarker);
    if (origIdx < 0 || fixIdx <= origIdx) return null;

    final noteIdx = rawContent.indexOf(_noteMarker, fixIdx);
    final original =
        rawContent.substring(origIdx + _origMarker.length, fixIdx).trim();

    final corrected = noteIdx >= 0
        ? rawContent.substring(fixIdx + _fixMarker.length, noteIdx).trim()
        : rawContent.substring(fixIdx + _fixMarker.length).trim();

    final note = noteIdx >= 0
        ? rawContent.substring(noteIdx + _noteMarker.length).trim()
        : '';

    if (original.isEmpty || corrected.isEmpty) return null;

    return InlineCorrectionData(
      originalText: original,
      correctedText: corrected,
      note: note,
    );
  }

  /// Trích xuất văn bản thuần để dịch hoặc tách từ (bỏ qua marker định dạng nếu có)
  static String plainTextForTranslation(String rawContent) {
    final bilingual = parseBilingual(rawContent);
    if (bilingual != null) return bilingual.primaryText;

    final correction = parseCorrection(rawContent);
    if (correction != null) return correction.correctedText;

    return rawContent.trim();
  }

  /// Tách câu chat thành danh sách từ đơn sạch (loại bỏ dấu câu & trùng lặp, giữ đúng thứ tự).
  /// Hỗ trợ cả câu Tiếng Anh/Latin và câu Tiếng Trung (tách từng Hán tự).
  static List<String> extractWords(String rawText) {
    final text = plainTextForTranslation(rawText);
    if (text.isEmpty) return const [];

    final seen = <String>{};
    final result = <String>[];

    if (TranslationService.containsChineseCharacters(text)) {
      final hanziMatches = RegExp(r'[\u4E00-\u9FFF]').allMatches(text);
      for (final match in hanziMatches) {
        final char = match.group(0) ?? '';
        if (char.isNotEmpty && seen.add(char)) {
          result.add(char);
        }
      }
      final latinMatches = RegExp(r"[A-Za-z]+(?:['’-][A-Za-z]+)*").allMatches(text);
      for (final match in latinMatches) {
        final token = match.group(0) ?? '';
        if (token.length >= 2 && seen.add(token.toLowerCase())) {
          result.add(token);
        }
      }
      return result;
    }

    final wordMatches =
        RegExp(r"[A-Za-zÀ-ỹ]+(?:['’-][A-Za-zÀ-ỹ]+)*").allMatches(text);
    for (final match in wordMatches) {
      final word = match.group(0) ?? '';
      if (word.length < 2) continue;
      if (seen.add(word.toLowerCase())) {
        result.add(word);
      }
    }
    return result;
  }
}
