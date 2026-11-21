import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/core/services/gamification_service.dart';
import 'package:soroban_kids_app/core/services/reminder_service.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/widgets/parental_gate_dialog.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/engine/adaptive_tutor_engine.dart';
import 'package:soroban_kids_app/shared/entities/attempt_log.dart';
import 'package:soroban_kids_app/shared/entities/child_profile.dart';

void main() {
  group('Adaptive Learning Engine & Gamification Tests (Mục 7.8 - 7.11)', () {
    test('AdaptiveLearningEngine: Cửa sổ trượt 5 bài tăng tốc khi đúng >= 80% & phản hồi nhanh', () {
      final fastLogs = List.generate(
        5,
        (i) => AttemptLog(
          questionId: 'q_$i',
          userAnswer: 4,
          isCorrect: true,
          responseTimeMs: 1400,
          answeredVia: 'voice',
          timestamp: DateTime.now().toIso8601String(),
          difficultyLevel: 1,
        ),
      );

      final decision = AdaptiveLearningEngine.evaluatePerformance(
        recentAttempts: fastLogs,
        currentFlashSpeedMs: 1200,
        currentLevel: 1,
      );

      expect(decision.action, AdaptiveAction.speedUp);
      expect(decision.recommendedSpeedMs, 1000); // 1200 - 200 = 1000ms
      expect(decision.recommendedLevel, 2); // Nâng từ level 1 lên level 2
      expect(decision.fingerGuideEnabled, isFalse);
      expect(decision.reason.contains('80%'), isTrue);
    });

    test('AdaptiveLearningEngine: Bật thị phạm ngón tay và giảm độ khó khi trẻ gặp khó khăn', () {
      final strugglingLogs = [
        AttemptLog(
          questionId: 'q_1',
          userAnswer: 2,
          isCorrect: false,
          responseTimeMs: 6500,
          answeredVia: 'abacus_touch',
          timestamp: DateTime.now().toIso8601String(),
          difficultyLevel: 2,
        ),
        AttemptLog(
          questionId: 'q_2',
          userAnswer: 3,
          isCorrect: false,
          responseTimeMs: 7000,
          answeredVia: 'abacus_touch',
          timestamp: DateTime.now().toIso8601String(),
          difficultyLevel: 2,
        ),
        AttemptLog(
          questionId: 'q_3',
          userAnswer: 5,
          isCorrect: true,
          responseTimeMs: 4000,
          answeredVia: 'voice',
          timestamp: DateTime.now().toIso8601String(),
          difficultyLevel: 2,
        ),
      ];

      final decision = AdaptiveLearningEngine.evaluatePerformance(
        recentAttempts: strugglingLogs,
        currentFlashSpeedMs: 1200,
        currentLevel: 2,
      );

      expect(decision.action, AdaptiveAction.guideHighlight);
      expect(decision.recommendedSpeedMs, 1400); // 1200 + 200 = 1400ms
      expect(decision.recommendedLevel, 1); // Giảm từ level 2 về level 1
      expect(decision.fingerGuideEnabled, isTrue); // Bật hướng dẫn thị phạm ngón tay
    });

    test('GamificationService: Mở khóa huy hiệu và tăng Streak khi hoàn thành bài', () {
      final initialProfile = ChildProfile(
        id: 'child_1',
        name: 'Bé Nam',
        age: 5,
        streakCount: 2,
        longestStreak: 2,
        lastActiveDate: DateTime(2026, 11, 20).toIso8601String(),
        lastCompletedDate: '2026-11-20',
        unlockedBadgeIds: const [],
        currentLevel: 1,
      );

      final logs = [
        AttemptLog(
          questionId: 'q_1',
          userAnswer: 5,
          isCorrect: true,
          responseTimeMs: 1200, // < 1.5s -> đủ điều kiện speed_demon
          answeredVia: 'voice', // voice -> đủ điều kiện voice_explorer
          timestamp: DateTime(2026, 11, 21, 19, 30).toIso8601String(),
        ),
      ];

      final result = GamificationService.processLessonCompletion(
        profile: initialProfile,
        allLogs: logs,
        now: DateTime(2026, 11, 21), // Ngày tiếp theo -> streak lên 3 -> mở khóa streak_3_days
      );

      expect(result.updatedProfile.streakCount, 3);
      expect(result.updatedProfile.longestStreak, 3);
      expect(result.newlyUnlockedBadges.length, greaterThanOrEqualTo(3));

      final badgeIds = result.newlyUnlockedBadges.map((b) => b.id).toList();
      expect(badgeIds.contains('starter_star'), isTrue);
      expect(badgeIds.contains('streak_3_days'), isTrue);
      expect(badgeIds.contains('speed_demon'), isTrue);
      expect(badgeIds.contains('voice_explorer'), isTrue);
    });

    test('ReminderService: Hiển thị nhắc nhở sau 19:00 nếu chưa học hôm nay', () {
      final profile = ChildProfile(
        id: 'child_1',
        name: 'Bé Nam',
        age: 5,
        streakCount: 2,
        lastActiveDate: '2026-11-20T10:00:00',
        lastCompletedDate: '2026-11-20',
        unlockedBadgeIds: const [],
        currentLevel: 1,
      );

      const settings = ReminderSettings(enabled: true, hour: 19, minute: 0);

      // Trường hợp 1: Lúc 18:30 (chưa đến giờ) -> không nhắc
      final at1830 = DateTime(2026, 11, 21, 18, 30);
      expect(
        ReminderService.shouldShowInAppReminder(
          settings: settings,
          profile: profile,
          now: at1830,
        ),
        isFalse,
      );

      // Trường hợp 2: Lúc 19:15 và chưa học hôm nay -> HIỂN THỊ NHẮC NHỞ
      final at1915 = DateTime(2026, 11, 21, 19, 15);
      expect(
        ReminderService.shouldShowInAppReminder(
          settings: settings,
          profile: profile,
          now: at1915,
        ),
        isTrue,
      );

      // Trường hợp 3: Đã hoàn thành hôm nay rồi -> không nhắc nữa
      final completedProfile = profile.copyWith(lastCompletedDate: '2026-11-21');
      expect(
        ReminderService.shouldShowInAppReminder(
          settings: settings,
          profile: completedProfile,
          now: at1915,
        ),
        isFalse,
      );
    });

    test('ParentalGate: Sinh câu hỏi toán chữ tiếng Việt ngẫu nhiên', () {
      final question = VerbalMathQuestion.generate();
      expect(question.questionText.contains('bằng mấy?'), isTrue);
      expect(question.options.contains(question.answer), isTrue);
      expect(question.options.length, 4);
    });
  });
}
