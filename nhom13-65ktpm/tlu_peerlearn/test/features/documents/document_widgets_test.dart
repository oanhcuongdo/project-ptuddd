import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/models/document_item.dart';
import 'package:tlu_peerlearn/features/documents/widgets/document_card.dart';
import 'package:tlu_peerlearn/features/documents/widgets/document_upload_dialog.dart';

void main() {
  group('Document Widgets Tests', () {
    testWidgets('DocumentCard displays document info and buttons', (tester) async {
      final doc = DocumentItem(
        id: 'doc-1',
        roomId: 'room-1',
        fileName: 'Kien_truc_phan_mem.pdf',
        fileUrl: 'https://example.com/kien-truc.pdf',
        fileType: 'pdf',
        fileSize: 1024 * 1024,
        topic: 'Design Patterns',
        uploadedBy: 'user-1',
        uploadedAt: DateTime(2026, 11, 20),
      );

      var downloaded = false;
      var deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCard(
              document: doc,
              showDelete: true,
              onDownload: () => downloaded = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      expect(find.text('Kien_truc_phan_mem.pdf'), findsOneWidget);
      expect(find.text('Design Patterns'), findsOneWidget);
      expect(find.text('1.00 MB'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.download_rounded));
      expect(downloaded, isTrue);

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleted, isTrue);
    });

    testWidgets('DocumentUploadDialog renders form fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentUploadDialog(
              onUpload: ({required fileName, required bytes, topic}) async {},
            ),
          ),
        ),
      );

      expect(find.text('Tải lên tài liệu mới'), findsOneWidget);
      expect(find.text('Chọn tệp từ thiết bị'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });
}
