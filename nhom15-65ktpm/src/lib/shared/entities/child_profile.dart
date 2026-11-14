import 'package:equatable/equatable.dart';

class ChildProfile extends Equatable {
  final String id;
  final String name;
  final int age;
  final int streakCount;
  final String lastActiveDate;
  final List<String> unlockedBadgeIds;
  final int currentLevel;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.streakCount,
    required this.lastActiveDate,
    required this.unlockedBadgeIds,
    required this.currentLevel,
  });

  ChildProfile copyWith({
    String? id,
    String? name,
    int? age,
    int? streakCount,
    String? lastActiveDate,
    List<String>? unlockedBadgeIds,
    int? currentLevel,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      streakCount: streakCount ?? this.streakCount,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
      currentLevel: currentLevel ?? this.currentLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'streakCount': streakCount,
      'lastActiveDate': lastActiveDate,
      'unlockedBadgeIds': unlockedBadgeIds,
      'currentLevel': currentLevel,
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Bé Yêu',
      age: map['age'] ?? 5,
      streakCount: map['streakCount'] ?? 0,
      lastActiveDate: map['lastActiveDate'] ?? '',
      unlockedBadgeIds: List<String>.from(map['unlockedBadgeIds'] ?? []),
      currentLevel: map['currentLevel'] ?? 1,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        streakCount,
        lastActiveDate,
        unlockedBadgeIds,
        currentLevel,
      ];
}
