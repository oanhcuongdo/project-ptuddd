import 'package:flutter/material.dart';
import '../services/drill_timer_service.dart';

class TimerDisplay extends StatelessWidget {
  final String formattedTime;
  final double progress;
  final DrillTimerStatus status;
  final int currentSet;
  final int totalSets;

  const TimerDisplay({
    super.key,
    required this.formattedTime,
    required this.progress,
    required this.status,
    required this.currentSet,
    required this.totalSets,
  });

  Color get _statusColor {
    switch (status) {
      case DrillTimerStatus.running:
        return const Color(0xFF10B981);
      case DrillTimerStatus.resting:
        return const Color(0xFF38BDF8);
      case DrillTimerStatus.paused:
        return const Color(0xFFF59E0B);
      case DrillTimerStatus.completed:
        return const Color(0xFF22C55E);
      case DrillTimerStatus.idle:
        return const Color(0xFF10B981);
    }
  }

  String get _statusLabel {
    switch (status) {
      case DrillTimerStatus.running:
        return 'ĐANG TẬP LUYỆN';
      case DrillTimerStatus.resting:
        return 'NGHỈ GIẢI LAO';
      case DrillTimerStatus.paused:
        return 'TẠM DỪNG';
      case DrillTimerStatus.completed:
        return 'HOÀN THÀNH';
      case DrillTimerStatus.idle:
        return 'SẴN SÀNG';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _statusColor;

    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF161F30),
        boxShadow: [
          BoxShadow(
            color: activeColor.withOpacity(0.18),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 236,
            height: 236,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: activeColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                formattedTime,
                style: const TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hiệp $currentSet / $totalSets',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
