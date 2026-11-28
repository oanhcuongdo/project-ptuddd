import 'dart:convert';

import 'ai_client.dart';

/// Bản tóm tắt chạy **ngay trên máy**, chỉ dùng khi chạy
/// `--dart-define=AI_SUMMARY_ENDPOINT=mock`.
///
/// Mục đích là xem trước giao diện và kiểm thử luồng chờ/lỗi khi nhóm chưa có
/// máy chủ proxy + API key. Thuật toán chỉ trích các câu đầu và gạch đầu dòng,
/// **không phải AI**, nên kết quả không dùng cho bản phát hành.
class DemoAiTransport implements AiTransport {
  const DemoAiTransport();

  @override
  Future<AiHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    final payload = jsonDecode(body);
    final text = payload is Map<String, dynamic>
        ? (payload['text'] as String? ?? '')
        : '';
    final mode = payload is Map<String, dynamic>
        ? (payload['mode'] as String? ?? 'short')
        : 'short';
    return AiHttpResponse(
      statusCode: 200,
      body: jsonEncode(<String, Object?>{
        'summary': _summarize(text, mode),
        'model': 'demo-extractive',
      }),
    );
  }

  @override
  void close() {}

  String _summarize(String text, String mode) {
    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((String sentence) => sentence.trim())
        .where((String sentence) => sentence.isNotEmpty)
        .toList();
    if (sentences.isEmpty) {
      return '';
    }
    switch (mode) {
      case 'long':
        return _joinSentences(sentences, maxSentences: 6, maxChars: 700);
      case 'bullets':
        final bullets = sentences
            .take(5)
            .map((String sentence) => '• ${_clip(sentence, 90)}')
            .join('\n');
        return bullets;
      default:
        return _joinSentences(sentences, maxSentences: 2, maxChars: 220);
    }
  }

  String _joinSentences(
    List<String> sentences, {
    required int maxSentences,
    required int maxChars,
  }) {
    final buffer = StringBuffer();
    for (final sentence in sentences.take(maxSentences)) {
      final next = buffer.isEmpty ? sentence : ' $sentence';
      if (buffer.length + next.length > maxChars) {
        break;
      }
      buffer.write(next);
    }
    if (buffer.isEmpty) {
      return _clip(sentences.first, maxChars);
    }
    return buffer.toString();
  }

  String _clip(String value, int maxChars) {
    if (value.length <= maxChars) {
      return value;
    }
    return '${value.substring(0, maxChars - 1).trimRight()}…';
  }
}
