import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/core/services/gamification_service.dart';
import 'package:soroban_kids_app/core/services/reminder_service.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/domain/streak_calculator.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/engine/adaptive_tutor_engine.dart';
import 'package:soroban_kids_app/shared/entities/attempt_log.dart';
import 'package:soroban_kids_app/shared/entities/child_profile.dart';

void main() {
  group('Adaptive Learning Engine & Gamification Tests (Mục 7.8 - 7.11)', () {
    test(
        'AdaptiveLearningEngine: Cửa sổ trượt 5 bài tăng tốc khi đúng >= 80% & phản hồi nhanh',
        () {
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

    test(
        'AdaptiveLearningEngine: Bật thị phạm ngón tay và giảm độ khó khi trẻ gặp khó khăn',
        () {
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
        AttemptLog(
          questionId: 'q_4',
          userAnswer: 1,
          isCorrect: false,
          responseTimeMs: 6800,
          answeredVia: 'abacus_touch',
          timestamp: DateTime.now().toIso8601String(),
          difficultyLevel: 2,
        ),
        AttemptLog(
          questionId: 'q_5',
          userAnswer: 0,
          isCorrect: false,
          responseTimeMs: 6600,
          answeredVia: 'abacus_touch',
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
      expect(decision.fingerGuideEnabled,
          isTrue); // Bật hướng dẫn thị phạm ngón tay
    });

    test(
        'GamificationService: Mở khóa huy hiệu và tăng Streak khi hoàn thành bài',
        () {
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
        now: DateTime(2026, 11,
            21), // Ngày tiếp theo -> streak lên 3 -> mở khóa streak_3_days
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

    test('starter badge unlocks on the first completed attempt', () {
      final profile = ChildProfile(
        id: 'child_starter',
        name: 'Bé Nam',
        age: 5,
        streakCount: 0,
        lastActiveDate: '',
        unlockedBadgeIds: const [],
        currentLevel: 1,
      );
      final result = GamificationService.processLessonCompletion(
        profile: profile,
        allLogs: const [
          AttemptLog(
            questionId: 'q_1',
            userAnswer: 0,
            isCorrect: false,
            responseTimeMs: 3000,
            answeredVia: 'abacus_touch',
            timestamp: '2026-11-23T10:00:00',
          ),
        ],
        now: DateTime(2026, 11, 23, 10),
      );

      expect(
        result.newlyUnlockedBadges.map((badge) => badge.id),
        contains('starter_star'),
      );
    });

    test('accuracy badge requires five most recent correct attempts', () {
      final profile = ChildProfile(
        id: 'child_accuracy',
        name: 'Bé Nam',
        age: 5,
        streakCount: 0,
        lastActiveDate: '',
        unlockedBadgeIds: const [],
        currentLevel: 1,
      );

      List<AttemptLog> attemptsWithCorrectCount(int correctCount) {
        return List.generate(
          5,
          (index) => AttemptLog(
            questionId: 'q_$index',
            userAnswer: 1,
            isCorrect: index < correctCount,
            responseTimeMs: 3000,
            answeredVia: 'abacus_touch',
            timestamp: '2026-11-23T10:00:00',
          ),
        );
      }

      final allCorrect = GamificationService.processLessonCompletion(
        profile: profile,
        allLogs: attemptsWithCorrectCount(5),
        now: DateTime(2026, 11, 23, 10),
      );
      final oneIncorrect = GamificationService.processLessonCompletion(
        profile: profile,
        allLogs: attemptsWithCorrectCount(4),
        now: DateTime(2026, 11, 23, 10),
      );

      expect(
        allCorrect.newlyUnlockedBadges.map((badge) => badge.id),
        contains('accuracy_master'),
      );
      expect(
        oneIncorrect.newlyUnlockedBadges.map((badge) => badge.id),
        isNot(contains('accuracy_master')),
      );
    });

    test('owned badges are not unlocked again and badge ids stay unique', () {
      final profile = ChildProfile(
        id: 'child_owned',
        name: 'Bé Nam',
        age: 5,
        streakCount: 1,
        lastActiveDate: DateTime(2026, 11, 22, 10).toUtc().toIso8601String(),
        lastCompletedDate: '2026-11-22',
        unlockedBadgeIds: const ['starter_star', 'starter_star'],
        currentLevel: 1,
      );
      const log = AttemptLog(
        questionId: 'q_1',
        userAnswer: 5,
        isCorrect: true,
        responseTimeMs: 1200,
        answeredVia: 'voice',
        timestamp: '2026-11-23T10:00:00',
      );

      final result = GamificationService.processLessonCompletion(
        profile: profile,
        allLogs: const [log],
        now: DateTime(2026, 11, 23, 10),
      );
      final newlyUnlockedIds =
          result.newlyUnlockedBadges.map((badge) => badge.id).toList();
      final ownedIds = result.updatedProfile.unlockedBadgeIds;

      expect(newlyUnlockedIds, isNot(contains('starter_star')));
      expect(newlyUnlockedIds.toSet().length, newlyUnlockedIds.length);
      expect(ownedIds.toSet().length, ownedIds.length);
    });

    test(
        'GamificationService records completion time and avoids same-day increments',
        () {
      final initialProfile = ChildProfile(
        id: 'child_2',
        name: 'Bé Linh',
        age: 5,
        streakCount: 0,
        longestStreak: 0,
        lastActiveDate: '',
        lastCompletedDate: '',
        unlockedBadgeIds: const [],
        currentLevel: 1,
      );
      final firstCompletion = DateTime(2026, 11, 23, 18, 30);

      final firstResult = GamificationService.processLessonCompletion(
        profile: initialProfile,
        allLogs: const [],
        now: firstCompletion,
      );
      final secondCompletion = firstCompletion.add(const Duration(hours: 4));
      final secondResult = GamificationService.processLessonCompletion(
        profile: firstResult.updatedProfile,
        allLogs: const [],
        now: secondCompletion,
      );

      expect(firstResult.updatedProfile.streakCount, 1);
      expect(
        firstResult.updatedProfile.lastActiveDate,
        firstCompletion.toUtc().toIso8601String(),
      );
      expect(
        firstResult.updatedProfile.lastCompletedDate,
        StreakCalculator.formatDate(firstCompletion),
      );
      expect(secondResult.updatedProfile.streakCount, 1);
      expect(
        secondResult.updatedProfile.lastActiveDate,
        secondCompletion.toUtc().toIso8601String(),
      );
    });

    test('GamificationService does not rewind the saved completion timestamp',
        () {
      final lastCompletion = DateTime(2026, 11, 23, 10).toUtc();
      final profile = ChildProfile(
        id: 'child_3',
        name: 'Bé An',
        age: 5,
        streakCount: 5,
        longestStreak: 5,
        lastActiveDate: lastCompletion.toIso8601String(),
        lastCompletedDate: '2026-11-23',
        unlockedBadgeIds: const [],
        currentLevel: 1,
      );

      final result = GamificationService.processLessonCompletion(
        profile: profile,
        allLogs: const [],
        now: lastCompletion.subtract(const Duration(hours: 2)),
      );

      expect(result.updatedProfile.streakCount, 5);
      expect(
        result.updatedProfile.lastActiveDate,
        lastCompletion.toIso8601String(),
      );
    });

    test('ReminderService: Hiển thị nhắc nhở sau 19:00 nếu chưa học hôm nay',
        () {
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
      final completedProfile =
          profile.copyWith(lastCompletedDate: '2026-11-21');
      expect(
        ReminderService.shouldShowInAppReminder(
          settings: settings,
          profile: completedProfile,
          now: at1915,
        ),
        isFalse,
      );
    });
  });
}
