import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../styles/chat_styles.dart';

/// Mở link Meet trong tab mới (stub cho môi trường non-Web / test)
void openMeetInNewTab(String url) {}

/// Khung hiển thị phòng Video Call Jitsi Meet trên môi trường non-Web / Widget Test.
class JitsiMeetFrame extends StatelessWidget {
  final String meetUrl;
  final String roomTitle;

  const JitsiMeetFrame({
    super.key,
    required this.meetUrl,
    required this.roomTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ChatStyles.tealPrimary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  size: 32,
                  color: ChatStyles.tealLight,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                roomTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phòng Video Call Jitsi Meet đang hoạt động. Đồng hồ điểm danh lên chuỗi ở phía trên vẫn đang chạy trực tiếp.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: meetUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép link phòng Meet!')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.surfaceWhite,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Sao chép link Meet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
