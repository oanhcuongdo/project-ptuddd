enum TaskStatus {
  todo,
  inProgress,
  done;

  String toDatabaseValue() {
    return switch (this) {
      TaskStatus.todo => 'todo',
      TaskStatus.inProgress => 'in_progress',
      TaskStatus.done => 'done',
    };
  }

  static TaskStatus fromDatabaseValue(String value) {
    return switch (value) {
      'todo' => TaskStatus.todo,
      'in_progress' => TaskStatus.inProgress,
      'done' => TaskStatus.done,
      _ => throw FormatException('Unknown task status: $value'),
    };
  }
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.planId,
    required this.userId,
    required this.title,
    required this.phase,
    this.description,
    this.dueDate,
    required this.status,
    required this.orderIndex,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String planId;
  final String userId;
  final String title;
  final String phase;
  final String? description;
  final DateTime? dueDate;
  final TaskStatus status;
  final int orderIndex;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final dueDate = json['due_date'] as String?;
    final completedAt = json['completed_at'] as String?;

    return TaskModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      phase: json['phase'] as String,
      description: json['description'] as String?,
      dueDate: dueDate == null ? null : DateTime.parse(dueDate),
      status: TaskStatus.fromDatabaseValue(json['status'] as String),
      orderIndex: json['order_index'] as int,
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'user_id': userId,
      'title': title,
      'phase': phase,
      'description': description,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'status': status.toDatabaseValue(),
      'order_index': orderIndex,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
