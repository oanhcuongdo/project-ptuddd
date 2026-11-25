import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/utils/docx_xml_parser.dart';

void main() {
  group('DocxXmlParser Tests', () {
    test('extracts text from paragraphs and word text tags', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r><w:t>Chương 1: </w:t></w:r>
      <w:r><w:t>Giới thiệu về Flutter và Dart.</w:t></w:r>
    </w:p>
    <w:p>
      <w:r><w:t>Flutter là một UI toolkit của Google &amp; cộng đồng.</w:t></w:r>
    </w:p>
  </w:body>
</w:document>
''';

      final result = DocxXmlParser.extractTextFromXml(xml);
      expect(result, contains('Chương 1: Giới thiệu về Flutter và Dart.'));
      expect(result, contains('Flutter là một UI toolkit của Google & cộng đồng.'));
    });

    test('handles empty xml gracefully', () {
      expect(DocxXmlParser.extractTextFromXml(''), '');
    });
  });
}
