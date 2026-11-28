import '../../../../shared/entities/attempt_log.dart';

class ParentDashboardStatistics {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalAttempts;
  final int correctAttempts;
  final int? accuracyPercent;
  final int? averageResponseTimeMs;
  final List<int> attemptsByWeekday;

  ParentDashboardStatistics({
    required this.periodStart,
    required this.periodEnd,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.accuracyPercent,
    required this.averageResponseTimeMs,
    required List<int> attemptsByWeekday,
  }) : attemptsByWeekday = List.unmodifiable(attemptsByWeekday);

  bool get hasData => totalAttempts > 0;
}

class ParentDashboardStatisticsService {
  const ParentDashboardStatisticsService._();

  /// Returns a copy of [logs] ordered from newest to oldest.
  static List<AttemptLog> newestFirst(List<AttemptLog> logs) {
    final sortedLogs = List<AttemptLog>.of(logs);
    sortedLogs.sort((left, right) {
      final leftTime = DateTime.tryParse(left.timestamp)?.toLocal();
      final rightTime = DateTime.tryParse(right.timestamp)?.toLocal();
      if (leftTime == null) return rightTime == null ? 0 : 1;
      if (rightTime == null) return -1;
      return rightTime.compareTo(leftTime);
    });
    return sortedLogs;
  }

  static ParentDashboardStatistics calculate(
    List<AttemptLog> logs, {
    DateTime? now,
  }) {
    final localNow = (now ?? DateTime.now()).toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final periodStart = DateTime(today.year, today.month, today.day - 6);
    final periodEnd = DateTime(today.year, today.month, today.day + 1);
    final attemptsByWeekday = List<int>.filled(DateTime.daysPerWeek, 0);
    final validAttempts = <AttemptLog>[];

    for (final log in logs) {
      if (log.questionId.trim().isEmpty || log.responseTimeMs < 0) continue;

      final parsedTimestamp = DateTime.tryParse(log.timestamp);
      if (parsedTimestamp == null) continue;

      final answeredAt = parsedTimestamp.toLocal();
      if (answeredAt.isAfter(localNow)) continue;

      final answeredDate =
          DateTime(answeredAt.year, answeredAt.month, answeredAt.day);
      if (answeredDate.isBefore(periodStart) ||
          !answeredDate.isBefore(periodEnd)) {
        continue;
      }

      validAttempts.add(log);
      attemptsByWeekday[answeredAt.weekday - DateTime.monday]++;
    }

    final totalAttempts = validAttempts.length;
    final correctAttempts = validAttempts.where((log) => log.isCorrect).length;
    final totalResponseTimeMs = validAttempts.fold<int>(
      0,
      (total, log) => total + log.responseTimeMs,
    );

    return ParentDashboardStatistics(
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalAttempts: totalAttempts,
      correctAttempts: correctAttempts,
      accuracyPercent: totalAttempts == 0
          ? null
          : (correctAttempts * 100 / totalAttempts).round(),
      averageResponseTimeMs: totalAttempts == 0
          ? null
          : (totalResponseTimeMs / totalAttempts).round(),
      attemptsByWeekday: attemptsByWeekday,
    );
  }
}
