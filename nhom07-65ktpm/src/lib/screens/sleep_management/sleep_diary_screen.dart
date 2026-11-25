import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../providers/sleep_provider.dart';

class SleepDiaryScreen extends StatefulWidget {
  const SleepDiaryScreen({super.key});

  @override
  State<SleepDiaryScreen> createState() => _SleepDiaryScreenState();
}

class _SleepDiaryScreenState extends State<SleepDiaryScreen> {
  DateTime _sleepTime = DateTime.now().subtract(const Duration(hours: 7, minutes: 30));
  DateTime _wakeTime = DateTime.now();
  int _feelingRating = 4;
  int _wakeUpCount = 0;
  final TextEditingController _noteController = TextEditingController();

  Future<void> _selectDateTime(bool isSleep) async {
    final current = isSleep ? _sleepTime : _wakeTime;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;

    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isSleep) {
        _sleepTime = selected;
      } else {
        _wakeTime = selected;
      }
    });
  }

  Future<void> _saveDiary() async {
    if (_wakeTime.isBefore(_sleepTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời điểm thức dậy phải sau thời điểm đi ngủ!')),
      );
      return;
    }

    await context.read<SleepProvider>().addSleepRecord(
          sleepTime: _sleepTime,
          wakeTime: _wakeTime,
          feelingRating: _feelingRating,
          wakeUpCount: _wakeUpCount,
          note: _noteController.text.trim(),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu nhật ký giấc ngủ thành công!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final durationHours = _wakeTime.difference(_sleepTime).inMinutes / 60.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi Nhật Ký Giấc Ngủ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Time Selectors
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.nightlight_round, color: AppTheme.accentCyan),
                      title: const Text('Thời điểm bắt đầu ngủ:'),
                      subtitle: Text(TimeUtils.formatDateTime(_sleepTime)),
                      trailing: const Icon(Icons.edit, size: 18),
                      onTap: () => _selectDateTime(true),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny_outlined, color: AppTheme.softAmber),
                      title: const Text('Thời điểm thức dậy:'),
                      subtitle: Text(TimeUtils.formatDateTime(_wakeTime)),
                      trailing: const Icon(Icons.edit, size: 18),
                      onTap: () => _selectDateTime(false),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng thời gian ngủ:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            TimeUtils.formatDuration(durationHours),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.softGreen, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Wake-up count & Feeling Rating
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Số lần thức giấc giữa đêm:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _wakeUpCount > 0 ? () => setState(() => _wakeUpCount--) : null,
                        ),
                        Text('$_wakeUpCount lần', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _wakeUpCount++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Mức độ tỉnh táo / Cảm nhận sau khi thức dậy:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          icon: Icon(
                            star <= _feelingRating ? Icons.star : Icons.star_border,
                            color: AppTheme.softAmber,
                            size: 32,
                          ),
                          onPressed: () => setState(() => _feelingRating = star),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Optional Note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú thêm (uống cafe, tập thể dục, mơ...)',
                filled: true,
                fillColor: AppTheme.surfaceNavy,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 4. Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Lưu Nhật Ký Vào Hệ Thống'),
                onPressed: _saveDiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
