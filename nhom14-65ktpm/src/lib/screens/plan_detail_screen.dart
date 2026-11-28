import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/plan_model.dart';
import '../models/task_model.dart';
import '../services/planning_service.dart';

class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({super.key, required this.plan, this.service});

  final PlanModel plan;
  final PlanningService? service;

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late final PlanningService _service = widget.service ?? PlanningService();
  List<TaskModel> _tasks = [];
  Object? _loadError;
  bool _isLoading = true;
  bool _isMutating = false;

  int get _completedCount =>
      _tasks.where((task) => task.status == TaskStatus.done).length;

  double get _progress =>
      _tasks.isEmpty ? 0 : _completedCount * 100 / _tasks.length;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final tasks = await _service.getTasks(planId: widget.plan.id);
      if (mounted) setState(() => _tasks = tasks);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showTaskForm({TaskModel? task}) async {
    final result = await showDialog<_TaskFormData>(
      context: context,
      builder: (_) => _TaskFormDialog(task: task),
    );
    if (result == null || !mounted) return;

    setState(() => _isMutating = true);
    try {
      final now = DateTime.now().toUtc();
      final updatedTask = TaskModel(
        id: task?.id ?? '',
        planId: widget.plan.id,
        userId: task?.userId ?? '',
        phase: result.phase,
        title: result.title,
        description: result.description,
        dueDate: result.dueDate,
        status: task?.status ?? TaskStatus.todo,
        orderIndex: result.orderIndex,
        completedAt: task?.completedAt,
        createdAt: task?.createdAt ?? now,
        updatedAt: task?.updatedAt ?? now,
      );

      final saved = task == null
          ? await _service.createTask(updatedTask)
          : await _service.updateTask(updatedTask);
      if (!mounted) return;

      setState(() {
        if (task == null) {
          _tasks = [..._tasks, saved]..sort(_compareTasks);
        } else {
          _replaceTask(saved);
        }
      });
      _showMessage(
        task == null ? 'Đã thêm công việc.' : 'Đã cập nhật công việc.',
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Không thể lưu công việc: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _updateStatus(TaskModel task, TaskStatus status) async {
    if (status == task.status) return;

    setState(() => _isMutating = true);
    try {
      final updated = await _service.updateTaskStatus(
        taskId: task.id,
        status: status,
      );
      if (!mounted) return;
      setState(() => _replaceTask(updated));
      _showMessage('Đã cập nhật trạng thái công việc.');
    } catch (error) {
      if (mounted) {
        _showMessage('Không thể cập nhật trạng thái: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: Text('Bạn có chắc muốn xóa "${task.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isMutating = true);
    try {
      await _service.deleteTask(taskId: task.id);
      if (!mounted) return;
      setState(() => _tasks.removeWhere((item) => item.id == task.id));
      _showMessage('Đã xóa công việc.');
    } catch (error) {
      if (mounted) {
        _showMessage('Không thể xóa công việc: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _replaceTask(TaskModel updated) {
    _tasks =
        _tasks.map((task) => task.id == updated.id ? updated : task).toList()
          ..sort(_compareTasks);
  }

  int _compareTasks(TaskModel first, TaskModel second) {
    final phaseComparison = first.phase.compareTo(second.phase);
    return phaseComparison != 0
        ? phaseComparison
        : first.orderIndex.compareTo(second.orderIndex);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.primaryAction,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: const Text('Chi tiết kế hoạch'),
        actions: [
          IconButton(
            tooltip: 'Tải lại công việc',
            onPressed: _isLoading ? null : _loadTasks,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isMutating ? null : () => _showTaskForm(),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Thêm công việc'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.danger,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Không tải được danh sách công việc.\n$_loadError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadTasks,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPlanSummary(),
                  const SizedBox(height: 18),
                  if (_loadError != null)
                    _InlineError(message: 'Không thể làm mới: $_loadError'),
                  if (_tasks.isEmpty)
                    _buildEmptyState()
                  else
                    ..._buildPhaseGroups(),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummary() {
    final progress = _progress.clamp(0, 100).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.plan.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.plan.description?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                widget.plan.description!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tiến độ công việc',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.primaryAction,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: AppColors.primaryBackground,
              color: AppColors.primaryAction,
            ),
            const SizedBox(height: 8),
            Text(
              '$_completedCount / ${_tasks.length} công việc hoàn thành',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPhaseGroups() {
    final groupedTasks = <String, List<TaskModel>>{};
    for (final task in _tasks) {
      groupedTasks.putIfAbsent(task.phase, () => []).add(task);
    }

    return groupedTasks.entries.map((entry) {
      final completed = entry.value
          .where((task) => task.status == TaskStatus.done)
          .length;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          leading: const CircleAvatar(
            backgroundColor: AppColors.primaryBackground,
            child: Icon(
              Icons.view_kanban_outlined,
              color: AppColors.primaryAction,
              size: 20,
            ),
          ),
          title: Text(
            entry.key,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '$completed/${entry.value.length} công việc hoàn thành',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          children: entry.value.map(_buildTaskCard).toList(),
        ),
      );
    }).toList();
  }

  Widget _buildTaskCard(TaskModel task) {
    final localizations = MaterialLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<TaskStatus>(
                  enabled: !_isMutating,
                  tooltip: 'Đổi trạng thái',
                  onSelected: (status) => _updateStatus(task, status),
                  itemBuilder: (context) => TaskStatus.values
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(_taskStatusLabel(status)),
                        ),
                      )
                      .toList(),
                  child: _TaskStatusBadge(status: task.status),
                ),
              ],
            ),
            if (task.description?.isNotEmpty == true) ...[
              const SizedBox(height: 5),
              Text(
                task.description!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  task.dueDate == null
                      ? 'Chưa đặt thời hạn'
                      : localizations.formatMediumDate(task.dueDate!),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '#${task.orderIndex}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _isMutating
                        ? null
                        : () => _showTaskForm(task: task),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Sửa'),
                  ),
                  TextButton.icon(
                    onPressed: _isMutating ? null : () => _deleteTask(task),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Xóa'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
        child: Column(
          children: [
            const Icon(
              Icons.checklist_rounded,
              size: 42,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có công việc trong kế hoạch',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thêm công việc đầu tiên và chia lộ trình theo từng giai đoạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isMutating ? null : () => _showTaskForm(),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Thêm công việc'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskFormData {
  const _TaskFormData({
    required this.title,
    required this.phase,
    required this.description,
    required this.dueDate,
    required this.orderIndex,
  });

  final String title;
  final String phase;
  final String? description;
  final DateTime? dueDate;
  final int orderIndex;
}

class _TaskFormDialog extends StatefulWidget {
  const _TaskFormDialog({this.task});

  final TaskModel? task;

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _phaseController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _orderController;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _phaseController = TextEditingController(text: widget.task?.phase ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _orderController = TextEditingController(
      text: widget.task?.orderIndex.toString() ?? '0',
    );
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _phaseController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.task == null ? 'Thêm công việc' : 'Sửa công việc'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Tên công việc *',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tên công việc.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phaseController,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Giai đoạn *',
                    hintText: 'Ví dụ: Phân tích yêu cầu',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập giai đoạn.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thứ tự trong giai đoạn',
                  ),
                  validator: (value) {
                    if (int.tryParse(value ?? '') == null) {
                      return 'Vui lòng nhập số thứ tự hợp lệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDueDate,
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: Text(
                          _dueDate == null
                              ? 'Chọn thời hạn'
                              : localizations.formatMediumDate(_dueDate!),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        tooltip: 'Xóa thời hạn',
                        onPressed: () => setState(() => _dueDate = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _TaskFormData(
                title: _titleController.text.trim(),
                phase: _phaseController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                dueDate: _dueDate,
                orderIndex: int.parse(_orderController.text),
              ),
            );
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class _TaskStatusBadge extends StatelessWidget {
  const _TaskStatusBadge({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TaskStatus.todo => AppColors.textSecondary,
      TaskStatus.inProgress => AppColors.secondary,
      TaskStatus.done => AppColors.primaryAction,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status == TaskStatus.todo
            ? AppColors.surfaceAlt
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        _taskStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _taskStatusLabel(TaskStatus status) {
  return switch (status) {
    TaskStatus.todo => 'Chưa thực hiện',
    TaskStatus.inProgress => 'Đang thực hiện',
    TaskStatus.done => 'Hoàn thành',
  };
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(message, style: const TextStyle(color: AppColors.danger)),
    );
  }
}
