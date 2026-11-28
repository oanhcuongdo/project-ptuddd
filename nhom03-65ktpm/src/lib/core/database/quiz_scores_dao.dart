import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables.dart';

part 'quiz_scores_dao.g.dart';

@DriftAccessor(tables: [QuizScores])
class QuizScoresDao extends DatabaseAccessor<AppDatabase>
    with _$QuizScoresDaoMixin {
  QuizScoresDao(super.db);

  Future<void> insertScore(QuizScoresCompanion score) =>
      into(quizScores).insert(score);

  Future<List<QuizScoreRow>> getAll() {
    final query = select(quizScores)
      ..orderBy([(QuizScores t) => OrderingTerm.desc(t.completedAt)]);
    return query.get();
  }
}
