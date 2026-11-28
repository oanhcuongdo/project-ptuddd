/// Ánh xạ bảng `user_topic_progress` — Tiến độ hoàn thành chủ đề của người dùng.
class TopicProgressModel {
  final String userId;
  final String topicId;
  final bool isCompleted;
  final DateTime completedAt;

  const TopicProgressModel({
    required this.userId,
    required this.topicId,
    this.isCompleted = true,
    required this.completedAt,
  });

  factory TopicProgressModel.fromMap(Map<String, dynamic> map) {
    return TopicProgressModel(
      userId: (map['user_id'] ?? '').toString(),
      topicId: (map['topic_id'] ?? '').toString(),
      isCompleted: map['is_completed'] as bool? ?? true,
      completedAt: map['completed_at'] != null
          ? (DateTime.tryParse(map['completed_at'].toString()) ??
              DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'topic_id': topicId,
        'is_completed': isCompleted,
        'completed_at': completedAt.toIso8601String(),
      };
}

