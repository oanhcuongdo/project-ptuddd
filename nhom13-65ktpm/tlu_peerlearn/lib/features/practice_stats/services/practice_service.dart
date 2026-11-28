import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ai_generator/models/flashcard_item.dart';
import '../../ai_generator/models/generated_set.dart';
import '../../ai_generator/models/quiz_question_item.dart';
import '../models/flashcard_study_item.dart';
import '../models/quiz_attempt.dart';

final practiceServiceProvider = Provider<PracticeService>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    client = null;
  }
  return PracticeService(client);
});

final roomPublishedSetsProvider =
    FutureProvider.family<List<GeneratedSet>, String>((ref, roomId) async {
  final service = ref.watch(practiceServiceProvider);
  return service.fetchPublishedSets(roomId);
});

class PracticeService {
  final SupabaseClient? _client;

  PracticeService([this._client]);

  SupabaseClient? get client => _client;

  static const String setsTable = 'ck_generated_sets';
  static const String flashcardsTable = 'ck_flashcards';
  static const String progressTable = 'ck_flashcard_progress';
  static const String quizzesTable = 'ck_quizzes';
  static const String questionsTable = 'ck_questions';
  static const String attemptsTable = 'ck_quiz_attempts';
  static const String answersTable = 'ck_attempt_answers';

  /// Fetches published sets for a room (BR-06)
  Future<List<GeneratedSet>> fetchPublishedSets(String roomId) async {
    if (_client == null) return [];

    try {
      final res = await _client
          .from(setsTable)
          .select()
          .eq('room_id', roomId)
          .eq('status', 'published')
          .order('published_at', ascending: false);

      return (res as List<dynamic>)
          .map((row) => GeneratedSet.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches flashcards with user's remembered status (PRA-01)
  Future<List<FlashcardStudyItem>> fetchFlashcardsWithProgress({
    required String setId,
    required String userId,
  }) async {
    if (_client == null) return [];

    try {
      final cardsRes = await _client
          .from(flashcardsTable)
          .select()
          .eq('set_id', setId)
          .order('order_index');

      final rawCards = (cardsRes as List<dynamic>)
          .map((row) => FlashcardItem.fromJson(row as Map<String, dynamic>))
          .toList();

      if (rawCards.isEmpty) return [];

      final cardIds = rawCards.map((c) => c.id).toList();
      final progressRes = await _client
          .from(progressTable)
          .select('flashcard_id, is_remembered')
          .eq('user_id', userId)
          .inFilter('flashcard_id', cardIds);

      final progressMap = <String, bool>{};
      for (final p in (progressRes as List<dynamic>)) {
        progressMap[p['flashcard_id'] as String] =
            p['is_remembered'] as bool? ?? false;
      }

      return rawCards.map((c) {
        return FlashcardStudyItem(
          flashcard: c,
          isRemembered: progressMap[c.id] ?? false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Toggles remembered state for a flashcard (PRA-01)
  Future<void> setFlashcardProgress({
    required String userId,
    required String flashcardId,
    required bool isRemembered,
  }) async {
    if (_client == null) return;

    await _client.from(progressTable).upsert({
      'user_id': userId,
      'flashcard_id': flashcardId,
      'is_remembered': isRemembered,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetches quiz metadata by set ID
  Future<Map<String, dynamic>?> fetchQuizBySetId(String setId) async {
    if (_client == null) return null;

    try {
      final res = await _client
          .from(quizzesTable)
          .select()
          .eq('set_id', setId)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Fetches questions for a quiz
  Future<List<QuizQuestionItem>> fetchQuizQuestions(String quizId) async {
    if (_client == null) return [];

    try {
      final res = await _client
          .from(questionsTable)
          .select()
          .eq('quiz_id', quizId)
          .order('order_index');

      return (res as List<dynamic>)
          .map((row) => QuizQuestionItem.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Submits quiz answers, computes score on 10-point scale, and records attempt (PRA-02, BR-08)
  Future<QuizAttempt> submitQuizAttempt({
    required String quizId,
    required String userId,
    required List<QuizQuestionItem> questions,
    required Map<String, int> selectedAnswers, // questionId -> selectedIndex
  }) async {
    int correctCount = 0;
    final totalCount = questions.length;
    final answerRecords = <Map<String, dynamic>>[];

    for (final q in questions) {
      final selected = selectedAnswers[q.id] ?? -1;
      final isCorrect = selected == q.correctIndex;
      if (isCorrect) correctCount++;

      answerRecords.add({
        'question_id': q.id,
        'selected_index': selected,
        'is_correct': isCorrect,
      });
    }

    final double score = totalCount > 0
        ? double.parse(((correctCount / totalCount) * 10).toStringAsFixed(2))
        : 0.0;

    if (_client == null) {
      // Local fallback for unit tests
      return QuizAttempt(
        id: 'mock-attempt-${DateTime.now().millisecondsSinceEpoch}',
        quizId: quizId,
        userId: userId,
        score: score,
        correctCount: correctCount,
        totalCount: totalCount,
        submittedAt: DateTime.now(),
      );
    }

    // Insert attempt
    final attemptRecord = await _client
        .from(attemptsTable)
        .insert({
          'quiz_id': quizId,
          'user_id': userId,
          'score': score,
          'correct_count': correctCount,
          'total_count': totalCount,
        })
        .select()
        .single();

    final attempt = QuizAttempt.fromJson(attemptRecord);

    // Insert individual answers
    if (answerRecords.isNotEmpty) {
      final rows = answerRecords.map((a) {
        return {
          'attempt_id': attempt.id,
          'question_id': a['question_id'],
          'selected_index': a['selected_index'],
          'is_correct': a['is_correct'],
        };
      }).toList();

      await _client.from(answersTable).insert(rows);
    }

    return attempt;
  }

  /// Analyzes quiz performance (PRA-03)
  Future<QuizAnalyticsSummary> fetchQuizAnalytics(
    String quizId,
    List<QuizQuestionItem> questions,
  ) async {
    if (_client == null) {
      return QuizAnalyticsSummary(
        quizId: quizId,
        totalAttempts: 0,
        averageScore: 0.0,
        highestScore: 0.0,
        questionStats: questions.map((q) {
          return QuestionStat(
            questionId: q.id,
            questionText: q.questionText,
            correctCount: 0,
            totalCount: 0,
            correctRate: 0.0,
          );
        }).toList(),
      );
    }

    try {
      // Fetch all attempts for this quiz
      final attemptsRes = await _client
          .from(attemptsTable)
          .select('id, quiz_id, user_id, score, correct_count, total_count, submitted_at, ck_profiles(full_name)')
          .eq('quiz_id', quizId)
          .order('submitted_at', ascending: false);

      final attempts = (attemptsRes as List<dynamic>)
          .map((r) => QuizAttempt.fromJson(r as Map<String, dynamic>))
          .toList();

      if (attempts.isEmpty) {
        return QuizAnalyticsSummary(
          quizId: quizId,
          totalAttempts: 0,
          averageScore: 0.0,
          highestScore: 0.0,
          questionStats: questions.map((q) => QuestionStat(
            questionId: q.id,
            questionText: q.questionText,
            correctCount: 0,
            totalCount: 0,
            correctRate: 0.0,
          )).toList(),
        );
      }

      final totalAttempts = attempts.length;
      final sumScore = attempts.fold<double>(0.0, (acc, a) => acc + a.score);
      final avgScore = double.parse((sumScore / totalAttempts).toStringAsFixed(2));
      final highestScore = attempts.fold<double>(0.0, (max, a) => a.score > max ? a.score : max);

      // Question accuracy rate
      final attemptIds = attempts.map((a) => a.id).toList();
      final answersRes = await _client
          .from(answersTable)
          .select('question_id, is_correct')
          .inFilter('attempt_id', attemptIds);

      final correctCounts = <String, int>{};
      final totalCounts = <String, int>{};

      for (final ans in (answersRes as List<dynamic>)) {
        final qId = ans['question_id'] as String;
        final isCorrect = ans['is_correct'] as bool? ?? false;
        totalCounts[qId] = (totalCounts[qId] ?? 0) + 1;
        if (isCorrect) {
          correctCounts[qId] = (correctCounts[qId] ?? 0) + 1;
        }
      }

      final questionStats = questions.map((q) {
        final c = correctCounts[q.id] ?? 0;
        final t = totalCounts[q.id] ?? 0;
        final rate = t > 0 ? (c / t) : 0.0;
        return QuestionStat(
          questionId: q.id,
          questionText: q.questionText,
          correctCount: c,
          totalCount: t,
          correctRate: double.parse(rate.toStringAsFixed(2)),
        );
      }).toList();

      return QuizAnalyticsSummary(
        quizId: quizId,
        totalAttempts: totalAttempts,
        averageScore: avgScore,
        highestScore: highestScore,
        questionStats: questionStats,
        recentAttempts: attempts,
      );
    } catch (_) {
      return QuizAnalyticsSummary(
        quizId: quizId,
        totalAttempts: 0,
        averageScore: 0.0,
        highestScore: 0.0,
        questionStats: [],
      );
    }
  }

  /// Fetches latest quiz scores per set_id for a user
  Future<Map<String, double>> fetchUserQuizScores(String userId) async {
    if (_client == null) return {};
    try {
      final rows = await _client
          .from('quiz_attempts')
          .select('score, submitted_at, quizzes!inner(set_id)')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      final Map<String, double> scores = {};
      for (final row in rows as List<dynamic>) {
        final quizObj = row['quizzes'] as Map<String, dynamic>?;
        final setId = quizObj?['set_id'] as String?;
        final score = (row['score'] as num?)?.toDouble();
        if (setId != null && score != null && !scores.containsKey(setId)) {
          scores[setId] = score;
        }
      }
      return scores;
    } catch (_) {
      return {};
    }
  }

  /// Fetches flashcard progress (remembered, total) per set_id for a user
  Future<Map<String, ({int remembered, int total})>>
      fetchUserFlashcardProgressBySet(String userId, List<String> setIds) async {
    if (_client == null || setIds.isEmpty) return {};
    try {
      final cardRows = await _client
          .from('flashcards')
          .select('id, set_id')
          .inFilter('set_id', setIds);

      final Map<String, List<String>> cardsBySet = {};
      final List<String> allCardIds = [];
      for (final r in cardRows as List<dynamic>) {
        final id = r['id'] as String?;
        final setId = r['set_id'] as String?;
        if (id != null && setId != null) {
          cardsBySet.putIfAbsent(setId, () => []).add(id);
          allCardIds.add(id);
        }
      }

      final Set<String> rememberedIds = {};
      if (allCardIds.isNotEmpty) {
        final progRows = await _client
            .from('flashcard_progress')
            .select('flashcard_id, is_remembered')
            .eq('user_id', userId)
            .eq('is_remembered', true)
            .inFilter('flashcard_id', allCardIds);
        for (final p in progRows as List<dynamic>) {
          final fid = p['flashcard_id'] as String?;
          if (fid != null) rememberedIds.add(fid);
        }
      }

      final Map<String, ({int remembered, int total})> result = {};
      for (final setId in setIds) {
        final ids = cardsBySet[setId] ?? [];
        final rem = ids.where((id) => rememberedIds.contains(id)).length;
        result[setId] = (remembered: rem, total: ids.length);
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Fetches personal practice summary (PRA-04)
  Future<PersonalPracticeSummary> fetchPersonalSummary(String userId) async {
    if (_client == null) {
      return const PersonalPracticeSummary(
        totalQuizzesTaken: 0,
        averageScore: 0.0,
        totalFlashcardsStudied: 0,
        rememberedFlashcards: 0,
      );
    }

    try {
      final attemptsRes = await _client
          .from(attemptsTable)
          .select('quiz_id, score, submitted_at')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      final Map<String, double> latestByQuiz = {};
      for (final row in attemptsRes as List<dynamic>) {
        final qId = row['quiz_id'] as String?;
        final score = (row['score'] as num?)?.toDouble();
        if (qId != null && score != null && !latestByQuiz.containsKey(qId)) {
          latestByQuiz[qId] = score;
        }
      }

      final totalQuizzes = latestByQuiz.length;
      double avgScore = 0.0;
      if (totalQuizzes > 0) {
        final sum = latestByQuiz.values.fold<double>(0.0, (a, b) => a + b);
        avgScore = double.parse((sum / totalQuizzes).toStringAsFixed(1));
      }

      final progressRes = await _client
          .from(progressTable)
          .select('is_remembered')
          .eq('user_id', userId);

      final progressList = progressRes as List<dynamic>;
      final totalCards = progressList.length;
      final remembered = progressList
          .where((p) => p['is_remembered'] as bool? ?? false)
          .length;

      return PersonalPracticeSummary(
        totalQuizzesTaken: totalQuizzes,
        averageScore: avgScore,
        totalFlashcardsStudied: totalCards,
        rememberedFlashcards: remembered,
      );
    } catch (_) {
      return const PersonalPracticeSummary(
        totalQuizzesTaken: 0,
        averageScore: 0.0,
        totalFlashcardsStudied: 0,
        rememberedFlashcards: 0,
      );
    }
  }
}
