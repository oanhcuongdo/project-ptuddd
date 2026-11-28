import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/nap_provider.dart';

class PowerNapScreen extends StatelessWidget {
  const PowerNapScreen({super.key});

  void _showCustomDurationDialog(BuildContext context, NapProvider napProv) {
    if (napProv.isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng tạm dừng hoặc hủy trước khi đổi thời gian.'),
        ),
      );
      return;
    }

    int tempMinutes = napProv.selectedPresetMinutes;
    final controller = TextEditingController(text: tempMinutes.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Chọn Thời Gian Ngủ Ngắn'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$tempMinutes phút',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: tempMinutes > 30
                          ? AppTheme.softAmber
                          : AppTheme.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: tempMinutes.clamp(1, 120).toDouble(),
                    min: 1,
                    max: 120,
                    divisions: 119,
                    activeColor: tempMinutes > 30
                        ? AppTheme.softAmber
                        : AppTheme.accentIndigo,
                    inactiveColor: AppTheme.cardNavy,
                    label: '$tempMinutes phút',
                    onChanged: (val) {
                      setDialogState(() {
                        tempMinutes = val.round();
                        controller.text = tempMinutes.toString();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Hoặc nhập số phút (1 - 180)',
                      suffixText: 'phút',
                      filled: true,
                      fillColor: AppTheme.surfaceNavy,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed >= 1 && parsed <= 180) {
                        setDialogState(() {
                          tempMinutes = parsed;
                        });
                      }
                    },
                  ),
                  if (tempMinutes > 30) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.softAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.softAmber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.softAmber,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Không khuyến khích ngủ trưa quá 30 phút vì dễ gây uể oải khi tỉnh dậy và ảnh hưởng giấc ngủ tối.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.softAmber,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  final parsed = int.tryParse(controller.text) ?? tempMinutes;
                  final clamped = parsed.clamp(1, 180);
                  napProv.selectCustomDuration(clamped);
                  Navigator.pop(ctx);
                },
                child: const Text('Xác nhận'),
              ),
            ],
          );
        },
      ),
    );
  }

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
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ...AppConstants.napPresetsMinutes.map((minutes) {
                  final isSelected = napProv.selectedPresetMinutes == minutes;
                  return ChoiceChip(
                    label: Text('$minutes phút'),
                    selected: isSelected,
                    selectedColor: AppTheme.accentIndigo,
                    onSelected: (selected) {
                      if (selected) napProv.selectPreset(minutes);
                    },
                  );
                }),
                Builder(
                  builder: (context) {
                    final isCustomSelected = !AppConstants.napPresetsMinutes
                        .contains(napProv.selectedPresetMinutes);
                    return ChoiceChip(
                      avatar: Icon(
                        Icons.tune,
                        size: 16,
                        color: isCustomSelected
                            ? Colors.white
                            : AppTheme.accentCyan,
                      ),
                      label: Text(
                        isCustomSelected
                            ? 'Tùy chỉnh (${napProv.selectedPresetMinutes}p)'
                            : 'Tùy chỉnh...',
                      ),
                      selected: isCustomSelected,
                      selectedColor: AppTheme.accentIndigo,
                      onSelected: (_) => _showCustomDurationDialog(context, napProv),
                    );
                  },
                ),
              ],
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
