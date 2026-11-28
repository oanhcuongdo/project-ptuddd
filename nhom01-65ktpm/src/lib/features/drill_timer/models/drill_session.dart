class DrillSession {
  final int? id;
  final String userId;
  final String drillName;
  final int durationMinutes;
  final int setsCompleted;
  final DateTime createdAt;
  final String? notes;

  const DrillSession({
    this.id,
    required this.userId,
    required this.drillName,
    required this.durationMinutes,
    this.setsCompleted = 1,
    required this.createdAt,
    this.notes,
  });

  Map<String, dynamic> toSupabaseMap() {
    return {
      'user_id': userId,
      'drill_name': drillName,
      'duration_minutes': durationMinutes,
      'sets_completed': setsCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DrillSession.fromSupabaseMap(Map<String, dynamic> map) {
    return DrillSession(
      id: map['id'] as int?,
      userId: map['user_id'] as String? ?? '',
      drillName: map['drill_name'] as String? ?? 'Bài tập bóng đá',
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      setsCompleted: map['sets_completed'] as int? ?? 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      notes: map['notes'] as String?,
    );
  }

  String get formattedDateTime {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString();
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String get summaryText {
    return '$setsCompleted hiệp • $durationMinutes phút';
  }

  DrillSession copyWith({
    int? id,
    String? userId,
    String? drillName,
    int? durationMinutes,
    int? setsCompleted,
    DateTime? createdAt,
    String? notes,
  }) {
    return DrillSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      drillName: drillName ?? this.drillName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      setsCompleted: setsCompleted ?? this.setsCompleted,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}
