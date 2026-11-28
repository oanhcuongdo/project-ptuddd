import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/domain/services/parent_dashboard_statistics_service.dart';
import 'package:soroban_kids_app/shared/entities/attempt_log.dart';

AttemptLog _log({
  required String id,
  required String timestamp,
  bool isCorrect = false,
  int responseTimeMs = 1000,
}) {
  return AttemptLog(
    questionId: id,
    userAnswer: 1,
    isCorrect: isCorrect,
    responseTimeMs: responseTimeMs,
    answeredVia: 'abacus_touch',
    timestamp: timestamp,
  );
}

void main() {
  group('ParentDashboardStatisticsService', () {
    final now = DateTime(2026, 11, 27, 12);

    test('calculates weekly totals, accuracy, average time, and weekdays', () {
      final statistics = ParentDashboardStatisticsService.calculate(
        [
          _log(
            id: 'saturday',
            timestamp: DateTime(2026, 11, 21, 10).toIso8601String(),
            isCorrect: true,
            responseTimeMs: 500,
          ),
          _log(
            id: 'monday-1',
            timestamp: DateTime(2026, 11, 23, 10).toIso8601String(),
            isCorrect: true,
            responseTimeMs: 500,
          ),
          _log(
            id: 'monday-2',
            timestamp: DateTime(2026, 11, 23, 11).toIso8601String(),
            responseTimeMs: 1000,
          ),
          _log(
            id: 'today',
            timestamp: DateTime(2026, 11, 27, 10).toIso8601String(),
            responseTimeMs: 1500,
          ),
          _log(
            id: 'older-than-seven-days',
            timestamp: DateTime(2026, 11, 20, 10).toIso8601String(),
          ),
          _log(
            id: 'future',
            timestamp: DateTime(2026, 11, 27, 13).toIso8601String(),
          ),
          _log(id: 'invalid-time', timestamp: 'not-a-date'),
          _log(
            id: 'invalid-duration',
            timestamp: DateTime(2026, 11, 26, 10).toIso8601String(),
            responseTimeMs: -1,
          ),
          _log(
            id: '',
            timestamp: DateTime(2026, 11, 26, 10).toIso8601String(),
          ),
        ],
        now: now,
      );

      expect(statistics.periodStart, DateTime(2026, 11, 21));
      expect(statistics.periodEnd, DateTime(2026, 11, 28));
      expect(statistics.totalAttempts, 4);
      expect(statistics.correctAttempts, 2);
      expect(statistics.accuracyPercent, 50);
      expect(statistics.averageResponseTimeMs, 875);
      expect(statistics.attemptsByWeekday, [2, 0, 0, 0, 1, 1, 0]);
      expect(statistics.hasData, isTrue);
    });

    test('returns an empty summary when there are no valid weekly records', () {
      final statistics = ParentDashboardStatisticsService.calculate(
        [
          _log(id: 'invalid', timestamp: 'bad-date'),
          _log(
            id: 'old',
            timestamp: DateTime(2026, 11, 20).toIso8601String(),
          ),
        ],
        now: now,
      );

      expect(statistics.totalAttempts, 0);
      expect(statistics.correctAttempts, 0);
      expect(statistics.accuracyPercent, isNull);
      expect(statistics.averageResponseTimeMs, isNull);
      expect(statistics.attemptsByWeekday, everyElement(0));
      expect(statistics.hasData, isFalse);
    });
  });
}
