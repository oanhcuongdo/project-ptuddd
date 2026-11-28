import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../theme.dart';

enum FeedbackTone { error, warning, info, success }

/// Hiệu ứng xuất hiện nhẹ nhàng (mờ dần + trượt nhẹ lên) tôn trọng cấu hình
/// giảm chuyển động của hệ điều hành và kết thúc hữu hạn (an toàn cho kiểm thử).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
    this.offsetY = 14,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _slide = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _slide.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Khung phản hồi trạng thái rõ ràng kèm biểu tượng + viền ngữ nghĩa
/// (Nguyên tắc Nielsen #1 & #9: giúp người dùng nhận diện & khắc phục lỗi nhanh).
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.message,
    this.tone = FeedbackTone.info,
    this.title,
    this.action,
  });

  final String message;
  final FeedbackTone tone;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (tone) {
      FeedbackTone.error => (
          AppColors.dangerBg,
          const Color(0xFFFCA5A5),
          const Color(0xFFB91C1C),
          Icons.error_outline_rounded,
        ),
      FeedbackTone.warning => (
          AppColors.warningBg,
          const Color(0xFFFCD34D),
          const Color(0xFFB45309),
          Icons.warning_amber_rounded,
        ),
      FeedbackTone.success => (
          AppColors.successBg,
          const Color(0xFF6EE7B7),
          const Color(0xFF047857),
          Icons.check_circle_outline_rounded,
        ),
      FeedbackTone.info => (
          AppColors.infoBg,
          const Color(0xFF93C5FD),
          AppColors.navyBrand,
          Icons.info_outline_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 19, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Khối trạng thái trống / lỗi thân thiện với vòng sáng biểu tượng & nút hành động rõ ràng.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.accentColor = AppColors.primary,
    this.action,
  });

  final IconData icon;
  final String? title;
  final String message;
  final Color accentColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 38, color: accentColor),
              ),
              const SizedBox(height: 16),
              if (title != null) ...[
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSecondary,
                  height: 1.45,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiêu đề nhóm có biểu tượng màu nhấn (Luật Gestalt: Phân nhóm vùng chung).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.color = AppColors.primary,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Chấm trạng thái sống động (trực quan hóa trạng thái mở cửa / trực tuyến).
class LiveStatusDot extends StatelessWidget {
  const LiveStatusDot({super.key, required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 6,
      height: size + 6,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.22),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/// Hộp thoại xác nhận đăng xuất (Nguyên tắc Nielsen #5: Phòng ngừa thao tác nhầm).
Future<void> confirmAndSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.logout_rounded, color: AppColors.sosRed),
      ),
      title: const Text('Đăng xuất tài khoản?'),
      content: const Text(
        'Bạn sẽ quay lại màn hình đăng nhập và cần nhập thông tin để truy cập lại.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Ở lại'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(124, 46),
            backgroundColor: AppColors.sosRed,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Đăng xuất'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await AuthRepository().signOut();
  }
}
