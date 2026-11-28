import 'package:equatable/equatable.dart';

class ChildProfile extends Equatable {
  final String id;
  final String name;
  final int age;
  final int streakCount;
  final int longestStreak;
  final int totalPoints;
  final String lastActiveDate;
  final String lastCompletedDate;
  final List<String> unlockedBadgeIds;
  final int currentLevel;
  final int flashAnzanLevel;
  final int flashSpeedMs;
  final bool fingerGuideEnabled;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.streakCount,
    this.longestStreak = 0,
    this.totalPoints = 0,
    required this.lastActiveDate,
    this.lastCompletedDate = '',
    required this.unlockedBadgeIds,
    required this.currentLevel,
    this.flashAnzanLevel = 1,
    this.flashSpeedMs = 2500,
    this.fingerGuideEnabled = false,
  });

  ChildProfile copyWith({
    String? id,
    String? name,
    int? age,
    int? streakCount,
    int? longestStreak,
    int? totalPoints,
    String? lastActiveDate,
    String? lastCompletedDate,
    List<String>? unlockedBadgeIds,
    int? currentLevel,
    int? flashAnzanLevel,
    int? flashSpeedMs,
    bool? fingerGuideEnabled,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      totalPoints: totalPoints ?? this.totalPoints,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
      currentLevel: currentLevel ?? this.currentLevel,
      flashAnzanLevel: flashAnzanLevel ?? this.flashAnzanLevel,
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
      'totalPoints': totalPoints,
      'lastActiveDate': lastActiveDate,
      'lastCompletedDate': lastCompletedDate,
      'unlockedBadgeIds': unlockedBadgeIds,
      'currentLevel': currentLevel,
      'flashAnzanLevel': flashAnzanLevel,
      'flashSpeedMs': flashSpeedMs,
      'fingerGuideEnabled': fingerGuideEnabled,
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    final streakCount = _nonNegativeInt(map['streakCount'], 0);
    final badgeIds = map['unlockedBadgeIds'];

    return ChildProfile(
      id: _stringValue(map['id'], ''),
      name: _stringValue(map['name'], 'Bé Yêu'),
      age: _nonNegativeInt(map['age'], 5),
      streakCount: streakCount,
      longestStreak: _nonNegativeInt(map['longestStreak'], streakCount),
      totalPoints: _nonNegativeInt(map['totalPoints'], 0),
      lastActiveDate: _stringValue(map['lastActiveDate'], ''),
      lastCompletedDate: _stringValue(map['lastCompletedDate'], ''),
      unlockedBadgeIds:
          badgeIds is List ? badgeIds.whereType<String>().toList() : const [],
      currentLevel: _nonNegativeInt(map['currentLevel'], 1),
      flashAnzanLevel: _nonNegativeInt(map['flashAnzanLevel'], 1),
      flashSpeedMs: _nonNegativeInt(map['flashSpeedMs'], 2500),
      fingerGuideEnabled: map['fingerGuideEnabled'] is bool
          ? map['fingerGuideEnabled'] as bool
          : false,
    );
  }

  static int _nonNegativeInt(Object? value, int fallback) {
    return value is int && value >= 0 ? value : fallback;
  }

  static String _stringValue(Object? value, String fallback) {
    return value is String ? value : fallback;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        streakCount,
        longestStreak,
        totalPoints,
        lastActiveDate,
        lastCompletedDate,
        unlockedBadgeIds,
        currentLevel,
        flashAnzanLevel,
        flashSpeedMs,
        fingerGuideEnabled,
      ];
}
