import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth_profile/presentation/components/auth_brand_header.dart';
import '../../features/auth_profile/presentation/components/auth_web_hero.dart';
import '../../features/auth_profile/presentation/styles/auth_styles.dart';

/// Khung bố cục Responsive cho phân hệ Xác thực:
/// - Android / Mobile (< 850px): 1 cột căn giữa (tuỳ chọn hiện BrandHeader trên Login, ẩn trên Register 2 bước).
/// - Chrome / Desktop (>= 850px): 2 cột kiểu Facebook (Cột trái Hero thương hiệu, Cột phải thẻ Form trắng).
class AuthLayout extends StatelessWidget {
  final String subtitle;
  final String? cardTitle;
  final bool showMobileBrandHeader;
  final Widget child;
  final Widget? footer;

  const AuthLayout({
    super.key,
    required this.subtitle,
    this.cardTitle,
    this.showMobileBrandHeader = true,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop =
              constraints.maxWidth >= AuthStyles.desktopBreakpoint;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: isDesktop && !isDark
                ? AuthStyles.webBackground
                : BoxDecoration(
                    color: isDark ? null : AppColors.scaffoldMobile,
                  ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: isDesktop ? AppSpacing.xxl : AppSpacing.lg,
                  ),
                  child: isDesktop
                      ? _buildDesktopLayout(isDark)
                      : _buildMobileLayout(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Giao diện 1 cột cho Android / Mobile
  Widget _buildMobileLayout() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AuthStyles.maxMobileFormWidth,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showMobileBrandHeader) ...[
            AuthBrandHeader(tagline: subtitle),
            const SizedBox(height: 28),
          ],
          child,
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.xl),
            footer!,
          ],
        ],
      ),
    );
  }

  /// Giao diện 2 cột kiểu Facebook cho Chrome / Desktop
  Widget _buildDesktopLayout(bool isDark) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AuthStyles.maxDesktopContainerWidth,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 11,
            child: Padding(
              padding: const EdgeInsets.only(right: 48),
              child: AuthWebHero(tagline: subtitle),
            ),
          ),
          SizedBox(
            width: AuthStyles.desktopCardWidth,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: AuthStyles.webCardDecoration(isDark),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (cardTitle != null) ...[
                    Text(
                      cardTitle!,
                      style: AuthStyles.cardTitle.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  child,
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
