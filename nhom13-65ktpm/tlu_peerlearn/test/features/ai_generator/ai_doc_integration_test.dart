import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/flashcard_item.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/generated_set.dart';
import 'package:tlu_peerlearn/features/ai_generator/models/quiz_question_item.dart';
import 'package:tlu_peerlearn/features/ai_generator/services/gemini_schema_helper.dart';
import 'package:tlu_peerlearn/features/documents/models/document_item.dart';
import 'package:tlu_peerlearn/features/documents/utils/document_validator.dart';
import 'package:tlu_peerlearn/features/documents/utils/text_extractor.dart';

void main() {
  group('AI Document End-to-End Integration Flow', () {
    test('full workflow: validate -> extract -> prompt schema -> draft -> edit -> publish', () async {
      // 1. Validate documents per BR-04
      final pdfBytes = Uint8List.fromList(List.filled(1024 * 50, 65)); // 50KB PDF dummy
      final docxBytes = Uint8List.fromList(List.filled(1024 * 100, 66)); // 100KB DOCX dummy

      expect(DocumentValidator.validateUpload(fileName: 'giao_trinh.pdf', sizeInBytes: pdfBytes.length), isNull);
      expect(DocumentValidator.validateUpload(fileName: 'bai_tap.docx', sizeInBytes: docxBytes.length), isNull);
      expect(DocumentValidator.validateUpload(fileName: 'virus.exe', sizeInBytes: 1000), isNotNull);
      expect(DocumentValidator.validateUpload(fileName: 'huge.pdf', sizeInBytes: 6 * 1024 * 1024), isNotNull);

      final doc1 = DocumentItem(
        id: 'doc-001',
        roomId: 'room-tlu',
        fileName: 'giao_trinh.pdf',
        fileUrl: 'https://storage.supabase.co/docs/giao_trinh.pdf',
        fileType: 'pdf',
        fileSize: pdfBytes.length,
        topic: 'Dart Flutter',
        uploadedBy: 'user-001',
        uploadedAt: DateTime.now(),
      );

      final doc2 = DocumentItem(
        id: 'doc-002',
        roomId: 'room-tlu',
        fileName: 'bai_tap.docx',
        fileUrl: 'https://storage.supabase.co/docs/bai_tap.docx',
        fileType: 'docx',
        fileSize: docxBytes.length,
        topic: 'Widget Testing',
        uploadedBy: 'user-001',
        uploadedAt: DateTime.now(),
      );

      // 2. Document selection limit for AI generation (max 2 documents BR-04)
      final selectedDocs = [doc1.id, doc2.id];
      expect(GeminiSchemaHelper.validateSelectedDocuments(selectedDocs), isNull);

      final tooManyDocs = [doc1.id, doc2.id, 'doc-003'];
      expect(GeminiSchemaHelper.validateSelectedDocuments(tooManyDocs), isNotNull);

      // 3. Text extraction & length truncation (max 15,000 chars BR-04)
      final longText = 'Dart and Flutter Peer Learning Architecture. ' * 500;
      final extracted = TextExtractor.truncateToLimit(longText);
      expect(extracted.length, lessThanOrEqualTo(15000));

      // 4. Gemini Prompt & Schema validation
      final prompt = GeminiSchemaHelper.buildPrompt(
        contentType: 'quiz',
        count: 5,
        difficulty: 'medium',
        topic: 'Dart Async Programming',
        documentContext: extracted,
      );
      expect(prompt, contains('câu hỏi trắc nghiệm'));
      expect(prompt, contains('medium'));

      final schema = GeminiSchemaHelper.quizJsonSchema;
      expect(schema['type'], 'OBJECT');
      expect(schema['properties'], contains('questions'));

      // 5. Simulate AI generation creating a Draft GeneratedSet (BR-06)
      var generatedSet = GeneratedSet(
        id: 'set-draft-1',
        roomId: 'room-tlu',
        createdBy: 'user-001',
        title: 'Bộ trắc nghiệm Dart Async',
        contentType: 'quiz',
        difficulty: 'medium',
        status: 'draft',
        createdAt: DateTime.now(),
      );
      expect(generatedSet.isDraft, isTrue);
      expect(generatedSet.isPublished, isFalse);

      var question = QuizQuestionItem(
        id: 'q-1',
        quizId: generatedSet.id,
        questionText: 'Future trong Dart là gì?',
        options: const [
          'Một giá trị có sẵn trong tương lai',
          'Một widget giao diện',
          'Một hàm đồng bộ',
          'Một biến cục bộ',
        ],
        correctIndex: 0,
        explanation: 'Future đại diện cho một tính toán bất đồng bộ.',
      );

      var flashcard = FlashcardItem(
        id: 'fc-1',
        setId: generatedSet.id,
        frontText: 'Stream trong Dart',
        backText: 'Dãy các sự kiện bất đồng bộ',
        explanation: 'Stream cho phép lắng nghe nhiều giá trị theo thời gian.',
      );

      // 6. Mentor edits draft questions & flashcards
      final updatedQuestion = question.copyWith(
        questionText: 'Khái niệm Future trong Dart là gì?',
        correctIndex: 0,
      );
      expect(updatedQuestion.questionText, 'Khái niệm Future trong Dart là gì?');

      final updatedFlashcard = flashcard.copyWith(
        backText: 'Dãy dữ liệu hoặc sự kiện bất đồng bộ theo thời gian',
      );
      expect(updatedFlashcard.backText, contains('theo thời gian'));

      // 7. Mentor publishes set (BR-06 status update)
      final publishedSet = generatedSet.copyWith(status: 'published');
      expect(publishedSet.isPublished, isTrue);
      expect(publishedSet.isDraft, isFalse);
    });
  });
}
