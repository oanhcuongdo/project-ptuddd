import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/conversation_model.dart';

/// Huy hiệu "đốm lửa" riêng cho từng phòng chat (cơ chế giống chuỗi TikTok):
/// - Ban đầu = 0 (màu xám)
/// - Nhắn 1 tin trong ngày -> sáng rực màu cam (+1 ngày)
/// - Sang ngày mới chưa nhắn -> cảnh báo sắp mất chuỗi
/// - Quên 1 ngày trọn vẹn -> tự reset về 0
class RoomStreakBadge extends StatelessWidget {
  final ConversationModel room;
  final bool compact;

  const RoomStreakBadge({
    super.key,
    required this.room,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final streak = room.effectiveRoomStreak();
    final isLitToday = room.isStreakLitToday();
    final isAtRisk = room.isStreakAtRisk();
    final isLost = room.isStreakLost();

    late final Color bgColor;
    late final Color borderColor;
    late final Color iconColor;
    late final Color textColor;
    late final String tooltip;

    if (isLitToday) {
      bgColor = AppColors.streakBg;
      borderColor = const Color(0xFFFDBA74);
      iconColor = AppColors.streakOrange;
      textColor = const Color(0xFFC2410C);
      tooltip =
          'Đã thắp lửa hôm nay ($streak ngày liên tiếp • Kỷ lục: ${room.bestStreak} ngày)';
    } else if (isAtRisk) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFCD34D);
      iconColor = const Color(0xFFD97706);
      textColor = const Color(0xFFB45309);
      tooltip =
          'Chuỗi $streak ngày đang chờ giữ lửa! Nhắn ít nhất 1 tin hôm nay kẻo mất chuỗi.';
    } else {
      bgColor = const Color(0xFFF1F5F9);
      borderColor = AppColors.divider;
      iconColor = AppColors.textMuted;
      textColor = AppColors.textMuted;
      tooltip = isLost
          ? 'Bạn đã bỏ lỡ 1 ngày nên chuỗi phòng này về 0. Nhắn tin hôm nay để thắp lại!'
          : 'Chuỗi phòng: 0 ngày. Nhắn 1 tin trong phòng này để bắt đầu thắp lửa!';
    }

    final label = compact ? '$streak' : '$streak ngày';

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLitToday
                  ? Icons.local_fire_department_rounded
                  : Icons.local_fire_department_outlined,
              size: compact ? 13.5 : 16,
              color: iconColor,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            if (isAtRisk && !compact) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.hourglass_bottom_rounded,
                size: 12,
                color: Color(0xFFD97706),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
