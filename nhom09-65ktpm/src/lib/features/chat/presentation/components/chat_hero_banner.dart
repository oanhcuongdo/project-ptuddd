import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../styles/chat_styles.dart';

/// Banner nổi bật tông Xanh Ngọc phía trên danh sách phòng học:
/// "Luyện nói cùng bạn bè — Mỗi ngày tốt hơn!" kèm minh họa mic & bong bóng hội thoại.
class ChatHeroBanner extends StatelessWidget {
  final bool isDiscoverTab;
  final VoidCallback onPrimaryAction;

  const ChatHeroBanner({
    super.key,
    required this.isDiscoverTab,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E),
            Color(0xFF0D9488),
            Color(0xFF2DD4BF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ChatStyles.tealPrimary.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Các vòng tròn phát sáng trang trí nền
          Positioned(
            right: -30,
            top: -36,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 110,
            bottom: -55,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: 22,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showArt = constraints.maxWidth >= 520;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Luyện nói cùng bạn bè',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mỗi ngày tốt hơn!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.90),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tham gia buổi học Video Call mỗi ngày để thắp sáng chuỗi lửa phòng cùng cộng đồng BuddyTalk.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: onPrimaryAction,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: ChatStyles.tealDark,
                              elevation: 0,
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            icon: Icon(
                              isDiscoverTab
                                  ? Icons.add_circle_outline_rounded
                                  : Icons.play_arrow_rounded,
                              size: 18,
                            ),
                            label: Text(
                              isDiscoverTab ? 'Tạo phòng học' : 'Khám phá ngay',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showArt) ...[
                      const SizedBox(width: AppSpacing.lg),
                      _HeroIllustration(),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            bottom: 8,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.headset_mic_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          Positioned(
            right: 0,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                "Let's\nspeak!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: ChatStyles.tealDark,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
