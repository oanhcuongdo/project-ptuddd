import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/nap_provider.dart';

class PowerNapScreen extends StatelessWidget {
  const PowerNapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final napProv = context.watch<NapProvider>();
    final isCompleted = napProv.isCompleted;

    return Scaffold(
      appBar: AppBar(title: const Text('Giấc Ngủ Ngắn (Power Nap)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceNavy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardNavy),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: AppTheme.accentCyan),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gợi ý: giấc ngủ ngắn 10–20 phút phù hợp với nhiều người trưởng thành (chỉ là tham khảo)',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'Chọn thời lượng giấc ngủ ngắn:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: AppConstants.napPresetsMinutes.map((minutes) {
                final isSelected = napProv.selectedPresetMinutes == minutes;
                return ChoiceChip(
                  label: Text('$minutes phút'),
                  selected: isSelected,
                  selectedColor: AppTheme.accentIndigo,
                  onSelected: (selected) {
                    if (selected) napProv.selectPreset(minutes);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: napProv.progress,
                    strokeWidth: 10,
                    backgroundColor: AppTheme.cardNavy,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.accentCyan,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      napProv.formattedRemainingTime,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted
                          ? 'Đã hết giờ ngủ ngắn'
                          : _statusMessage(napProv.status),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isCompleted
                            ? AppTheme.softGreen
                            : AppTheme.textMuted,
                        fontSize: isCompleted ? 16 : 13,
                        fontWeight: isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (napProv.status == NapStatus.running)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.softAmber,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(Icons.pause, color: Colors.black87),
                    label: const Text(
                      'Tạm dừng',
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                    onPressed: napProv.pauseTimer,
                  )
                else if (napProv.status == NapStatus.paused)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.softGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      'Tiếp tục',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onPressed: napProv.resumeTimer,
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.softGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      'Bắt đầu',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onPressed: napProv.startTimer,
                  ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Hủy'),
                  onPressed: napProv.cancelTimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusMessage(NapStatus status) {
    switch (status) {
      case NapStatus.notStarted:
        return 'Sẵn sàng bắt đầu';
      case NapStatus.running:
        return 'Đang trong giấc ngủ ngắn...';
      case NapStatus.paused:
        return 'Đang tạm dừng';
      case NapStatus.completed:
        return 'Đã hết giờ ngủ ngắn';
    }
  }
}
