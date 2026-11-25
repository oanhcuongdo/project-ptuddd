class SleepRecordModel {
  final int? id;
  final DateTime sleepTime;
  final DateTime wakeTime;
  final double durationHours;
  final int wakeUpCount; // Số lần thức giấc trong đêm
  final int feelingRating; // 1 (Rất mệt) -> 5 (Rất tỉnh táo)
  final String note;
  final bool isGoalMet;
  final DateTime createdAt;

  SleepRecordModel({
    this.id,
    required this.sleepTime,
    required this.wakeTime,
    required this.durationHours,
    this.wakeUpCount = 0,
    this.feelingRating = 4,
    this.note = '',
    this.isGoalMet = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sleep_time': sleepTime.toIso8601String(),
      'wake_time': wakeTime.toIso8601String(),
      'duration_hours': durationHours,
      'wake_up_count': wakeUpCount,
      'feeling_rating': feelingRating,
      'note': note,
      'is_goal_met': isGoalMet ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SleepRecordModel.fromMap(Map<String, dynamic> map) {
    return SleepRecordModel(
      id: map['id'] as int?,
      sleepTime: DateTime.tryParse(map['sleep_time'] ?? '') ?? DateTime.now().subtract(const Duration(hours: 8)),
      wakeTime: DateTime.tryParse(map['wake_time'] ?? '') ?? DateTime.now(),
      durationHours: (map['duration_hours'] as num?)?.toDouble() ?? 8.0,
      wakeUpCount: map['wake_up_count'] as int? ?? 0,
      feelingRating: map['feeling_rating'] as int? ?? 4,
      note: map['note'] ?? '',
      isGoalMet: (map['is_goal_met'] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
