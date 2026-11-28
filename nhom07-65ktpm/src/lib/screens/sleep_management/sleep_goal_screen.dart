import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/sleep_goal_model.dart';
import '../../providers/sleep_provider.dart';

class SleepGoalScreen extends StatefulWidget {
  const SleepGoalScreen({super.key});

  @override
  State<SleepGoalScreen> createState() => _SleepGoalScreenState();
}

class _SleepGoalScreenState extends State<SleepGoalScreen> {
  static const List<String> _weekdays = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  late TimeOfDay _bedtime;
  late TimeOfDay _wakeTime;
  late double _targetDuration;
  late Set<String> _activeDays;
  SleepGoalModel? _observedGoal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final goal = context.watch<SleepProvider>().goal;
    if (identical(goal, _observedGoal)) return;

    final previousGoal = _observedGoal;
    _observedGoal = goal;
    if (previousGoal != null &&
        previousGoal.bedtimeHour == goal.bedtimeHour &&
        previousGoal.bedtimeMinute == goal.bedtimeMinute &&
        previousGoal.wakeHour == goal.wakeHour &&
        previousGoal.wakeMinute == goal.wakeMinute &&
        previousGoal.targetDurationHours == goal.targetDurationHours &&
        previousGoal.activeDays == goal.activeDays) {
      return;
    }

    _bedtime = TimeOfDay(hour: goal.bedtimeHour, minute: goal.bedtimeMinute);
    _wakeTime = TimeOfDay(hour: goal.wakeHour, minute: goal.wakeMinute);
    _targetDuration = goal.targetDurationHours;
    _activeDays = goal.activeDays
        .split(',')
        .map((day) => day.trim())
        .where(_weekdays.contains)
        .toSet();
    if (_activeDays.isEmpty) {
      _activeDays.addAll(_weekdays);
    }
  }

  Future<void> _selectBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
      helpText: 'CHỌN GIỜ ĐI NGỦ MỤC TIÊU',
    );
    if (picked != null) {
      setState(() {
        _bedtime = picked;
        _recalculateDuration();
      });
    }
  }

  Future<void> _selectWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      helpText: 'CHỌN GIỜ THỨC DẬY MỤC TIÊU',
    );
    if (picked != null) {
      setState(() {
        _wakeTime = picked;
        _recalculateDuration();
      });
    }
  }

  void _recalculateDuration() {
    int startMinutes = _bedtime.hour * 60 + _bedtime.minute;
    int endMinutes = _wakeTime.hour * 60 + _wakeTime.minute;

    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60; // Qua đêm
    }

    _targetDuration = (endMinutes - startMinutes) / 60.0;
  }

  void _toggleActiveDay(String day, bool selected) {
    if (selected) {
      setState(() => _activeDays.add(day));
      return;
    }

    if (_activeDays.length == 1 && _activeDays.contains(day)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chọn ít nhất 1 ngày')));
      return;
    }

    setState(() => _activeDays.remove(day));
  }

  Future<void> _saveGoal() async {
    await context.read<SleepProvider>().updateGoal(
      bedtimeHour: _bedtime.hour,
      bedtimeMinute: _bedtime.minute,
      wakeHour: _wakeTime.hour,
      wakeMinute: _wakeTime.minute,
      targetDurationHours: _targetDuration,
      activeDays: _weekdays.where(_activeDays.contains).join(','),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật mục tiêu giấc ngủ thành công!'),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _setReminderEnabled(bool value) async {
    await context.read<SleepProvider>().setReminderEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Đã bật nhắc giờ đi ngủ' : 'Đã tắt nhắc giờ đi ngủ',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thiết Lập Mục Tiêu Ngủ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xây dựng lịch ngủ cố định giúp đồng hồ sinh học cơ thể ổn định và thức dậy tràn đầy năng lượng.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // Select Bedtime
            _buildTimePickerCard(
              title: 'Giờ đi ngủ mục tiêu',
              subtitle: 'Thời điểm bắt đầu lên giường ngủ',
              timeStr: TimeUtils.formatTime(_bedtime.hour, _bedtime.minute),
              icon: Icons.nightlight_round,
              color: AppTheme.accentCyan,
              onTap: _selectBedtime,
            ),
            const SizedBox(height: 16),
            // Select Wake Time
            _buildTimePickerCard(
              title: 'Giờ thức dậy mục tiêu',
              subtitle: 'Thời điểm thức dậy đón ngày mới',
              timeStr: TimeUtils.formatTime(_wakeTime.hour, _wakeTime.minute),
              icon: Icons.wb_sunny_outlined,
              color: AppTheme.softAmber,
              onTap: _selectWakeTime,
            ),
            const SizedBox(height: 20),
            // Target Duration Preview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thời lượng ngủ mục tiêu:',
                      style: TextStyle(fontSize: 15),
                    ),
                    Text(
                      TimeUtils.formatDuration(_targetDuration),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ngày áp dụng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _weekdays.map((day) {
                        return FilterChip(
                          label: Text(day),
                          selected: _activeDays.contains(day),
                          onSelected: (selected) =>
                              _toggleActiveDay(day, selected),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Nhắc giờ đi ngủ'),
              value: context.watch<SleepProvider>().goal.isReminderEnabled,
              onChanged: _setReminderEnabled,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Lưu Mục Tiêu Giấc Ngủ'),
                onPressed: _saveGoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerCard({
    required String title,
    required String subtitle,
    required String timeStr,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            timeStr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
