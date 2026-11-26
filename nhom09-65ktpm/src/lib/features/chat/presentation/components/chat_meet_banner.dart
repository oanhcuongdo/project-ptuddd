import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/meet_session_model.dart';
import '../styles/chat_styles.dart';

/// Thanh Banner lịch / buổi Video Call Meet hiển thị Realtime ngay đầu khung chat.
class ChatMeetBanner extends StatelessWidget {
  final MeetSessionModel session;
  final bool canManage;
  final VoidCallback onJoinMeet;
  final VoidCallback? onStartNow;
  final VoidCallback? onEndSession;

  const ChatMeetBanner({
    super.key,
    required this.session,
    required this.canManage,
    required this.onJoinMeet,
    this.onStartNow,
    this.onEndSession,
  });

  String _formatSchedule(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')} '
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isLive = session.isLive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isLive ? ChatStyles.tealSoftBg : const Color(0xFFFFFBEB),
        border: Border(
          bottom: BorderSide(
            color: isLive ? ChatStyles.tealBorder : const Color(0xFFFDE68A),
          ),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLive ? Icons.sensors_rounded : Icons.event_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLive ? 'LIVE MEET' : 'LỊCH HỌC',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isLive
                          ? '${session.hostName} đang mở • Học đủ ${session.minMinutes} phút → 🔥 +1 chuỗi'
                          : 'Bắt đầu lúc ${_formatSchedule(session.scheduledAt)} • Cần ${session.minMinutes} phút → 🔥 +1 chuỗi',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isLive)
                FilledButton.icon(
                  onPressed: onJoinMeet,
                  style: FilledButton.styleFrom(
                    backgroundColor: ChatStyles.tealPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.videocam_rounded, size: 16),
                  label: const Text('Tham gia Meet'),
                )
              else if (canManage && onStartNow != null)
                FilledButton.icon(
                  onPressed: onStartNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: ChatStyles.tealPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 17),
                  label: const Text('Mở phòng ngay'),
                ),
              if (canManage && onEndSession != null)
                OutlinedButton(
                  onPressed: onEndSession,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Kết thúc'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
