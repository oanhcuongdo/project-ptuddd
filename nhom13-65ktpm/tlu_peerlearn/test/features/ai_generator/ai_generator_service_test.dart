import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/flashcard_item.dart';
import 'package:tlu_peerlearn/features/ai_generator/services/ai_generator_service.dart';

void main() {
  group('AiGeneratorService Tests', () {
    test('saveDraftSet enforces at least 1 document', () async {
      final service = AiGeneratorService(null);
      expect(
        () => service.saveDraftSet(
          roomId: 'r1',
          createdBy: 'u1',
          title: 'Test',
          contentType: 'flashcard',
          difficulty: 'basic',
          documentIds: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('saveDraftSet enforces at most 2 documents (BR-04)', () async {
      final service = AiGeneratorService(null);
      expect(
        () => service.saveDraftSet(
          roomId: 'r1',
          createdBy: 'u1',
          title: 'Test',
          contentType: 'flashcard',
          difficulty: 'basic',
          documentIds: ['doc1', 'doc2', 'doc3'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('saveDraftSet returns draft object with valid params', () async {
      final service = AiGeneratorService(null);
      final set = await service.saveDraftSet(
        roomId: 'r1',
        createdBy: 'u1',
        title: 'Bộ thẻ Dart',
        contentType: 'flashcard',
        difficulty: 'medium',
        documentIds: ['doc1'],
        flashcards: [
          FlashcardItem(id: '1', setId: '', frontText: 'A', backText: 'B'),
        ],
      );

      expect(set.isDraft, isTrue);
      expect(set.title, 'Bộ thẻ Dart');
    });

    test('generateContent falls back safely to local generator when client is null', () async {
      final service = AiGeneratorService(null);
      final result = await service.generateContent(
        roomId: 'r1',
        createdBy: 'u1',
        title: 'Đề ôn tập',
        contentType: 'quiz',
        count: 5,
        difficulty: 'basic',
        documentIds: ['doc1'],
        documentContext: 'Dart và Flutter là nền tảng di động',
      );

      expect(result.set.isDraft, isTrue);
      expect(result.questions?.length, 5);
      expect(result.questions?.first.options.length, 4);
    });
  });
}
