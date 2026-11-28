import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soroban_kids_app/core/services/gamification_service.dart';
import 'package:soroban_kids_app/core/services/storage_service.dart';
import 'package:soroban_kids_app/shared/entities/child_profile.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ChildProfile Streak and badges persist through StorageService',
      () async {
    const profile = ChildProfile(
      id: 'child-1',
      name: 'Linh',
      age: 5,
      streakCount: 4,
      longestStreak: 7,
      lastActiveDate: '2026-11-23T18:30:00.000',
      lastCompletedDate: '2026-11-23',
      unlockedBadgeIds: ['starter_star', 'streak_3_days'],
      currentLevel: 2,
    );
    final storage = StorageService();

    await storage.saveChildProfile(profile);
    final restored = await StorageService().getChildProfile();

    expect(restored, profile);
    expect(
      GamificationService.unlockedBadgesFor(restored).map((badge) => badge.id),
      ['starter_star', 'streak_3_days'],
    );
    expect(
      GamificationService.lockedBadgesFor(restored).map((badge) => badge.id),
      [
        'streak_7_days',
        'streak_14_days',
        'accuracy_master',
        'speed_demon',
        'voice_explorer'
      ],
    );
  });

  test('recorded completion survives a StorageService reload', () async {
    final storage = StorageService();
    final profile = await storage.getChildProfile();
    final completedAt = DateTime(2026, 11, 23, 18, 30);
    final result = GamificationService.processLessonCompletion(
      profile: profile,
      allLogs: const [],
      now: completedAt,
    );

    await storage.saveChildProfile(result.updatedProfile);
    final restored = await StorageService().getChildProfile();

    expect(restored.streakCount, 1);
    expect(restored.lastActiveDate, completedAt.toUtc().toIso8601String());
    expect(restored.lastCompletedDate, '2026-11-23');
  });

  test('missing profile returns zero progress and an empty badge collection',
      () async {
    final profile = await StorageService().getChildProfile();

    expect(profile.streakCount, 0);
    expect(profile.longestStreak, 0);
    expect(profile.lastActiveDate, isEmpty);
    expect(profile.lastCompletedDate, isEmpty);
    expect(profile.unlockedBadgeIds, isEmpty);
  });

  test('malformed stored profile returns a safe empty profile', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('soroban_child_profile', '{not-json');

    final profile = await StorageService().getChildProfile();

    expect(profile.streakCount, 0);
    expect(profile.longestStreak, 0);
    expect(profile.unlockedBadgeIds, isEmpty);
  });

  test('invalid profile fields are normalized without losing valid badge ids',
      () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'soroban_child_profile',
      jsonEncode({
        'streakCount': -2,
        'longestStreak': 'unknown',
        'lastActiveDate': 7,
        'lastCompletedDate': false,
        'unlockedBadgeIds': ['starter_star', 3],
      }),
    );

    final profile = await StorageService().getChildProfile();

    expect(profile.streakCount, 0);
    expect(profile.longestStreak, 0);
    expect(profile.lastActiveDate, isEmpty);
    expect(profile.lastCompletedDate, isEmpty);
    expect(profile.unlockedBadgeIds, ['starter_star']);
  });

  test('non-object profile JSON returns a safe empty profile', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('soroban_child_profile', jsonEncode([1, 2]));

    final profile = await StorageService().getChildProfile();

    expect(profile.streakCount, 0);
    expect(profile.unlockedBadgeIds, isEmpty);
  });
}
