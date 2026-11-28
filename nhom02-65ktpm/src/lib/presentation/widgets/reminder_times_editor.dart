import 'package:flutter/material.dart';

import '../../core/strings/auth_strings.dart';

/// Chỉnh danh sách giờ nhắc ("HH:mm"): xóa bằng nút x, thêm bằng TimePicker.
class ReminderTimesEditor extends StatelessWidget {
  const ReminderTimesEditor({
    super.key,
    required this.times,
    required this.onChanged,
    this.enabled = true,
  });

  static const int maxTimes = 6;

  final List<String> times;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  Future<void> _addTime(BuildContext context) async {
    if (times.length >= maxTimes) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(ProfileStrings.maxTimesReached)));
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final value = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    if (times.contains(value)) return;
    onChanged([...times, value]..sort());
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final time in times)
          InputChip(
            label: Text(time),
            avatar: const Icon(Icons.alarm, size: 18),
            isEnabled: enabled,
            onDeleted: () => onChanged(times.where((t) => t != time).toList()),
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text(ProfileStrings.addTime),
          onPressed: enabled ? () => _addTime(context) : null,
        ),
      ],
    );
  }
}
