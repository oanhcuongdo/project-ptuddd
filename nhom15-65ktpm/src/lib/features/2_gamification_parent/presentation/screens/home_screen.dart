import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/controllers/finger_math_controller.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/widgets/finger_math_board_widget.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/presentation/screens/flash_anzan_screen.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/presentation/screens/lesson_play_screen.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/child_profile.dart';
import '../../../../shared/widgets/kid_badge_card.dart';
import '../../../../shared/widgets/kid_button.dart';
import '../../../../shared/widgets/kid_card.dart';
import '../../../../shared/widgets/kid_decoration.dart';
import '../../../../shared/widgets/kid_status_banner.dart';
import '../../../../shared/widgets/kid_status_icon.dart';
import '../../../../shared/widgets/mascot_bubble.dart';
import '../../../../shared/widgets/panda_mascot.dart';
import 'parent_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = sl<AudioService>();
  final AuthService _authService = sl<AuthService>();
  final StorageService _storageService = sl<StorageService>();
  ChildProfile? _profile;
  bool _showReminderBanner = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _storageService.getChildProfile();
    final reminderSettings = await ReminderService.getSettings();
    final showReminder = ReminderService.shouldShowInAppReminder(
      settings: reminderSettings,
      profile: profile,
    );

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _showReminderBanner = showReminder;
    });
  }

  /// Biểu cảm Panda dựa trên chuỗi Streak hiện tại.
  PandaExpression get _pandaExpression {
    final streak = _profile?.streakCount ?? 0;
    if (streak >= 7) return PandaExpression.celebrating;
    if (streak >= 3) return PandaExpression.encouraging;
    return PandaExpression.happy;
  }

  /// Lời chào động theo tên bé và chuỗi Streak.
  String get _greetingText {
    final name = _profile?.name;
    final streak = _profile?.streakCount ?? 0;
    final greeting =
        name != null && name.isNotEmpty ? 'Chào bé $name!' : 'Chào bé!';
    if (streak >= 7) {
      return '$greeting Tuyệt vời! $streak ngày liên tiếp rồi! 🎉';
    } else if (streak >= 3) {
      return '$greeting Giỏi lắm! $streak ngày liên tiếp! 🔥';
    }
    return '$greeting Hôm nay mình cùng chơi toán nhé!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 640;
            final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 20.0;
            final contentWidth = (constraints.maxWidth - horizontalPadding * 2)
                .clamp(0.0, double.infinity)
                .toDouble();
            final mascotWidth =
                constraints.maxWidth < 360 ? contentWidth : 360.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: _storageService.lastCloudSyncError == null
                                ? 'Dữ liệu đã đồng bộ với Firebase'
                                : 'Chưa đồng bộ được dữ liệu. Kiểm tra cấu hình Firebase.',
                            child: Icon(
                              _storageService.lastCloudSyncError == null
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_off_rounded,
                              color: _storageService.lastCloudSyncError == null
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Đăng xuất tài khoản',
                            onPressed: _confirmSignOut,
                            icon: const Icon(Icons.logout_rounded),
                          ),
                        ],
                      ),
                      Center(
                        child: SizedBox(
                          width: mascotWidth,
                          child: MascotBubbleWidget(
                            speechText: _greetingText,
                            expression: _pandaExpression,
                            onMascotTap: () {
                              HapticFeedback.selectionClick();
                              _audioService.speak(_greetingText);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _profile == null
                            ? 'Chào bé!'
                            : 'Chào bé ${_profile!.name}!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildStreakCard(context),
                      if (_showReminderBanner) ...[
                        const SizedBox(height: 12),
                        _buildReminderBanner(),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Chọn hoạt động',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isWide ? 1.12 : 0.92,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildFeatureCard(
                            label: 'Tập đếm',
                            semanticLabel: 'Tập đếm ngón tay tự do',
                            icon: Icons.back_hand_rounded,
                            color: AppColors.secondary,
                            onTap: _openFreePlayModal,
                          ),
                          _buildFeatureCard(
                            label: 'Luyện tập',
                            semanticLabel:
                                'Chọn bài luyện toán cơ bản hoặc công thức',
                            icon: Icons.calculate_rounded,
                            color: AppColors.primary,
                            onTap: _openPracticeOptions,
                          ),
                          _buildFeatureCard(
                            label: 'Flash Anzan',
                            semanticLabel: 'Luyện tính nhẩm Flash Anzan',
                            icon: Icons.bolt_rounded,
                            color: AppColors.accentPurple,
                            onTap: _openFlashAnzan,
                          ),
                          _buildFeatureCard(
                            label: 'Phụ huynh',
                            semanticLabel: 'Mở cổng phụ huynh',
                            icon: Icons.family_restroom_rounded,
                            color: AppColors.success,
                            onTap: _openParentDashboard,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildBadgeCollection(
                        context,
                        constraints.maxWidth,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    final streakCount = _profile?.streakCount;
    return KidCard(
      color: Theme.of(context).colorScheme.secondaryContainer,
      semanticLabel: streakCount == null
          ? 'Đang tải chuỗi ngày học'
          : 'Chuỗi ngày học: $streakCount ngày',
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.accentYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuỗi ngày học',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Text(
                    streakCount == null ? 'Đang tải…' : '$streakCount ngày',
                    key: ValueKey(streakCount),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          const KidDecoration(
            type: KidDecorationType.star,
            size: 32,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.accentYellow),
              Text(
                '${_profile?.totalPoints ?? 0}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Text('điểm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCollection(BuildContext context, double width) {
    final profile = _profile;
    if (profile == null) {
      return const KidCard(
        semanticLabel: 'Đang tải bộ sưu tập huy hiệu',
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final unlockedBadges = GamificationService.unlockedBadgesFor(profile);
    final lockedBadges = GamificationService.lockedBadgesFor(profile);
    final badges = [...unlockedBadges, ...lockedBadges];
    final unlockedIds = unlockedBadges.map((badge) => badge.id).toSet();
    final columns = width >= 900
        ? 4
        : width >= 560
            ? 3
            : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.secondary,
              size: 30,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Huy hiệu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Semantics(
              label:
                  '${unlockedBadges.length} trên ${badges.length} huy hiệu đã mở khóa',
              child: Text(
                '${unlockedBadges.length}/${badges.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryText,
                    ),
              ),
            ),
          ],
        ),
        if (unlockedBadges.isEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Học tập để mở huy hiệu đầu tiên nhé!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: badges.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns == 2 ? 0.95 : 0.9,
          ),
          itemBuilder: (context, index) {
            final badge = badges[index];
            return KidBadgeCard(
              badge: badge,
              isUnlocked: unlockedIds.contains(badge.id),
              size: 100,
            );
          },
        ),
      ],
    );
  }

  Widget _buildReminderBanner() {
    return KidStatusBanner(
      status: KidStatusType.warning,
      iconEmoji: '⏰',
      title: 'Đã đến giờ luyện tập!',
      subtitle: 'Cùng học để duy trì chuỗi ngày nhé!',
      actionLabel: 'Bắt đầu ngay',
      onAction: () => _openLesson(1),
      onDismiss: () => setState(() => _showReminderBanner = false),
      margin: EdgeInsets.zero,
    );
  }

  Widget _buildFeatureCard({
    required String label,
    required String semanticLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return KidCard(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      semanticLabel: semanticLabel,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
          ),
        ],
      ),
    );
  }

  void _openFreePlayModal() {
    final fingerController = FingerMathController(showLeftHand: true);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('✋', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: FingerMathBoardWidget(
                      controller: fingerController,
                      height: 220,
                      showLiveValue: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                KidButton(
                  onPressed: () =>
                      _audioService.speak(fingerController.speechDescription),
                  icon: Icons.volume_up_rounded,
                  label: 'Nghe số',
                  semanticLabel: 'Nghe phát âm số ngón tay',
                  backgroundColor: AppColors.buttonSecondary,
                  textColor: AppColors.textDark,
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => _loadProfile());
  }

  void _openPracticeOptions() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              KidButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _openLesson(1);
                },
                icon: Icons.looks_one_rounded,
                label: 'Toán cơ bản',
                semanticLabel: 'Bắt đầu luyện toán cơ bản',
                backgroundColor: AppColors.buttonSecondary,
                textColor: AppColors.textDark,
              ),
              const SizedBox(height: 12),
              KidButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _openLesson(2);
                },
                icon: Icons.swap_horiz_rounded,
                label: 'Công thức',
                semanticLabel: 'Bắt đầu luyện công thức',
                backgroundColor: AppColors.buttonPurple,
                textColor: AppColors.textDark,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openParentDashboard() {
    ParentDashboardRoute.open(context).then((_) => _loadProfile());
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Tiến độ của bé đã được lưu theo tài khoản.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (shouldSignOut == true) await _authService.signOut();
  }

  void _openLesson(int level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonPlayScreen(level: level),
      ),
    ).then((_) => _loadProfile());
  }

  void _openFlashAnzan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FlashAnzanScreen(),
      ),
    ).then((_) => _loadProfile());
  }
}
