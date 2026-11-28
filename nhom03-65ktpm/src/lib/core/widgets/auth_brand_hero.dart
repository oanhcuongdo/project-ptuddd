import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_logo.dart';

/// Khối thương hiệu đầu màn đăng nhập — tham chiếu `15_brand_visual.png`:
/// nền gradient xanh, logo trên ô sáng, tên app + khẩu hiệu, hoạ tiết vòng
/// tròn mờ và biểu tượng sách chìm ở góc phải.
///
/// Chỉ dùng role màu của theme nên tự tương phản đúng ở cả sáng và tối.
class AuthBrandHero extends StatelessWidget {
  const AuthBrandHero({this.tagline = 'Học tốt hơn mỗi ngày', super.key});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onHero = scheme.onPrimary;

    return Container(
      height: AppSizes.authHeroHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary,
            Color.lerp(scheme.primary, scheme.shadow, 0.28)!,
          ],
        ),
        boxShadow: AppShadows.hero(scheme.primary),
      ),
      child: Stack(
        children: <Widget>[
          // Hoạ tiết nền: vòng tròn và biểu tượng sách mờ, không mang thông tin.
          Positioned(
            top: -36,
            right: 28,
            child: _Circle(size: 104, color: onHero.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -42,
            right: 92,
            child: _Circle(size: 72, color: onHero.withValues(alpha: 0.07)),
          ),
          Positioned(
            right: -18,
            bottom: -24,
            child: Icon(
              Icons.auto_stories_rounded,
              size: 148,
              color: onHero.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const AppLogo(size: 44, onPrimary: true),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'SmartNote',
                  style: theme.textTheme.titleLarge?.copyWith(color: onHero),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  tagline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onHero.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
