import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass.dart';

class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _Feature(this.title, this.subtitle, this.icon, this.color, this.route);
}

const _features = [
  _Feature('Bản Đồ Lộ Trình', 'HSK 1 - HSK 2', Icons.map_outlined, AppColors.sky, AppConstants.roadmapRoute),
  _Feature(
    'Chấm Phát Âm AI',
    'Thanh điệu & Pinyin',
    Icons.mic_none_outlined,
    AppColors.fig,
    AppConstants.pronunciationRoute,
  ),
  _Feature('Luyện Viết Hán Tự', 'Thứ tự nét chuẩn', Icons.brush_outlined, AppColors.heather, AppConstants.writingRoute),
  _Feature(
    'Flashcard SM-2',
    'Ôn tập ngắt quãng',
    Icons.style_outlined,
    AppColors.secondaryDark,
    AppConstants.flashcardRoute,
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();

  /// 0 → 1 khi tiêu đề lớn cuộn khuất: hiện dần thanh kính + tiêu đề nhỏ (kiểu iOS).
  double _collapse = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final v = (_scroll.offset / 56).clamp(0.0, 1.0);
      if ((v - _collapse).abs() > 0.02 || v == 0 || v == 1) setState(() => _collapse = v);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassScaffold(
      appBar: GlassAppBar(
        backgroundOpacity: _collapse,
        title: Opacity(opacity: _collapse, child: const Text('ChaiLish')),
        actions: [
          // Menu dev: đăng nhập demo, dữ liệu giả, trạng thái hợp đồng (không có ở bản release).
          if (kDebugMode)
            GlassIconButton(
              icon: CupertinoIcons.wrench,
              tooltip: 'Menu dev',
              onPressed: () => context.push(AppConstants.devMenuRoute),
            ),
          GlassIconButton(icon: CupertinoIcons.bell, tooltip: 'Thông báo', onPressed: () {}),
          GlassIconButton(
            icon: CupertinoIcons.person_crop_circle,
            tooltip: 'Tài khoản',
            onPressed: () => context.push(AppConstants.loginRoute),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final pad = MediaQuery.paddingOf(context);
          return ListView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.fromLTRB(16, pad.top + 4, 16, pad.bottom + 24),
            children: [
              // Tiêu đề lớn kiểu iOS
              EntranceAnimation(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ChaiLish', style: theme.textTheme.displaySmall),
                    Text(
                      '学中文 · Học tiếng Trung mỗi ngày',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const EntranceAnimation(index: 1, child: _StreakHero(streakDays: 3, goalProgress: 0.6)),
              const SizedBox(height: 28),
              EntranceAnimation(index: 2, child: Text('Tính Năng Cốt Lõi', style: theme.textTheme.titleLarge)),
              const SizedBox(height: 12),
              EntranceAnimation(index: 3, child: _FeaturedAiCard(onTap: () => context.push(AppConstants.aiChatRoute))),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.02,
                children: [
                  for (var i = 0; i < _features.length; i++)
                    EntranceAnimation(
                      index: 4 + i,
                      child: _FeatureCard(feature: _features[i]),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              EntranceAnimation(
                index: 8,
                child: GlassCard(
                  onTap: () => context.push(AppConstants.statisticsRoute),
                  child: Row(
                    children: [
                      const CookieIcon(icon: Icons.insights_outlined, color: AppColors.cactus, lobes: 6),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Thống Kê Tiến Độ', style: theme.textTheme.titleMedium),
                            Text(
                              'Biểu đồ & Xếp hạng',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_forward, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Thẻ nổi bật kiểu Expressive: nền gradient đỏ son, chuỗi ngày học đếm lên,
/// vòng mục tiêu hôm nay chạy bằng lò xo.
class _StreakHero extends StatelessWidget {
  final int streakDays;
  final double goalProgress;

  const _StreakHero({required this.streakDays, required this.goalProgress});

  @override
  Widget build(BuildContext context) {
    // Bóng vẽ bằng RRect (Impeller vẽ bóng superellipse bị lỗi khối vuông),
    // phần nền gradient vẫn giữ hình squircle.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.clayDeep.withValues(alpha: 0.24),
            blurRadius: 32,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(32)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.clayGradient,
          ),
        ),
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Chữ Hán trang trí mờ phía sau
              const Positioned(
                right: -12,
                bottom: -34,
                child: Text(
                  '学',
                  style: TextStyle(fontSize: 150, color: Color(0x1FFFFFFF), fontWeight: FontWeight.w900),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xin chào, Học viên!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'serif',
                              fontFamilyFallback: ['Noto Serif', 'Georgia'],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Mục tiêu: 15 phút học mỗi ngày',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          GlassSurface(
                            borderRadius: BorderRadius.circular(100),
                            tint: const Color(0x33FFFFFF),
                            shadow: false,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.3, end: 1),
                                  duration: const Duration(milliseconds: 1100),
                                  curve: Curves.elasticOut,
                                  builder: (context, s, child) => Transform.scale(scale: s, child: child),
                                  child: const Icon(Icons.local_fire_department, color: AppColors.manilla, size: 22),
                                ),
                                const SizedBox(width: 6),
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: streakDays),
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, v, _) => Text(
                                    '$v ngày liên tiếp',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: goalProgress),
                      duration: const Duration(milliseconds: 1200),
                      curve: AppMotion.springSmooth,
                      builder: (context, v, _) => SizedBox.square(
                        dimension: 76,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.square(
                              dimension: 76,
                              child: CircularProgressIndicator(
                                value: v.clamp(0.0, 1.0),
                                strokeWidth: 9,
                                strokeCap: StrokeCap.round,
                                color: Colors.white,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                            Text(
                              '${(v * 15).round()}′',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ rộng cho Trợ lý AI – tính năng đã hoạt động.
class _FeaturedAiCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FeaturedAiCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      key: const Key('feature-ai-chat'),
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const CookieIcon(icon: Icons.smart_toy_outlined, color: AppColors.clay, size: 60, lobes: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trợ Lý AI Ôn Bài', style: theme.textTheme.titleMedium?.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text(
                  'Hội thoại & Ngữ pháp',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          GlassSurface(
            borderRadius: BorderRadius.circular(100),
            tint: AppColors.clayDeep.withValues(alpha: 0.92),
            shadow: false,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              'Bắt đầu',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      onTap: () => context.push(feature.route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CookieIcon(icon: feature.icon, color: feature.color),
          const Spacer(),
          Text(feature.title, style: theme.textTheme.titleSmall?.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text(feature.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
