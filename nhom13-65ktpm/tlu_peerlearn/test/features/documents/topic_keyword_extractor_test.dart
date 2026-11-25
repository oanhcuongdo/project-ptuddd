import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/utils/topic_keyword_extractor.dart';

void main() {
  group('TopicKeywordExtractor Tests', () {
    test('extracts top keywords and ignores stop words', () {
      const text = '''
Flutter là một framework tuyệt vời. Flutter giúp xây dựng ứng dụng di động nhanh chóng.
Dart là ngôn ngữ lập trình của Flutter. Dart rất linh hoạt và mạnh mẽ.
Flutter hỗ trợ cả Android và iOS.
''';

      final keywords = TopicKeywordExtractor.extractKeywords(text, topN: 3);
      expect(keywords, contains('Flutter'));
      expect(keywords, contains('Dart'));
      expect(keywords.length, lessThanOrEqualTo(3));
    });

    test('handles empty text', () {
      expect(TopicKeywordExtractor.extractKeywords(''), isEmpty);
    });
  });
}
