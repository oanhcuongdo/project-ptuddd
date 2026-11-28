import 'task_model.dart';

enum PlanStatus {
  active,
  completed,
  archived;

  String toDatabaseValue() => name;

  static PlanStatus fromDatabaseValue(String value) {
    return switch (value) {
      'active' => PlanStatus.active,
      'completed' => PlanStatus.completed,
      'archived' => PlanStatus.archived,
      _ => throw FormatException('Unknown plan status: $value'),
    };
  }
}

class PlanModel {
  const PlanModel({
    required this.id,
    required this.userId,
    required this.personalTopicId,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.tasks = const [],
  });

  final String id;
  final String userId;
  final String personalTopicId;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final PlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskModel> tasks;

  double get progress {
    if (tasks.isEmpty) return 0;
    return tasks.where((task) => task.status == TaskStatus.done).length *
        100 /
        tasks.length;
  }

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final taskJson = json['tasks'] as List<dynamic>? ?? const [];

    return PlanModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      personalTopicId: json['personal_topic_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      status: PlanStatus.fromDatabaseValue(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tasks: taskJson
          .map(
            (task) =>
                TaskModel.fromJson(Map<String, dynamic>.from(task as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'personal_topic_id': personalTopicId,
      'title': title,
      'description': description,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'status': status.toDatabaseValue(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
