import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/generated_set.dart';
import 'package:tlu_peerlearn/features/ai_generator/widgets/generated_sets_list_widget.dart';

void main() {
  testWidgets('GeneratedSetsListWidget filters sets correctly', (tester) async {
    final sets = [
      GeneratedSet(
        id: '1',
        roomId: 'r1',
        createdBy: 'u1',
        title: 'Quiz 1: Dart Basics',
        contentType: 'quiz',
        difficulty: 'basic',
        status: 'published',
        createdAt: DateTime.now(),
      ),
      GeneratedSet(
        id: '2',
        roomId: 'r1',
        createdBy: 'u1',
        title: 'Flashcard 2: Flutter Widgets',
        contentType: 'flashcard',
        difficulty: 'medium',
        status: 'draft',
        createdAt: DateTime.now(),
      ),
    ];

    GeneratedSet? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GeneratedSetsListWidget(
              sets: sets,
              onSelectSet: (s) => selected = s,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Quiz 1: Dart Basics'), findsOneWidget);
    expect(find.text('Flashcard 2: Flutter Widgets'), findsOneWidget);

    // Tap on Quiz 1
    await tester.tap(find.text('Quiz 1: Dart Basics'));
    expect(selected?.id, '1');

    // Filter by flashcard
    await tester.tap(find.text('Flashcard'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz 1: Dart Basics'), findsNothing);
    expect(find.text('Flashcard 2: Flutter Widgets'), findsOneWidget);
  });
}
