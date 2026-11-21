import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/models/document_item.dart';

void main() {
  group('DocumentItem Model Tests', () {
    test('fromJson and toJson should serialize correctly', () {
      final json = {
        'id': 'doc-123',
        'room_id': 'room-456',
        'file_name': 'lap-trinh-di-dong.pdf',
        'file_url': 'https://example.com/doc.pdf',
        'file_type': 'pdf',
        'file_size': 2048576,
        'topic': 'Flutter Cơ bản',
        'uploaded_by': 'user-789',
        'uploaded_at': '2026-11-20T10:00:00.000Z',
      };

      final doc = DocumentItem.fromJson(json);

      expect(doc.id, 'doc-123');
      expect(doc.roomId, 'room-456');
      expect(doc.fileName, 'lap-trinh-di-dong.pdf');
      expect(doc.fileType, 'pdf');
      expect(doc.isPdf, isTrue);
      expect(doc.isDocx, isFalse);
      expect(doc.formattedFileSize, '1.95 MB');

      final serialized = doc.toJson();
      expect(serialized['id'], 'doc-123');
      expect(serialized['topic'], 'Flutter Cơ bản');
    });

    test('formattedFileSize handles bytes and KB', () {
      final docBytes = DocumentItem(
        id: '1',
        roomId: 'r',
        fileName: 'a.txt',
        fileUrl: '',
        fileType: 'pdf',
        fileSize: 500,
        uploadedBy: 'u',
        uploadedAt: DateTime.now(),
      );
      expect(docBytes.formattedFileSize, '500 B');

      final docKb = DocumentItem(
        id: '2',
        roomId: 'r',
        fileName: 'b.docx',
        fileUrl: '',
        fileType: 'docx',
        fileSize: 15360,
        uploadedBy: 'u',
        uploadedAt: DateTime.now(),
      );
      expect(docKb.formattedFileSize, '15.0 KB');
      expect(docKb.isDocx, isTrue);
    });
  });
}
