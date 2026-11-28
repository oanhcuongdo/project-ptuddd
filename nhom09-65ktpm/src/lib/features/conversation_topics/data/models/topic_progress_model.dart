/// Ánh xạ bảng `user_topic_progress` — Tiến độ hoàn thành chủ đề của người dùng.
class TopicProgressModel {
  final String userId;
  final String topicId;
  final bool isCompleted;
  final DateTime? completedAt;

  const TopicProgressModel({
    required this.userId,
    required this.topicId,
    this.isCompleted = true,
    this.completedAt,
  });

  TopicProgressModel copyWith({
    String? userId,
    String? topicId,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TopicProgressModel(
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  factory TopicProgressModel.fromMap(Map<String, dynamic> map) {
    final completed = map['is_completed'] as bool? ?? true;
    return TopicProgressModel(
      userId: (map['user_id'] ?? '').toString(),
      topicId: (map['topic_id'] ?? '').toString(),
      isCompleted: completed,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'topic_id': topicId,
        'is_completed': isCompleted,
        'completed_at': isCompleted ? completedAt?.toIso8601String() : null,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TopicProgressModel &&
        other.userId == userId &&
        other.topicId == topicId &&
        other.isCompleted == isCompleted &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(userId, topicId, isCompleted, completedAt);
}
