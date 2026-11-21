import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/models/document_item.dart';
import 'package:tlu_peerlearn/features/documents/widgets/document_quota_card.dart';

void main() {
  testWidgets('DocumentQuotaCard calculates total files and size correctly', (tester) async {
    final docs = [
      DocumentItem(
        id: '1',
        roomId: 'r',
        fileName: 'a.pdf',
        fileUrl: '',
        fileType: 'pdf',
        fileSize: 1024 * 1024,
        uploadedBy: 'u',
        uploadedAt: DateTime.now(),
      ),
      DocumentItem(
        id: '2',
        roomId: 'r',
        fileName: 'b.docx',
        fileUrl: '',
        fileType: 'docx',
        fileSize: 1024 * 512,
        uploadedBy: 'u',
        uploadedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocumentQuotaCard(documents: docs),
        ),
      ),
    );

    expect(find.text('Kho học liệu phòng (2 tệp)'), findsOneWidget);
    expect(find.text('Đã lưu: 1.50 MB • 1 PDF • 1 DOCX'), findsOneWidget);
  });
}
