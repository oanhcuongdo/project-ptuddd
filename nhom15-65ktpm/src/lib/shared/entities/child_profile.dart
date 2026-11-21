import 'package:equatable/equatable.dart';

class ChildProfile extends Equatable {
  final String id;
  final String name;
  final int age;
  final int streakCount;
  final int longestStreak;
  final String lastActiveDate;
  final String lastCompletedDate;
  final List<String> unlockedBadgeIds;
  final int currentLevel;
  final int flashSpeedMs;
  final bool fingerGuideEnabled;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.streakCount,
    this.longestStreak = 3,
    required this.lastActiveDate,
    this.lastCompletedDate = '',
    required this.unlockedBadgeIds,
    required this.currentLevel,
    this.flashSpeedMs = 1200,
    this.fingerGuideEnabled = false,
  });

  ChildProfile copyWith({
    String? id,
    String? name,
    int? age,
    int? streakCount,
    int? longestStreak,
    String? lastActiveDate,
    String? lastCompletedDate,
    List<String>? unlockedBadgeIds,
    int? currentLevel,
    int? flashSpeedMs,
    bool? fingerGuideEnabled,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
      currentLevel: currentLevel ?? this.currentLevel,
      flashSpeedMs: flashSpeedMs ?? this.flashSpeedMs,
      fingerGuideEnabled: fingerGuideEnabled ?? this.fingerGuideEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'streakCount': streakCount,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate,
      'lastCompletedDate': lastCompletedDate,
      'unlockedBadgeIds': unlockedBadgeIds,
      'currentLevel': currentLevel,
      'flashSpeedMs': flashSpeedMs,
      'fingerGuideEnabled': fingerGuideEnabled,
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Bé Yêu',
      age: map['age'] ?? 5,
      streakCount: map['streakCount'] ?? 0,
      longestStreak: map['longestStreak'] ?? (map['streakCount'] ?? 3),
      lastActiveDate: map['lastActiveDate'] ?? '',
      lastCompletedDate: map['lastCompletedDate'] ?? '',
      unlockedBadgeIds: (map['unlockedBadgeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['starter_star', 'streak_3_days'],
      currentLevel: map['currentLevel'] ?? 1,
      flashSpeedMs: map['flashSpeedMs'] ?? 1200,
      fingerGuideEnabled: map['fingerGuideEnabled'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        streakCount,
        longestStreak,
        lastActiveDate,
        lastCompletedDate,
        unlockedBadgeIds,
        currentLevel,
        flashSpeedMs,
        fingerGuideEnabled,
      ];
}
