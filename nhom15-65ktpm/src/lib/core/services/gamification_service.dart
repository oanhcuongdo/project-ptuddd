import 'dart:math';
import '../../../shared/entities/attempt_log.dart';
import '../../../shared/entities/badge_item.dart';
import '../../../shared/entities/child_profile.dart';
import '../../features/2_gamification_parent/domain/streak_calculator.dart';

class GamificationResult {
  final ChildProfile updatedProfile;
  final List<BadgeItem> newlyUnlockedBadges;
  final int pointsEarned;
  final int streakMultiplier;

  const GamificationResult({
    required this.updatedProfile,
    required this.newlyUnlockedBadges,
    required this.pointsEarned,
    required this.streakMultiplier,
  });
}

class GamificationService {
  static const int pointsPerCorrectAnswer = 10;

  /// Raises the reward multiplier at the same milestones as streak badges.
  static int multiplierForStreak(int streak) {
    if (streak >= 14) return 4;
    if (streak >= 7) return 3;
    if (streak >= 3) return 2;
    return 1;
  }

  static List<BadgeItem> unlockedBadgesFor(ChildProfile profile) {
    final unlockedIds = profile.unlockedBadgeIds.toSet();
    return BadgeDefinitions.allBadges
        .where((badge) => unlockedIds.contains(badge.id))
        .toList(growable: false);
  }

  static List<BadgeItem> lockedBadgesFor(ChildProfile profile) {
    final unlockedIds = profile.unlockedBadgeIds.toSet();
    return BadgeDefinitions.allBadges
        .where((badge) => !unlockedIds.contains(badge.id))
        .toList(growable: false);
  }

  /// Cập nhật chuỗi Streak và kiểm tra mở khóa huy hiệu sau mỗi bài làm
  static GamificationResult processLessonCompletion({
    required ChildProfile profile,
    required List<AttemptLog> allLogs,
    DateTime? now,
  }) {
    final completedAt = now ?? DateTime.now();
    final localCompletedAt = completedAt.toLocal();
    final lastActive = DateTime.tryParse(profile.lastActiveDate);
    final lastRecordedCompletion =
        lastActive != null && completedAt.isBefore(lastActive)
            ? lastActive
            : completedAt;

    final newStreak = StreakCalculator.updateStreak(
      currentStreak: profile.streakCount,
      lastActiveDate: lastActive,
      today: localCompletedAt,
    );

    final newLongest = max(profile.longestStreak, newStreak);
    // StorageService returns recent attempts newest-first; the first log is
    // the answer that triggered this completion.
    final streakMultiplier = multiplierForStreak(newStreak);
    final pointsEarned = allLogs.isNotEmpty && allLogs.first.isCorrect
        ? pointsPerCorrectAnswer * streakMultiplier
        : 0;
    final todayDateStr = StreakCalculator.formatDate(localCompletedAt);

    // Kiểm tra danh sách huy hiệu
    final currentUnlocked = Set<String>.from(profile.unlockedBadgeIds);
    final newlyUnlocked = <BadgeItem>[];

    for (final badge in BadgeDefinitions.allBadges) {
      if (currentUnlocked.contains(badge.id)) continue;

      bool shouldUnlock = false;

      switch (badge.id) {
        case 'starter_star':
          shouldUnlock = allLogs.isNotEmpty;
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
          shouldUnlock = allLogs.any((l) =>
              l.isCorrect && l.answeredVia.toLowerCase().contains('voice'));
          break;
      }

      if (shouldUnlock) {
        final unlockedBadge = badge.copyWith(
          unlockedAt: completedAt.toUtc().toIso8601String(),
        );
        newlyUnlocked.add(unlockedBadge);
        currentUnlocked.add(badge.id);
      }
    }

    final updatedProfile = profile.copyWith(
      streakCount: newStreak,
      longestStreak: newLongest,
      totalPoints: profile.totalPoints + pointsEarned,
      lastActiveDate: lastRecordedCompletion.toUtc().toIso8601String(),
      lastCompletedDate: todayDateStr,
      unlockedBadgeIds: currentUnlocked.toList(),
    );

    return GamificationResult(
      updatedProfile: updatedProfile,
      newlyUnlockedBadges: newlyUnlocked,
      pointsEarned: pointsEarned,
      streakMultiplier: streakMultiplier,
    );
  }
}
