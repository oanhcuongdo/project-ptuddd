class PlanModel {
  const PlanModel({
    required this.id,
    required this.personalTopicId,
    required this.userId,
    required this.title,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String personalTopicId;
  final String userId;
  final String title;
  final String? description;
  final DateTime createdAt;

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String,
      personalTopicId: json['personal_topic_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personal_topic_id': personalTopicId,
      'user_id': userId,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
