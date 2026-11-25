import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/generated_set.dart';
import 'package:tlu_peerlearn/features/ai_generator/screens/room_learning_content_screen.dart';

void main() {
  testWidgets('RoomLearningContentScreen renders empty state and generate button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomGeneratedSetsProvider('room-1').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: RoomLearningContentScreen(roomId: 'room-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kho nội dung ôn tập AI'), findsOneWidget);
    expect(find.text('Chưa có bộ đề nào được tạo trong phòng'), findsOneWidget);
    expect(find.text('Tạo bằng AI'), findsOneWidget);
  });

  testWidgets('RoomLearningContentScreen displays sets list when available', (tester) async {
    final sets = [
      GeneratedSet(
        id: 's1',
        roomId: 'room-1',
        createdBy: 'u1',
        title: 'Bộ trắc nghiệm Kiến trúc',
        contentType: 'quiz',
        difficulty: 'medium',
        status: 'published',
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomGeneratedSetsProvider('room-1').overrideWith((ref) async => sets),
        ],
        child: const MaterialApp(
          home: RoomLearningContentScreen(roomId: 'room-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bộ trắc nghiệm Kiến trúc'), findsOneWidget);
  });
}
