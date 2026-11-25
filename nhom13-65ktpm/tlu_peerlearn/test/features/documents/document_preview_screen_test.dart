import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/models/document_item.dart';
import 'package:tlu_peerlearn/features/documents/screens/document_preview_screen.dart';

void main() {
  testWidgets('DocumentPreviewScreen displays details and actions', (tester) async {
    final doc = DocumentItem(
      id: 'doc-1',
      roomId: 'room-1',
      fileName: 'Kien_truc_phan_mem.pdf',
      fileUrl: 'https://example.com/kien_truc.pdf',
      fileType: 'pdf',
      fileSize: 1024 * 1024 * 2,
      topic: 'Design Patterns',
      uploadedBy: 'user-1',
      uploadedAt: DateTime.now(),
    );

    var aiClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: DocumentPreviewScreen(
          document: doc,
          extractedText: 'Nội dung trích xuất bài học mẫu.',
          onGenerateAi: () => aiClicked = true,
        ),
      ),
    );

    expect(find.text('Kien_truc_phan_mem.pdf'), findsOneWidget);
    expect(find.text('Chủ đề: Design Patterns'), findsOneWidget);
    expect(find.text('Nội dung trích xuất bài học mẫu.'), findsOneWidget);
    expect(find.text('Tạo đề AI'), findsOneWidget);

    await tester.tap(find.text('Tạo đề AI'));
    expect(aiClicked, isTrue);
  });
}
