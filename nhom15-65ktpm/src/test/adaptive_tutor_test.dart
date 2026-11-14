import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/domain/streak_calculator.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/engine/adaptive_tutor_engine.dart';
import 'package:soroban_kids_app/shared/entities/attempt_log.dart';

void main() {
  group('Adaptive Tutor Engine Tests (Module 4 - Cẩm Ly)', () {
    test('TC_AI_01: Tăng tốc độ và độ khó khi bé làm đúng 100% và rất nhanh', () {
      final fastCorrectLogs = List.generate(
        5,
        (i) => AttemptLog(
          questionId: 'q_$i',
          userAnswer: 5,
          isCorrect: true,
          responseTimeMs: 1500, // 1.5s
          answeredVia: 'voice',
          timestamp: DateTime.now().toIso8601String(),
        ),
      );

      final decision = AdaptiveTutorEngine.evaluatePerformance(
        recentAttempts: fastCorrectLogs,
        currentFlashSpeedMs: 1200,
      );

      expect(decision.action, AdaptiveAction.speedUp);
      expect(decision.recommendedSpeedMs, 1000); // 1200 - 200 = 1000ms
    });

    test('TC_AI_02: Chuyển sang hướng dẫn thị phạm khi bé làm sai nhiều', () {
      final strugglingLogs = [
        AttemptLog(
          questionId: 'q_1',
          userAnswer: 2,
          isCorrect: false,
          responseTimeMs: 7000,
          answeredVia: 'abacus_touch',
          timestamp: DateTime.now().toIso8601String(),
        ),
        AttemptLog(
          questionId: 'q_2',
          userAnswer: 3,
          isCorrect: false,
          responseTimeMs: 6500,
          answeredVia: 'abacus_touch',
          timestamp: DateTime.now().toIso8601String(),
        ),
        AttemptLog(
          questionId: 'q_3',
          userAnswer: 5,
          isCorrect: true,
          responseTimeMs: 4000,
          answeredVia: 'voice',
          timestamp: DateTime.now().toIso8601String(),
        ),
      ];

      final decision = AdaptiveTutorEngine.evaluatePerformance(
        recentAttempts: strugglingLogs,
        currentFlashSpeedMs: 1200,
      );

      expect(decision.action, AdaptiveAction.guideHighlight);
      expect(decision.recommendedSpeedMs, 1400); // 1200 + 200 = 1400ms
    });

    test('TC_AI_03: Duy trì độ khó khi bé làm bài ổn định', () {
      final steadyLogs = List.generate(
        5,
        (i) => AttemptLog(
          questionId: 'q_$i',
          userAnswer: 5,
          isCorrect: i != 0, // 4/5 đúng = 80%
          responseTimeMs: 3500, // 3.5s
          answeredVia: 'abacus_touch',
          timestamp: DateTime.now().toIso8601String(),
        ),
      );

      final decision = AdaptiveTutorEngine.evaluatePerformance(
        recentAttempts: steadyLogs,
        currentFlashSpeedMs: 1200,
      );

      expect(decision.action, AdaptiveAction.stayCurrent);
      expect(decision.recommendedSpeedMs, 1200);
    });
  });

  group('Streak Calculator Tests (Module 2 - Duy Thái)', () {
    test('Duy trì streak khi học tiếp tục vào ngày kế tiếp', () {
      final yesterday = DateTime(2026, 11, 13);
      final today = DateTime(2026, 11, 14);

      final streak = StreakCalculator.updateStreak(
        currentStreak: 3,
        lastActiveDate: yesterday,
        today: today,
      );

      expect(streak, 4);
    });

    test('Giữ nguyên streak khi bé học nhiều lần trong cùng 1 ngày', () {
      final todayMorning = DateTime(2026, 11, 14, 8, 0);
      final todayEvening = DateTime(2026, 11, 14, 19, 0);

      final streak = StreakCalculator.updateStreak(
        currentStreak: 5,
        lastActiveDate: todayMorning,
        today: todayEvening,
      );

      expect(streak, 5);
    });

    test('Reset streak về 1 khi bị gián đoạn nhiều hơn 1 ngày', () {
      final threeDaysAgo = DateTime(2026, 11, 10);
      final today = DateTime(2026, 11, 14);

      final streak = StreakCalculator.updateStreak(
        currentStreak: 10,
        lastActiveDate: threeDaysAgo,
        today: today,
      );

      expect(streak, 1);
    });
  });
}
