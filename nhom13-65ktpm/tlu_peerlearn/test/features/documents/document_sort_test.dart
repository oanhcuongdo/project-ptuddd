import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/models/document_item.dart';
import 'package:tlu_peerlearn/features/documents/models/document_sort_option.dart';

void main() {
  group('DocumentSortOption Tests', () {
    final docA = DocumentItem(
      id: '1',
      roomId: 'r',
      fileName: 'Alpha.pdf',
      fileUrl: '',
      fileType: 'pdf',
      fileSize: 100,
      uploadedBy: 'u',
      uploadedAt: DateTime(2026, 1, 1),
    );
    final docZ = DocumentItem(
      id: '2',
      roomId: 'r',
      fileName: 'Zulu.docx',
      fileUrl: '',
      fileType: 'docx',
      fileSize: 500,
      uploadedBy: 'u',
      uploadedAt: DateTime(2026, 2, 1),
    );

    test('sorts by name ascending and descending', () {
      final list = [docZ, docA];
      final asc = DocumentSortOption.nameAsc.sort(list);
      expect(asc.first.fileName, 'Alpha.pdf');

      final desc = DocumentSortOption.nameDesc.sort(list);
      expect(desc.first.fileName, 'Zulu.docx');
    });

    test('sorts by size descending', () {
      final list = [docA, docZ];
      final sorted = DocumentSortOption.sizeDesc.sort(list);
      expect(sorted.first.fileName, 'Zulu.docx');
    });

    test('sorts by newest date', () {
      final list = [docA, docZ];
      final sorted = DocumentSortOption.newest.sort(list);
      expect(sorted.first.fileName, 'Zulu.docx');
    });
  });
}
