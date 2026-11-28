import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../providers/sleep_provider.dart';
import '../../data/models/sleep_record_model.dart';

class SleepHistoryScreen extends StatelessWidget {
  const SleepHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Sử Giấc Ngủ')),
      body: Consumer<SleepProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = provider.records;

          if (records.isEmpty) {
            return const Center(
              child: Text('Bạn chưa có nhật ký giấc ngủ nào.'),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.nightlight_round,
                              color: AppTheme.accentCyan,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                TimeUtils.formatDateTime(record.sleepTime),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Sửa',
                              icon: const Icon(
                                Icons.edit,
                                color: AppTheme.accentCyan,
                              ),
                              onPressed: () => _editRecord(context, record),
                            ),
                            IconButton(
                              tooltip: 'Xóa',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deleteRecord(context, record),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          'Thức dậy: ${TimeUtils.formatDateTime(record.wakeTime)}',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Thời lượng ngủ: ${TimeUtils.formatDuration(record.durationHours)}',
                          style: const TextStyle(
                            color: AppTheme.softGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Số lần thức giấc: ${record.wakeUpCount}'),
                        Text('Đánh giá: ${record.feelingRating}/5 ⭐'),
                        if (record.note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Ghi chú: ${record.note}'),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteRecord(
    BuildContext context,
    SleepRecordModel record,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa nhật ký'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa nhật ký giấc ngủ này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && record.id != null && context.mounted) {
      await context.read<SleepProvider>().deleteSleepRecord(record.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa nhật ký giấc ngủ!')),
        );
      }
    }
  }

  Future<void> _editRecord(
    BuildContext context,
    SleepRecordModel record,
  ) async {
    final noteController = TextEditingController(text: record.note);
    final wakeCountController = TextEditingController(
      text: record.wakeUpCount.toString(),
    );

    int rating = record.feelingRating;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sửa nhật ký giấc ngủ'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'Ghi chú'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: wakeCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số lần thức giấc',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Đánh giá chất lượng ngủ'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          onPressed: () {
                            setDialogState(() => rating = star);
                          },
                          icon: Icon(
                            star <= rating ? Icons.star : Icons.star_border,
                            color: AppTheme.softAmber,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && context.mounted) {
      final wakeCount = int.tryParse(wakeCountController.text);

      if (wakeCount == null || wakeCount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số lần thức giấc không hợp lệ!')),
        );
      } else {
        final updatedRecord = SleepRecordModel(
          id: record.id,
          sleepTime: record.sleepTime,
          wakeTime: record.wakeTime,
          durationHours: record.durationHours,
          wakeUpCount: wakeCount,
          feelingRating: rating,
          note: noteController.text.trim(),
          isGoalMet: record.isGoalMet,
          createdAt: record.createdAt,
        );

        await context.read<SleepProvider>().updateSleepRecord(updatedRecord);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật nhật ký giấc ngủ!')),
          );
        }
      }
    }

    noteController.dispose();
    wakeCountController.dispose();
  }
}
