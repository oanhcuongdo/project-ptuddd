import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/core/services/gamification_service.dart';
import 'package:soroban_kids_app/core/services/reminder_service.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/domain/streak_calculator.dart';
import 'package:soroban_kids_app/shared/entities/attempt_log.dart';
import 'package:soroban_kids_app/shared/entities/child_profile.dart';

void main() {
  group('Habit and learning streak management', () {
    test('custom daily reminder waits until its scheduled time and stops after learning', () {
      final profile = ChildProfile(
        id: 'child_habit',
        name: 'Bé An',
        age: 6,
        streakCount: 2,
        longestStreak: 3,
        lastActiveDate: '2026-11-25T10:00:00',
        lastCompletedDate: '2026-11-25',
        unlockedBadgeIds: const [],
        currentLevel: 1,
      );
      const settings = ReminderSettings(enabled: true, hour: 20, minute: 30);

      expect(
        ReminderService.shouldShowInAppReminder(
          settings: settings,
          profile: profile,
          now: DateTime(2026, 11, 26, 20, 29),
        ),
        isFalse,
      );
      expect(
        ReminderService.shouldShowInAppReminder(
          settings: settings,
          profile: profile,
          now: DateTime(2026, 11, 26, 20, 30),
        ),
        isTrue,
      );
      expect(
        ReminderService.shouldShowInAppReminder(
          settings: settings,
          profile: profile.copyWith(lastCompletedDate: '2026-11-26'),
          now: DateTime(2026, 11, 26, 21),
        ),
        isFalse,
      );
    });

    test('consecutive learning updates current and longest streak and unlocks milestone', () {
      final profile = ChildProfile(
        id: 'child_streak',
        name: 'Bé Bình',
        age: 7,
        streakCount: 2,
        longestStreak: 4,
        lastActiveDate: DateTime(2026, 11, 25, 18).toUtc().toIso8601String(),
        lastCompletedDate: '2026-11-25',
        unlockedBadgeIds: const [],
        currentLevel: 1,
      );

      final result = GamificationService.processLessonCompletion(
        profile: profile,
        allLogs: const <AttemptLog>[],
        now: DateTime(2026, 11, 26, 18),
      );

      expect(result.updatedProfile.streakCount, 3);
      expect(result.updatedProfile.longestStreak, 4);
      expect(result.updatedProfile.lastCompletedDate,
          StreakCalculator.formatDate(DateTime(2026, 11, 26, 18)));
      expect(
        result.newlyUnlockedBadges.map((badge) => badge.id),
        contains('streak_3_days'),
      );
    });

    test('missed learning day resets current streak but preserves personal record', () {
      final profile = ChildProfile(
        id: 'child_gap',
        name: 'Bé Chi',
        age: 6,
        streakCount: 6,
        longestStreak: 8,
        lastActiveDate: DateTime(2026, 11, 23, 18).toUtc().toIso8601String(),
        lastCompletedDate: '2026-11-23',
        unlockedBadgeIds: const ['streak_3_days'],
        currentLevel: 1,
      );

      final result = GamificationService.processLessonCompletion(
        profile: profile,
        allLogs: const <AttemptLog>[],
        now: DateTime(2026, 11, 26, 18),
      );

      expect(result.updatedProfile.streakCount, 1);
      expect(result.updatedProfile.longestStreak, 8);
      expect(result.updatedProfile.lastCompletedDate, '2026-11-26');
      expect(
        result.newlyUnlockedBadges.map((badge) => badge.id),
        isNot(contains('streak_3_days')),
      );
    });
  });
}
