class SleepGoalModel {
  final int? id;
  final int bedtimeHour;
  final int bedtimeMinute;
  final int wakeHour;
  final int wakeMinute;
  final double targetDurationHours;
  final String activeDays; // e.g. "T2,T3,T4,T5,T6,T7,CN"
  final bool isReminderEnabled;

  SleepGoalModel({
    this.id,
    required this.bedtimeHour,
    required this.bedtimeMinute,
    required this.wakeHour,
    required this.wakeMinute,
    required this.targetDurationHours,
    this.activeDays = 'T2,T3,T4,T5,T6,T7,CN',
    this.isReminderEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bedtime_hour': bedtimeHour,
      'bedtime_minute': bedtimeMinute,
      'wake_hour': wakeHour,
      'wake_minute': wakeMinute,
      'target_duration_hours': targetDurationHours,
      'active_days': activeDays,
      'is_reminder_enabled': isReminderEnabled ? 1 : 0,
    };
  }

  factory SleepGoalModel.fromMap(Map<String, dynamic> map) {
    return SleepGoalModel(
      id: map['id'] as int?,
      bedtimeHour: map['bedtime_hour'] as int? ?? 23,
      bedtimeMinute: map['bedtime_minute'] as int? ?? 0,
      wakeHour: map['wake_hour'] as int? ?? 7,
      wakeMinute: map['wake_minute'] as int? ?? 0,
      targetDurationHours: (map['target_duration_hours'] as num?)?.toDouble() ?? 8.0,
      activeDays: map['active_days'] as String? ?? 'T2,T3,T4,T5,T6,T7,CN',
      isReminderEnabled: (map['is_reminder_enabled'] as int? ?? 1) == 1,
    );
  }
}
