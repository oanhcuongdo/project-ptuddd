import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/services/document_service.dart';

void main() {
  group('DocumentService Tests', () {
    test('DocumentService with null client returns empty list safely', () async {
      final service = DocumentService(null);
      final list = await service.fetchDocuments('test-room');
      expect(list, isEmpty);
    });

    test('uploadDocument throws ArgumentError on invalid file', () async {
      final service = DocumentService(null);
      expect(
        () => service.uploadDocument(
          roomId: 'room-1',
          fileName: 'invalid.exe',
          bytes: Uint8List.fromList([1, 2, 3]),
          uploadedBy: 'user-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('uploadDocument throws ArgumentError when file exceeds 5MB', () async {
      final service = DocumentService(null);
      final oversizedBytes = Uint8List(5 * 1024 * 1024 + 10);
      expect(
        () => service.uploadDocument(
          roomId: 'room-1',
          fileName: 'big.pdf',
          bytes: oversizedBytes,
          uploadedBy: 'user-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
