import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/utils/document_validator.dart';

void main() {
  group('DocumentValidator Tests (BR-04)', () {
    test('validateFileType accepts .pdf and .docx (case-insensitive)', () {
      expect(DocumentValidator.validateFileType('lecture.pdf'), isNull);
      expect(DocumentValidator.validateFileType('slide.PDF'), isNull);
      expect(DocumentValidator.validateFileType('assignment.docx'), isNull);
      expect(DocumentValidator.validateFileType('NOTES.DOCX'), isNull);
    });

    test('validateFileType rejects disallowed file types and empty names', () {
      expect(DocumentValidator.validateFileType(''), 'Tên tệp không được để trống');
      expect(
        DocumentValidator.validateFileType('program.exe'),
        'Chỉ chấp nhận tệp định dạng .pdf hoặc .docx',
      );
      expect(
        DocumentValidator.validateFileType('archive.zip'),
        'Chỉ chấp nhận tệp định dạng .pdf hoặc .docx',
      );
    });

    test('validateFileSize validates within 5MB boundary', () {
      // 0 bytes
      expect(DocumentValidator.validateFileSize(0), 'Tệp tin không có nội dung (0 bytes)');

      // Valid: 4.9MB
      expect(DocumentValidator.validateFileSize(4900000), isNull);

      // Exactly 5MB (5242880 bytes)
      expect(DocumentValidator.validateFileSize(5242880), isNull);

      // Exceeded: 5MB + 1 byte
      expect(
        DocumentValidator.validateFileSize(5242881),
        'Dung lượng tệp vượt quá giới hạn tối đa 5MB',
      );
    });

    test('validateUpload runs combined checks correctly', () {
      expect(
        DocumentValidator.validateUpload(
          fileName: 'bai-giang.pdf',
          sizeInBytes: 1024 * 1024,
        ),
        isNull,
      );

      expect(
        DocumentValidator.validateUpload(
          fileName: 'virus.bat',
          sizeInBytes: 100,
        ),
        'Chỉ chấp nhận tệp định dạng .pdf hoặc .docx',
      );
    });
  });
}
