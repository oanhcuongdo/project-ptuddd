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
    required this.title,
    required this.phase,
    this.description,
    this.dueDate,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String planId;
  final String title;
  final String phase;
  final String? description;
  final DateTime? dueDate;
  final TaskStatus status;
  final DateTime createdAt;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final dueDate = json['due_date'] as String?;

    return TaskModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      title: json['title'] as String,
      phase: json['phase'] as String,
      description: json['description'] as String?,
      dueDate: dueDate == null ? null : DateTime.parse(dueDate),
      status: TaskStatus.fromDatabaseValue(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'title': title,
      'phase': phase,
      'description': description,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'status': status.toDatabaseValue(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
