// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_scores_dao.dart';

// ignore_for_file: type=lint
mixin _$QuizScoresDaoMixin on DatabaseAccessor<AppDatabase> {
  $QuizScoresTable get quizScores => attachedDatabase.quizScores;
  QuizScoresDaoManager get managers => QuizScoresDaoManager(this);
}

class QuizScoresDaoManager {
  final _$QuizScoresDaoMixin _db;
  QuizScoresDaoManager(this._db);
  $$QuizScoresTableTableManager get quizScores =>
      $$QuizScoresTableTableManager(_db.attachedDatabase, _db.quizScores);
}
