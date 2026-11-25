class ReminderModel {
  final int? id;
  final String title;
  final int hour;
  final int minute;
  final String type; // 'prepare_sleep', 'bedtime', 'wakeup'
  final bool isEnabled;

  ReminderModel({
    this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.type,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'hour': hour,
      'minute': minute,
      'type': type,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as int?,
      title: map['title'] ?? '',
      hour: map['hour'] as int? ?? 22,
      minute: map['minute'] as int? ?? 30,
      type: map['type'] ?? 'prepare_sleep',
      isEnabled: (map['is_enabled'] as int? ?? 1) == 1,
    );
  }
}
