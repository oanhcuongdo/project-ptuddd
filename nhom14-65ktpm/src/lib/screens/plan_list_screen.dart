import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/plan_model.dart';
import '../models/task_model.dart';
import '../services/planning_service.dart';
import 'plan_detail_screen.dart';

class PlanListScreen extends StatefulWidget {
  const PlanListScreen({
    super.key,
    required this.personalTopicId,
    this.service,
  });

  final String personalTopicId;
  final PlanningService? service;

  @override
  State<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends State<PlanListScreen> {
  late final PlanningService _service = widget.service ?? PlanningService();
  List<PlanModel> _plans = [];
  Object? _loadError;
  bool _isLoading = true;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final plans = await _service.getPlans(
        personalTopicId: widget.personalTopicId,
      );
      if (mounted) setState(() => _plans = plans);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showPlanForm({PlanModel? plan}) async {
    final result = await showDialog<_PlanFormData>(
      context: context,
      builder: (_) => _PlanFormDialog(plan: plan),
    );
    if (result == null || !mounted) return;

    setState(() => _isMutating = true);
    try {
      final now = DateTime.now().toUtc();
      final updatedPlan = PlanModel(
        id: plan?.id ?? '',
        userId: plan?.userId ?? '',
        personalTopicId: widget.personalTopicId,
        title: result.title,
        description: result.description,
        startDate: result.startDate,
        endDate: result.endDate,
        status: result.status,
        createdAt: plan?.createdAt ?? now,
        updatedAt: plan?.updatedAt ?? now,
        tasks: plan?.tasks ?? const [],
      );

      if (plan == null) {
        await _service.createPlan(updatedPlan);
      } else {
        await _service.updatePlan(updatedPlan);
      }

      if (!mounted) return;
      _showMessage(plan == null ? 'Đã tạo kế hoạch.' : 'Đã cập nhật kế hoạch.');
      await _loadPlans();
    } catch (error) {
      if (mounted) {
        _showMessage('Không thể lưu kế hoạch: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _deletePlan(PlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa kế hoạch?'),
        content: Text(
          'Kế hoạch "${plan.title}" và các công việc liên quan sẽ bị xóa.',
        ),
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
      await _service.deletePlan(planId: plan.id);
      if (!mounted) return;
      _showMessage('Đã xóa kế hoạch.');
      await _loadPlans();
    } catch (error) {
      if (mounted) {
        _showMessage('Không thể xóa kế hoạch: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
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
        title: const Text('Kế hoạch & tiến độ'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : _loadPlans,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isMutating ? null : () => _showPlanForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo kế hoạch'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _plans.isEmpty) {
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
                'Không tải được danh sách kế hoạch.\n$_loadError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadPlans,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlans,
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
                  _buildIntro(),
                  const SizedBox(height: 18),
                  if (_loadError != null)
                    _InlineError(message: 'Không thể làm mới: $_loadError'),
                  if (_plans.isEmpty)
                    _buildEmptyState()
                  else
                    ..._plans.map(_buildPlanCard),
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

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_note_rounded,
            color: AppColors.primaryAction,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lộ trình thực hiện đề tài',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_plans.length} kế hoạch',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            const Icon(
              Icons.event_available_rounded,
              size: 42,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có kế hoạch nào',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tạo kế hoạch đầu tiên để chia nhỏ các bước thực hiện đề tài.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isMutating ? null : () => _showPlanForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo kế hoạch'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(PlanModel plan) {
    final progress = plan.progress.clamp(0, 100).toDouble();
    final localizations = MaterialLocalizations.of(context);
    final dateRange = _formatDateRange(plan, localizations);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => PlanDetailScreen(plan: plan, service: _service),
            ),
          );
          if (mounted) await _loadPlans();
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _PlanStatusBadge(status: plan.status),
                  IconButton(
                    tooltip: 'Sửa kế hoạch',
                    onPressed: _isMutating
                        ? null
                        : () => _showPlanForm(plan: plan),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Xóa kế hoạch',
                    onPressed: _isMutating ? null : () => _deletePlan(plan),
                    color: AppColors.danger,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              if (plan.description?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  plan.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.date_range_rounded,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateRange,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tiến độ hoàn thành',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.primaryAction,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress / 100,
                minHeight: 7,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: AppColors.primaryBackground,
                color: AppColors.primaryAction,
              ),
              const SizedBox(height: 6),
              Text(
                '${plan.tasks.where((task) => task.status == TaskStatus.done).length}'
                '/${plan.tasks.length} công việc hoàn thành',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(PlanModel plan, MaterialLocalizations localizations) {
    if (plan.startDate == null && plan.endDate == null) {
      return 'Chưa thiết lập thời gian';
    }
    if (plan.startDate == null) {
      return 'Đến ${localizations.formatMediumDate(plan.endDate!)}';
    }
    if (plan.endDate == null) {
      return 'Từ ${localizations.formatMediumDate(plan.startDate!)}';
    }
    return '${localizations.formatMediumDate(plan.startDate!)}'
        ' – ${localizations.formatMediumDate(plan.endDate!)}';
  }
}

class _PlanFormData {
  const _PlanFormData({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final PlanStatus status;
}

class _PlanFormDialog extends StatefulWidget {
  const _PlanFormDialog({this.plan});

  final PlanModel? plan;

  @override
  State<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<_PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late PlanStatus _status;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plan?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.plan?.description ?? '',
    );
    _status = widget.plan?.status ?? PlanStatus.active;
    _startDate = widget.plan?.startDate;
    _endDate = widget.plan?.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? currentDate) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.plan == null ? 'Tạo kế hoạch' : 'Sửa kế hoạch'),
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
                    labelText: 'Tên kế hoạch *',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên kế hoạch.';
                    }
                    return null;
                  },
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
                DropdownButtonFormField<PlanStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: PlanStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_planStatusLabel(status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await _pickDate(_startDate);
                          if (date != null) setState(() => _startDate = date);
                        },
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          _startDate == null
                              ? 'Ngày bắt đầu'
                              : localizations.formatShortDate(_startDate!),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await _pickDate(_endDate);
                          if (date != null) setState(() => _endDate = date);
                        },
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text(
                          _endDate == null
                              ? 'Ngày kết thúc'
                              : localizations.formatShortDate(_endDate!),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
              _PlanFormData(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                startDate: _startDate,
                endDate: _endDate,
                status: _status,
              ),
            );
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class _PlanStatusBadge extends StatelessWidget {
  const _PlanStatusBadge({required this.status});

  final PlanStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _planStatusLabel(status),
        style: const TextStyle(
          color: AppColors.primaryAction,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _planStatusLabel(PlanStatus status) {
  return switch (status) {
    PlanStatus.active => 'Đang thực hiện',
    PlanStatus.completed => 'Hoàn thành',
    PlanStatus.archived => 'Đã lưu trữ',
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
