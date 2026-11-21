import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flashcard_item.dart';
import '../models/generated_set.dart';
import '../models/quiz_question_item.dart';
import 'gemini_schema_helper.dart';
import 'local_ai_fallback_generator.dart';

final aiGeneratorServiceProvider = Provider<AiGeneratorService>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    client = null;
  }
  return AiGeneratorService(client);
});

class AiGeneratedResult {
  final GeneratedSet set;
  final List<FlashcardItem>? flashcards;
  final List<QuizQuestionItem>? questions;

  const AiGeneratedResult({
    required this.set,
    this.flashcards,
    this.questions,
  });
}

class AiGeneratorService {
  final SupabaseClient? _client;

  AiGeneratorService([this._client]);

  SupabaseClient? get client => _client;

  static const String setsTable = 'ck_generated_sets';
  static const String setDocsTable = 'ck_generated_set_documents';
  static const String flashcardsTable = 'ck_flashcards';
  static const String quizzesTable = 'ck_quizzes';
  static const String questionsTable = 'ck_questions';

  /// Generates learning content using Edge Function or Local Fallback, then saves as draft (BR-06)
  Future<AiGeneratedResult> generateContent({
    required String roomId,
    required String createdBy,
    required String title,
    required String contentType, // 'flashcard' | 'quiz'
    required int count,
    required String difficulty,
    String? topic,
    required List<String> documentIds,
    required String documentContext,
  }) async {
    final docError = GeminiSchemaHelper.validateSelectedDocuments(documentIds);
    if (docError != null) throw ArgumentError(docError);

    final countError = GeminiSchemaHelper.validateItemCount(count);
    if (countError != null) throw ArgumentError(countError);

    List<FlashcardItem>? flashcards;
    List<QuizQuestionItem>? questions;

    // 1. Try calling Supabase Edge Function
    var calledEdge = false;
    if (_client != null) {
      try {
        final res = await _client.functions.invoke(
          'generate-learning-content',
          body: {
            'contentType': contentType,
            'count': count,
            'difficulty': difficulty,
            'topic': topic,
            'documentContext': documentContext,
          },
        );

        if (res.status == 200 && res.data is Map<String, dynamic>) {
          final data = res.data as Map<String, dynamic>;
          if (contentType == 'flashcard' && data['flashcards'] is List) {
            flashcards = (data['flashcards'] as List)
                .map((j) => FlashcardItem.fromJson(j as Map<String, dynamic>))
                .toList();
            calledEdge = true;
          } else if (contentType == 'quiz' && data['questions'] is List) {
            questions = (data['questions'] as List)
                .map((j) => QuizQuestionItem.fromJson(j as Map<String, dynamic>))
                .toList();
            calledEdge = true;
          }
        }
      } catch (_) {
        calledEdge = false;
      }
    }

    // 2. Fallback to Local AI Generator if Edge Function is offline/unavailable
    if (!calledEdge) {
      if (contentType == 'flashcard') {
        flashcards = LocalAiFallbackGenerator.generateFlashcards(
          documentText: documentContext,
          count: count,
          difficulty: difficulty,
          topic: topic,
        );
      } else {
        questions = LocalAiFallbackGenerator.generateQuiz(
          documentText: documentContext,
          count: count,
          difficulty: difficulty,
          topic: topic,
        );
      }
    }

    // 3. Save as draft in Supabase
    final draftSet = await saveDraftSet(
      roomId: roomId,
      createdBy: createdBy,
      title: title,
      contentType: contentType,
      difficulty: difficulty,
      topic: topic,
      documentIds: documentIds,
      flashcards: flashcards,
      questions: questions,
    );

    return AiGeneratedResult(
      set: draftSet,
      flashcards: flashcards,
      questions: questions,
    );
  }

  /// Saves a draft generated set with its flashcard or quiz items into Supabase
  Future<GeneratedSet> saveDraftSet({
    required String roomId,
    required String createdBy,
    required String title,
    required String contentType, // 'flashcard' | 'quiz'
    required String difficulty,
    String? topic,
    required List<String> documentIds,
    List<FlashcardItem>? flashcards,
    List<QuizQuestionItem>? questions,
  }) async {
    final docError = GeminiSchemaHelper.validateSelectedDocuments(documentIds);
    if (docError != null) throw ArgumentError(docError);

    if (_client == null) {
      // In-memory fallback for local testing
      return GeneratedSet(
        id: 'draft-${DateTime.now().millisecondsSinceEpoch}',
        roomId: roomId,
        createdBy: createdBy,
        title: title,
        contentType: contentType,
        difficulty: difficulty,
        topic: topic,
        status: 'draft',
        createdAt: DateTime.now(),
      );
    }

    // 1. Insert set record (status = draft, BR-06)
    final setRecord = await _client
        .from(setsTable)
        .insert({
          'room_id': roomId,
          'created_by': createdBy,
          'title': title,
          'content_type': contentType,
          'difficulty': difficulty,
          'topic': topic,
          'status': 'draft',
          'version': 1,
        })
        .select()
        .single();

    final set = GeneratedSet.fromJson(setRecord);

    // 2. Link documents
    for (final docId in documentIds) {
      await _client.from(setDocsTable).insert({
        'set_id': set.id,
        'document_id': docId,
      });
    }

    // 3. Insert items
    if (contentType == 'flashcard' && flashcards != null && flashcards.isNotEmpty) {
      final rows = flashcards.map((f) => {
            'set_id': set.id,
            'front_text': f.frontText,
            'back_text': f.backText,
            'explanation': f.explanation,
            'topic': f.topic ?? topic,
            'difficulty': f.difficulty ?? difficulty,
          }).toList();
      await _client.from(flashcardsTable).insert(rows);
    } else if (contentType == 'quiz' && questions != null && questions.isNotEmpty) {
      final quizRecord = await _client
          .from(quizzesTable)
          .insert({
            'set_id': set.id,
            'title': title,
            'total_questions': questions.length,
          })
          .select()
          .single();

      final quizId = quizRecord['id'] as String;
      final qRows = questions.map((q) => {
            'quiz_id': quizId,
            'question_text': q.questionText,
            'options': q.options,
            'correct_index': q.correctIndex,
            'explanation': q.explanation,
            'topic': q.topic ?? topic,
            'difficulty': q.difficulty ?? difficulty,
          }).toList();
      await _client.from(questionsTable).insert(qRows);
    }

    return set;
  }

  /// Publishes a draft set so room members can access it (BR-06)
  Future<void> publishSet(String setId) async {
    if (_client == null) return;

    await _client.from(setsTable).update({
      'status': 'published',
      'published_at': DateTime.now().toIso8601String(),
    }).eq('id', setId);
  }

  /// Fetches all generated sets for a room
  Future<List<GeneratedSet>> fetchSets(String roomId) async {
    if (_client == null) return [];

    try {
      final res = await _client
          .from(setsTable)
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false);

      return (res as List<dynamic>)
          .map((row) => GeneratedSet.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
