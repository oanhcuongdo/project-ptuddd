import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/plan_model.dart';
import '../models/task_model.dart';

class PlanningServiceException implements Exception {
  const PlanningServiceException({
    required this.operation,
    required this.message,
    this.code,
    this.details,
  });

  final String operation;
  final String message;
  final String? code;
  final String? details;

  @override
  String toString() {
    final errorCode = code == null ? '' : ' ($code)';
    final errorDetails = details == null ? '' : ' Details: $details';
    return '$operation failed$errorCode: $message$errorDetails';
  }
}

class PlanningService {
  PlanningService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required for planning operations.');
    }
    return user.id;
  }

  Future<List<PlanModel>> getPlans({required String personalTopicId}) async {
    final userId = _currentUserId;
    final rows = await _execute<List<Map<String, dynamic>>>(
      'Load plans',
      () => _client
          .from('plans')
          .select('*, tasks(*)')
          .eq('personal_topic_id', personalTopicId)
          .eq('user_id', userId),
    );

    return rows
        .map((row) => PlanModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<PlanModel> createPlan(PlanModel plan) async {
    final userId = _currentUserId;
    final values = _planValues(plan)..['user_id'] = userId;
    final row = await _execute<Map<String, dynamic>>(
      'Create plan',
      () => _client.from('plans').insert(values).select().single(),
    );
    return PlanModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<PlanModel> updatePlan(PlanModel plan) async {
    final userId = _currentUserId;
    final row = await _execute<Map<String, dynamic>>(
      'Update plan',
      () => _client
          .from('plans')
          .update(_planValues(plan))
          .eq('id', plan.id)
          .eq('user_id', userId)
          .select()
          .single(),
    );
    return PlanModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deletePlan({required String planId}) async {
    final userId = _currentUserId;
    final rows = await _execute<List<Map<String, dynamic>>>(
      'Delete plan',
      () => _client
          .from('plans')
          .delete()
          .eq('id', planId)
          .eq('user_id', userId)
          .select('id'),
    );
    if (rows.isEmpty) {
      throw StateError(
        'Plan not found or the user is not allowed to delete it.',
      );
    }
  }

  Future<List<TaskModel>> getTasks({required String planId}) async {
    final userId = _currentUserId;
    final rows = await _execute<List<Map<String, dynamic>>>(
      'Load tasks',
      () => _client
          .from('tasks')
          .select()
          .eq('plan_id', planId)
          .eq('user_id', userId)
          .order('phase')
          .order('order_index'),
    );

    return rows
        .map((row) => TaskModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<TaskModel> createTask(TaskModel task) async {
    final userId = _currentUserId;
    final values = _taskValues(task)..['user_id'] = userId;
    final row = await _execute<Map<String, dynamic>>(
      'Create task',
      () => _client.from('tasks').insert(values).select().single(),
    );
    return TaskModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final userId = _currentUserId;
    final row = await _execute<Map<String, dynamic>>(
      'Update task',
      () => _client
          .from('tasks')
          .update(_taskValues(task))
          .eq('id', task.id)
          .eq('user_id', userId)
          .select()
          .single(),
    );
    return TaskModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteTask({required String taskId}) async {
    final userId = _currentUserId;
    final rows = await _execute<List<Map<String, dynamic>>>(
      'Delete task',
      () => _client
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', userId)
          .select('id'),
    );
    if (rows.isEmpty) {
      throw StateError(
        'Task not found or the user is not allowed to delete it.',
      );
    }
  }

  Future<TaskModel> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
  }) async {
    final userId = _currentUserId;
    final row = await _execute<Map<String, dynamic>>(
      'Update task status',
      () => _client
          .from('tasks')
          .update({
            'status': status.toDatabaseValue(),
            'completed_at': status == TaskStatus.done
                ? DateTime.now().toUtc().toIso8601String()
                : null,
          })
          .eq('id', taskId)
          .eq('user_id', userId)
          .select()
          .single(),
    );
    return TaskModel.fromJson(Map<String, dynamic>.from(row));
  }

  Map<String, dynamic> _planValues(PlanModel plan) {
    return {
      'personal_topic_id': plan.personalTopicId,
      'title': plan.title,
      'description': plan.description,
      'start_date': plan.startDate?.toIso8601String().split('T').first,
      'end_date': plan.endDate?.toIso8601String().split('T').first,
      'status': plan.status.toDatabaseValue(),
    };
  }

  Map<String, dynamic> _taskValues(TaskModel task) {
    return {
      'plan_id': task.planId,
      'phase': task.phase,
      'title': task.title,
      'description': task.description,
      'due_date': task.dueDate?.toIso8601String().split('T').first,
      'status': task.status.toDatabaseValue(),
      'order_index': task.orderIndex,
      'completed_at': task.completedAt?.toUtc().toIso8601String(),
    };
  }

  Future<T> _execute<T>(String operation, Future<T> Function() request) async {
    try {
      return await request();
    } on PostgrestException catch (error) {
      throw PlanningServiceException(
        operation: operation,
        message: error.message,
        code: error.code,
        details: error.details?.toString(),
      );
    }
  }
}
