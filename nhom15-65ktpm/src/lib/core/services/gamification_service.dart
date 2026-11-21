import 'dart:math';
import '../../../shared/entities/attempt_log.dart';
import '../../../shared/entities/badge_item.dart';
import '../../../shared/entities/child_profile.dart';
import '../../features/2_gamification_parent/domain/streak_calculator.dart';

class GamificationResult {
  final ChildProfile updatedProfile;
  final List<BadgeItem> newlyUnlockedBadges;

  const GamificationResult({
    required this.updatedProfile,
    required this.newlyUnlockedBadges,
  });
}

class GamificationService {
  /// Cập nhật chuỗi Streak và kiểm tra mở khóa huy hiệu sau mỗi bài làm
  static GamificationResult processLessonCompletion({
    required ChildProfile profile,
    required List<AttemptLog> allLogs,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    DateTime? lastActive;
    if (profile.lastActiveDate.isNotEmpty) {
      try {
        lastActive = DateTime.parse(profile.lastActiveDate);
      } catch (_) {}
    }

    final newStreak = StreakCalculator.updateStreak(
      currentStreak: profile.streakCount,
      lastActiveDate: lastActive,
      today: today,
    );

    final newLongest = max(profile.longestStreak, newStreak);
    final todayDateStr = StreakCalculator.formatDate(today);

    // Kiểm tra danh sách huy hiệu
    final currentUnlocked = Set<String>.from(profile.unlockedBadgeIds);
    final newlyUnlocked = <BadgeItem>[];

    for (final badge in BadgeDefinitions.allBadges) {
      if (currentUnlocked.contains(badge.id)) continue;

      bool shouldUnlock = false;

      switch (badge.id) {
        case 'starter_star':
          shouldUnlock = allLogs.any((l) => l.isCorrect);
          break;
        case 'streak_3_days':
          shouldUnlock = newStreak >= 3;
          break;
        case 'streak_7_days':
          shouldUnlock = newStreak >= 7;
          break;
        case 'streak_14_days':
          shouldUnlock = newStreak >= 14;
          break;
        case 'accuracy_master':
          if (allLogs.length >= 5) {
            shouldUnlock = allLogs.take(5).every((l) => l.isCorrect);
          }
          break;
        case 'speed_demon':
          shouldUnlock = allLogs.any((l) =>
              l.isCorrect && l.responseTimeMs > 0 && l.responseTimeMs <= 1500);
          break;
        case 'voice_explorer':
          shouldUnlock = allLogs.any(
              (l) => l.isCorrect && l.answeredVia.toLowerCase().contains('voice'));
          break;
      }

      if (shouldUnlock) {
        final unlockedBadge = badge.copyWith(unlockedAt: today.toIso8601String());
        newlyUnlocked.add(unlockedBadge);
        currentUnlocked.add(badge.id);
      }
    }

    final updatedProfile = profile.copyWith(
      streakCount: newStreak,
      longestStreak: newLongest,
      lastActiveDate: today.toIso8601String(),
      lastCompletedDate: todayDateStr,
      unlockedBadgeIds: currentUnlocked.toList(),
    );

    return GamificationResult(
      updatedProfile: updatedProfile,
      newlyUnlockedBadges: newlyUnlocked,
    );
  }
}
