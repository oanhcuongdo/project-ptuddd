import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth_profile/presentation/components/auth_brand_header.dart';
import '../../features/auth_profile/presentation/components/auth_web_hero.dart';
import '../../features/auth_profile/presentation/styles/auth_styles.dart';

/// Khung bố cục Responsive cho phân hệ Xác thực:
/// - Android / Mobile (< 850px): 1 cột căn giữa (Header logo trên, Form dưới).
/// - Chrome / Desktop (>= 850px): 2 cột  
class AuthLayout extends StatelessWidget {
  final String subtitle;
  final String? cardTitle;
  final Widget child;
  final Widget? footer;

  const AuthLayout({
    super.key,
    required this.subtitle,
    this.cardTitle,
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
                    horizontal: isDesktop ? 40 : 22,
                    vertical: isDesktop ? AppSpacing.xxl : AppSpacing.xl,
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
          AuthBrandHeader(tagline: subtitle),
          const SizedBox(height: 28),
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
              padding: const EdgeInsets.all(32),
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
                    const SizedBox(height: 22),
                  ],
                  child,
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.xl),
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
