import 'package:flutter/material.dart';
import '../services/drill_timer_service.dart';

class TimerControls extends StatelessWidget {
  final DrillTimerStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onNextSet;
  final VoidCallback onSkipRest;
  final VoidCallback onFinishEarly;

  const TimerControls({
    super.key,
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onNextSet,
    required this.onSkipRest,
    required this.onFinishEarly,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (status != DrillTimerStatus.idle) ...[
              _SecondaryCircleButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Làm lại',
                onPressed: onReset,
              ),
              const SizedBox(width: 20),
            ],
            _buildPrimaryButton(),
            if (status != DrillTimerStatus.idle &&
                status != DrillTimerStatus.completed) ...[
              const SizedBox(width: 20),
              _SecondaryCircleButton(
                icon: status == DrillTimerStatus.resting
                    ? Icons.fast_forward_rounded
                    : Icons.skip_next_rounded,
                tooltip: status == DrillTimerStatus.resting
                    ? 'Bỏ qua nghỉ'
                    : 'Hết hiệp / Chuyển bài',
                onPressed: status == DrillTimerStatus.resting
                    ? onSkipRest
                    : onNextSet,
              ),
            ],
          ],
        ),
        if (status == DrillTimerStatus.running ||
            status == DrillTimerStatus.paused ||
            status == DrillTimerStatus.resting) ...[
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onFinishEarly,
            icon: const Icon(
              Icons.stop_circle_outlined,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            label: const Text(
              'Kết thúc buổi tập',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryButton() {
    if (status == DrillTimerStatus.running ||
        status == DrillTimerStatus.resting) {
      return _ActionButton(
        icon: Icons.pause_rounded,
        label: 'TẠM DỪNG',
        color: const Color(0xFFF59E0B),
        textColor: const Color(0xFF000000),
        onPressed: onPause,
      );
    }

    if (status == DrillTimerStatus.paused) {
      return _ActionButton(
        icon: Icons.play_arrow_rounded,
        label: 'TIẾP TỤC',
        color: const Color(0xFF10B981),
        textColor: const Color(0xFF000000),
        onPressed: onResume,
      );
    }

    return _ActionButton(
      icon: Icons.play_arrow_rounded,
      label: status == DrillTimerStatus.completed ? 'TẬP LẠI' : 'BẮT ĐẦU',
      color: const Color(0xFF22C55E),
      textColor: const Color(0xFF000000),
      onPressed: onStart,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28, color: textColor),
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 4,
      ),
    );
  }
}

class _SecondaryCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _SecondaryCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFF1E293B),
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              icon,
              color: const Color(0xFFF8FAFC),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
