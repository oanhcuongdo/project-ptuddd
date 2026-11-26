import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/meet_session_model.dart';
import '../providers/chat_provider.dart';
import '../styles/chat_styles.dart';

/// Hộp thoại dành cho Chủ phòng & Trợ giảng hẹn lịch hoặc mở ngay buổi học Video Call Meet.
class ScheduleMeetDialog extends StatefulWidget {
  final ConversationModel room;
  final String hostId;
  final String hostName;

  const ScheduleMeetDialog({
    super.key,
    required this.room,
    required this.hostId,
    required this.hostName,
  });

  @override
  State<ScheduleMeetDialog> createState() => _ScheduleMeetDialogState();
}

class _ScheduleMeetDialogState extends State<ScheduleMeetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  bool _startImmediately = true;
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(minutes: 30)),
  );
  int _minMinutes = 15;
  bool _isSaving = false;

  static const _minuteChoices = [
    (minutes: 1, label: '1 phút (Demo)'),
    (minutes: 5, label: '5 phút'),
    (minutes: 10, label: '10 phút'),
    (minutes: 15, label: '15 phút'),
    (minutes: 20, label: '20 phút'),
    (minutes: 30, label: '30 phút'),
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Luyện nói cùng ${widget.room.name}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null && mounted) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null && mounted) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final scheduledAt = _startImmediately
        ? DateTime.now()
        : DateTime(
            _scheduledDate.year,
            _scheduledDate.month,
            _scheduledDate.day,
            _scheduledTime.hour,
            _scheduledTime.minute,
          );

    final created = await context.read<ChatProvider>().scheduleMeetSession(
          conversationId: widget.room.id,
          roomName: widget.room.name,
          hostId: widget.hostId,
          hostName: widget.hostName,
          title: _titleController.text.trim(),
          scheduledAt: scheduledAt,
          minMinutes: _minMinutes,
          startImmediately: _startImmediately,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (created != null) {
      Navigator.of(context).pop<MeetSessionModel>(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_scheduledDate.day.toString().padLeft(2, '0')}/${_scheduledDate.month.toString().padLeft(2, '0')}/${_scheduledDate.year}';
    final timeStr =
        '${_scheduledTime.hour.toString().padLeft(2, '0')}:${_scheduledTime.minute.toString().padLeft(2, '0')}';

    return Dialog(
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Xanh Ngọc
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [ChatStyles.tealDark, ChatStyles.tealPrimary],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.video_call_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hẹn lịch học Video Call Meet',
                          style: TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Thành viên học đủ số phút quy định sẽ tự động 🔥 +1 chuỗi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chủ đề / Tên buổi học *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'VD: Luyện phản xạ giao tiếp tối nay',
                        prefixIcon: const Icon(
                          Icons.title_rounded,
                          size: 19,
                          color: ChatStyles.tealPrimary,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFB),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFDCE7EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFDCE7EA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: ChatStyles.tealPrimary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Nhập tên buổi học tối thiểu 3 ký tự'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Thời điểm diễn ra',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ModeOption(
                            icon: Icons.sensors_rounded,
                            label: 'Mở ngay bây giờ',
                            selected: _startImmediately,
                            onTap: () =>
                                setState(() => _startImmediately = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ModeOption(
                            icon: Icons.event_outlined,
                            label: 'Hẹn giờ học',
                            selected: !_startImmediately,
                            onTap: () =>
                                setState(() => _startImmediately = false),
                          ),
                        ),
                      ],
                    ),

                    if (!_startImmediately) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: Color(0xFFDCE7EA)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.calendar_today_rounded,
                                size: 15,
                                color: ChatStyles.tealPrimary,
                              ),
                              label: Text(dateStr),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickTime,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: Color(0xFFDCE7EA)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: ChatStyles.tealPrimary,
                              ),
                              label: Text(timeStr),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    const Text(
                      'Số phút tối thiểu trong Meet để lên chuỗi phòng 🔥',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _minuteChoices.map((c) {
                        final active = _minMinutes == c.minutes;
                        return InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => setState(() => _minMinutes = c.minutes),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? ChatStyles.tealPrimary
                                  : const Color(0xFFF8FAFB),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: active
                                    ? ChatStyles.tealPrimary
                                    : const Color(0xFFDCE7EA),
                              ),
                            ),
                            child: Text(
                              c.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: ChatStyles.tealPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _startImmediately
                                ? Icons.videocam_rounded
                                : Icons.event_available_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _startImmediately ? 'Mở phòng Meet ngay' : 'Tạo lịch học',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ChatStyles.tealSoftBg : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? ChatStyles.tealPrimary : const Color(0xFFDCE7EA),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? ChatStyles.tealPrimary : AppColors.textMuted,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                  color: selected ? ChatStyles.tealDark : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
