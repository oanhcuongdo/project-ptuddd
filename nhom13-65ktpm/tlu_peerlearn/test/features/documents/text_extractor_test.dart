import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/utils/text_extractor.dart';

void main() {
  group('TextExtractor Tests (BR-04)', () {
    test('truncateToLimit keeps text under 15000 characters', () {
      final shortText = 'Đây là nội dung ngắn.';
      expect(TextExtractor.truncateToLimit(shortText), shortText);

      final longText = 'A' * 20000;
      final truncated = TextExtractor.truncateToLimit(longText);
      expect(truncated.length, 15000);
      expect(truncated, 'A' * 15000);
    });

    test('cleanText removes excessive whitespace and normalizes newlines', () {
      final dirtyText = 'Xin chào   các bạn!\r\n\r\n\r\n\r\nĐây  là bài học.';
      final cleaned = TextExtractor.cleanText(dirtyText);
      expect(cleaned, 'Xin chào các bạn!\n\nĐây là bài học.');
    });

    test('extractFromBytes decodes utf8 and truncates', () {
      final bytes = Uint8List.fromList(utf8.encode('Nội dung tài liệu học tập'));
      final extracted = TextExtractor.extractFromBytes(bytes);
      expect(extracted, 'Nội dung tài liệu học tập');
    });

    test('hasSufficientContent checks minimum length threshold', () {
      expect(TextExtractor.hasSufficientContent('ngắn'), isFalse);
      expect(
        TextExtractor.hasSufficientContent(
          'Đây là đoạn văn bản mẫu có độ dài đủ lớn hơn 50 ký tự để làm đầu vào cho mô hình AI xử lý.',
        ),
        isTrue,
      );
    });
  });
}
