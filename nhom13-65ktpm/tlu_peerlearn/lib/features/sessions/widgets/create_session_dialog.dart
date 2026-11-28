import 'package:flutter/material.dart';
import '../models/tutoring_session.dart';

class CreateSessionDialog extends StatefulWidget {
  final TutoringSession? initialSession;
  final Future<void> Function({
    required String title,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required String mode,
    String? locationOrLink,
    String? plannedContent,
  }) onSubmit;

  const CreateSessionDialog({
    super.key,
    this.initialSession,
    required this.onSubmit,
  });

  @override
  State<CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<CreateSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _contentController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  int _durationMinutes = 100;
  String _mode = 'offline';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSession;
    if (s != null) {
      _titleController.text = s.title;
      _locationController.text = s.locationOrLink ?? '';
      _contentController.text = s.plannedContent ?? '';
      _startDate = s.scheduledStart;
      _startTime = TimeOfDay.fromDateTime(s.scheduledStart);
      _mode = s.mode;
      final diff = s.scheduledEnd.difference(s.scheduledStart).inMinutes;
      if (diff == 50 || diff == 100 || diff == 150) {
        _durationMinutes = diff;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = startDateTime.add(Duration(minutes: _durationMinutes));

    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(
        title: _titleController.text.trim(),
        scheduledStart: startDateTime,
        scheduledEnd: endDateTime,
        mode: _mode,
        locationOrLink: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        plannedContent: _contentController.text.trim().isEmpty
            ? null
            : _contentController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo lịch học: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialSession != null
            ? 'Chỉnh sửa buổi học'
            : 'Lên lịch buổi học mới (SES-01)',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề buổi học *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_note),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tiêu đề buổi học'
                    : null,
              ),
              const SizedBox(height: 12),

              // Mode toggle (Offline / Online)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'offline',
                    label: Text('Trực tiếp (Offline)'),
                    icon: Icon(Icons.meeting_room_outlined),
                  ),
                  ButtonSegment(
                    value: 'online',
                    label: Text('Trực tuyến (Online)'),
                    icon: Icon(Icons.video_call_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (set) => setState(() => _mode = set.first),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: _mode == 'offline'
                      ? 'Địa điểm (VD: Thư viện TLU / P301 A4)'
                      : 'Link phòng học (Google Meet / Zoom)',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_mode == 'offline' ? Icons.place : Icons.link),
                ),
              ),
              const SizedBox(height: 12),

              // Date & Time pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(_startTime.format(context)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (picked != null) setState(() => _startTime = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Duration selector
              DropdownButtonFormField<int>(
                initialValue: _durationMinutes,
                decoration: const InputDecoration(
                  labelText: 'Thời lượng dự kiến',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 50, child: Text('1 tiết (50 phút)')),
                  DropdownMenuItem(value: 100, child: Text('2 tiết (100 phút)')),
                  DropdownMenuItem(value: 150, child: Text('3 tiết (150 phút)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _durationMinutes = val);
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _contentController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Lưu lịch học'),
        ),
      ],
    );
  }
}
