import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/models/document_item.dart';
import 'package:tlu_peerlearn/features/documents/screens/room_documents_tab.dart';
import 'package:tlu_peerlearn/features/documents/services/document_service.dart';

void main() {
  testWidgets('RoomDocumentsTab renders empty state and search bar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomDocumentsProvider('room-123').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: RoomDocumentsTab(roomId: 'room-123'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Chưa có tài liệu nào trong phòng học'), findsOneWidget);
    expect(find.text('Tải lên'), findsOneWidget);
  });

  testWidgets('RoomDocumentsTab renders document list when data available', (tester) async {
    final mockDocs = [
      DocumentItem(
        id: 'doc-1',
        roomId: 'room-123',
        fileName: 'Giao_trinh_Dart.pdf',
        fileUrl: 'https://example.com/dart.pdf',
        fileType: 'pdf',
        fileSize: 1024 * 500,
        topic: 'Dart Cơ bản',
        uploadedBy: 'u1',
        uploadedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomDocumentsProvider('room-123').overrideWith((ref) async => mockDocs),
        ],
        child: const MaterialApp(
          home: RoomDocumentsTab(roomId: 'room-123'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Giao_trinh_Dart.pdf'), findsOneWidget);
    expect(find.text('Dart Cơ bản'), findsOneWidget);
  });
}
