import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/flashcard_item.dart';
import 'package:tlu_peerlearn/features/ai_generator/widgets/flashcard_edit_dialog.dart';

void main() {
  testWidgets('FlashcardEditDialog edits front and back text', (tester) async {
    final original = FlashcardItem(
      id: 'c1',
      setId: 's1',
      frontText: 'Ban đầu',
      backText: 'Định nghĩa ban đầu',
    );

    FlashcardItem? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlashcardEditDialog(
            flashcard: original,
            onSave: (card) => saved = card,
          ),
        ),
      ),
    );

    expect(find.text('Chỉnh sửa thẻ ghi nhớ (Flashcard)'), findsOneWidget);
    expect(find.text('Ban đầu'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Thuật ngữ đã sửa');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(saved?.frontText, 'Thuật ngữ đã sửa');
  });
}
