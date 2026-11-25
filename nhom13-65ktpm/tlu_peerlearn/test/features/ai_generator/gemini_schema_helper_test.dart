import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/services/gemini_schema_helper.dart';

void main() {
  group('GeminiSchemaHelper Tests', () {
    test('validateItemCount enforces 5-20 bounds', () {
      expect(GeminiSchemaHelper.validateItemCount(4), isNotNull);
      expect(GeminiSchemaHelper.validateItemCount(5), isNull);
      expect(GeminiSchemaHelper.validateItemCount(15), isNull);
      expect(GeminiSchemaHelper.validateItemCount(20), isNull);
      expect(GeminiSchemaHelper.validateItemCount(21), isNotNull);
    });

    test('validateSelectedDocuments enforces 1-2 docs (BR-04)', () {
      expect(GeminiSchemaHelper.validateSelectedDocuments([]), isNotNull);
      expect(GeminiSchemaHelper.validateSelectedDocuments(['doc-1']), isNull);
      expect(GeminiSchemaHelper.validateSelectedDocuments(['doc-1', 'doc-2']), isNull);
      expect(GeminiSchemaHelper.validateSelectedDocuments(['doc-1', 'doc-2', 'doc-3']), isNotNull);
    });

    test('JSON schemas have valid object and array structure', () {
      final flashcardSchema = GeminiSchemaHelper.flashcardsJsonSchema;
      expect(flashcardSchema['type'], 'OBJECT');
      expect(flashcardSchema['required'], contains('items'));

      final quizSchema = GeminiSchemaHelper.quizJsonSchema;
      expect(quizSchema['type'], 'OBJECT');
      expect(quizSchema['required'], contains('questions'));
    });

    test('buildPrompt includes count, difficulty and documentContext', () {
      final prompt = GeminiSchemaHelper.buildPrompt(
        contentType: 'quiz',
        count: 10,
        difficulty: 'medium',
        topic: 'Flutter State',
        documentContext: 'Ngữ cảnh bài học về Riverpod',
      );

      expect(prompt, contains('10'));
      expect(prompt, contains('medium'));
      expect(prompt, contains('Flutter State'));
      expect(prompt, contains('Riverpod'));
    });
  });
}
