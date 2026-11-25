class NapRecordModel {
  final int? id;
  final DateTime startTime;
  final int durationMinutes;
  final String note;
  final DateTime createdAt;

  NapRecordModel({
    this.id,
    required this.startTime,
    required this.durationMinutes,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NapRecordModel.fromMap(Map<String, dynamic> map) {
    return NapRecordModel(
      id: map['id'] as int?,
      startTime: DateTime.tryParse(map['start_time'] ?? '') ?? DateTime.now(),
      durationMinutes: map['duration_minutes'] as int? ?? 20,
      note: map['note'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
