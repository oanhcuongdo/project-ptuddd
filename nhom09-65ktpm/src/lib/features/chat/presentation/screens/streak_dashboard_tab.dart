import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/streak_board_model.dart';
import '../providers/chat_provider.dart';
import '../styles/chat_styles.dart';

/// Trang Dashboard "Bảng cập nhật chuỗi" hiển thị toàn màn hình:
/// - 4 thẻ KPI tổng quan (Chuỗi hiện tại, Kỷ lục, Tiến độ hôm nay, Ngày đạt tuần này)
/// - Bố cục 2 cột rộng trên Desktop:
///   + Trái: Tiến độ 7 ngày tuần này (T2 -> CN) + Chuỗi theo từng phòng học
///   + Phải: Cách tính chuỗi + Lịch sử cập nhật chuỗi gần đây
class StreakDashboardTab extends StatefulWidget {
  const StreakDashboardTab({super.key});

  @override
  State<StreakDashboardTab> createState() => _StreakDashboardTabState();
}

class _StreakDashboardTabState extends State<StreakDashboardTab> {
  String? _loadedForUserId;

  void _ensureLoaded(String? userId, int dailyGoalMinutes) {
    if (userId == null || userId == _loadedForUserId) return;
    _loadedForUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshData(userId: userId, dailyGoalMinutes: dailyGoalMinutes);
    });
  }

  Future<void> _refreshData({
    required String userId,
    required int dailyGoalMinutes,
  }) async {
    final chat = context.read<ChatProvider>();
    await chat.loadStreakBoard(
      userId: userId,
      dailyGoalMinutes: dailyGoalMinutes,
    );
    if (mounted && chat.myRooms.isEmpty && !chat.isLoading) {
      await chat.loadRooms(userId, silent: true);
    }
  }

  String _formatHistoryTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (diff == 0) return 'Hôm nay $hh:$mm';
    if (diff == 1) return 'Hôm qua $hh:$mm';
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$dd/$mo $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().currentProfile;
    final chat = context.watch<ChatProvider>();
    final userId = profile?.userId;
    final dailyGoal = (profile?.dailyGoalMinutes ?? 15) > 0
        ? (profile?.dailyGoalMinutes ?? 15)
        : 15;

    _ensureLoaded(userId, dailyGoal);

    final board = chat.streakBoard;
    final isLoading = chat.isLoadingStreakBoard;
    final rooms = chat.myRooms;
    final streakCount = profile?.streakCount ?? 0;
    final bestStreak = (profile?.bestStreak ?? 0) > streakCount
        ? (profile?.bestStreak ?? 0)
        : streakCount;
    final todayMinutes = board?.todayMinutes ?? 0;
    final progress = (todayMinutes / dailyGoal).clamp(0.0, 1.0);
    final remaining = (dailyGoal - todayMinutes).clamp(0, dailyGoal);
    final isGoalDone = todayMinutes >= dailyGoal;
    final weekDays = board?.weekDays ??
        StreakBoardData.buildCurrentWeekDays(
          referenceDate: DateTime.now(),
          dailyGoalMinutes: dailyGoal,
          logsByDateKey: const {},
        );
    final completedDays = weekDays.where((d) => d.isCompleted).length;
    final activeRoomsCount =
        rooms.where((r) => r.effectiveRoomStreak() > 0).length;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader(
                isLoading: isLoading,
                onRefresh: userId == null
                    ? null
                    : () => _refreshData(
                          userId: userId,
                          dailyGoalMinutes: dailyGoal,
                        ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4 thẻ KPI tổng quan
              _buildKpiGrid(
                streakCount: streakCount,
                bestStreak: bestStreak,
                todayMinutes: todayMinutes,
                dailyGoal: dailyGoal,
                progress: progress,
                isGoalDone: isGoalDone,
                completedDays: completedDays,
                activeRoomsCount: activeRoomsCount,
                totalRoomsCount: rooms.length,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Bố cục Dashboard 2 cột rộng hiển thị đầy đủ mọi thông tin
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 920;

                  final leftColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWeekProgressCard(
                        weekDays: weekDays,
                        todayMinutes: todayMinutes,
                        dailyGoal: dailyGoal,
                        progress: progress,
                        remaining: remaining,
                        isGoalDone: isGoalDone,
                        completedDays: completedDays,
                        isLoading: isLoading && board == null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildRoomStreaksCard(rooms),
                    ],
                  );

                  final rightColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStreakRulesCard(dailyGoal: dailyGoal),
                      const SizedBox(height: AppSpacing.lg),
                      _buildRecentHistoryCard(
                        history: board?.recentHistory ?? const [],
                        isLoading: isLoading && board == null,
                      ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: leftColumn),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(flex: 5, child: rightColumn),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      leftColumn,
                      const SizedBox(height: AppSpacing.lg),
                      rightColumn,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader({
    required bool isLoading,
    required VoidCallback? onRefresh,
  }) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.streakOrange.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bảng cập nhật chuỗi', style: ChatStyles.pageTitle),
                  SizedBox(height: 2),
                  Text(
                    'Theo dõi chuỗi cá nhân, tiến độ 7 ngày, chuỗi từng phòng học và lịch sử điểm danh',
                    style: ChatStyles.pageSubtitle,
                  ),
                ],
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onRefresh,
          style: OutlinedButton.styleFrom(
            foregroundColor: ChatStyles.tealDark,
            backgroundColor: AppColors.surfaceWhite,
            side: const BorderSide(color: Color(0xFFDCE7EA)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ChatStyles.tealPrimary,
                  ),
                )
              : const Icon(Icons.refresh_rounded, size: 17),
          label: const Text(
            'Làm mới dữ liệu',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid({
    required int streakCount,
    required int bestStreak,
    required int todayMinutes,
    required int dailyGoal,
    required double progress,
    required bool isGoalDone,
    required int completedDays,
    required int activeRoomsCount,
    required int totalRoomsCount,
  }) {
    final pct = (progress * 100).round();
    final cards = [
      _KpiCard(
        icon: Icons.local_fire_department_rounded,
        iconBg: AppColors.streakBg,
        iconColor: AppColors.streakOrange,
        label: 'Chuỗi cá nhân hiện tại',
        value: '$streakCount ngày liên tiếp',
        subtext: isGoalDone
            ? 'Đã hoàn thành mục tiêu hôm nay'
            : 'Vào Video Call để giữ lửa hôm nay',
        highlightBorder: const Color(0xFFFDBA74),
      ),
      _KpiCard(
        icon: Icons.emoji_events_rounded,
        iconBg: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
        label: 'Kỷ lục chuỗi dài nhất',
        value: 'Kỷ lục: $bestStreak ngày',
        subtext: 'Chuỗi cá nhân cao nhất từng đạt',
      ),
      _KpiCard(
        icon: Icons.timer_outlined,
        iconBg: ChatStyles.tealSoftBg,
        iconColor: ChatStyles.tealPrimary,
        label: 'Mục tiêu hôm nay ($pct%)',
        value: '$todayMinutes / $dailyGoal phút',
        subtext: isGoalDone
            ? 'Vượt mốc mục tiêu mỗi ngày'
            : 'Còn thiếu ${(dailyGoal - todayMinutes).clamp(0, dailyGoal)} phút',
      ),
      _KpiCard(
        icon: Icons.groups_rounded,
        iconBg: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
        label: 'Tuần này & Phòng đang cháy',
        value: '$completedDays/7 ngày đạt',
        subtext: '$activeRoomsCount/$totalRoomsCount phòng đang có chuỗi lửa',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 960
            ? 4
            : (constraints.maxWidth >= 560 ? 2 : 1);
        const gap = AppSpacing.md;
        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _buildWeekProgressCard({
    required List<DailyStreakDay> weekDays,
    required int todayMinutes,
    required int dailyGoal,
    required double progress,
    required int remaining,
    required bool isGoalDone,
    required int completedDays,
    required bool isLoading,
  }) {
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ChatStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiến độ 7 ngày tuần này',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tự động cập nhật từ thời gian học Video Call mỗi ngày',
                      style: ChatStyles.metaText,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ChatStyles.tealSoftBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ChatStyles.tealBorder),
                ),
                child: Text(
                  '$completedDays/7 ngày đạt',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ChatStyles.tealDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 7 ô ngày T2 -> CN rộng rãi
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: ChatStyles.tealPrimary),
              ),
            )
          else
            Row(
              children: weekDays
                  .map((day) => Expanded(child: _WeekDayColumn(day: day)))
                  .toList(),
            ),

          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isGoalDone
                  ? ChatStyles.tealSoftBg
                  : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isGoalDone
                    ? ChatStyles.tealBorder
                    : const Color(0xFFFDBA74),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mục tiêu hôm nay: $todayMinutes / $dailyGoal phút',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isGoalDone
                            ? ChatStyles.tealDark
                            : const Color(0xFF9A3412),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isGoalDone
                            ? ChatStyles.tealDark
                            : const Color(0xFFC2410C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isGoalDone
                          ? ChatStyles.tealPrimary
                          : AppColors.streakOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isGoalDone
                      ? 'Xuất sắc! Bạn đã hoàn thành mục tiêu giữ chuỗi cá nhân hôm nay.'
                      : 'Còn thiếu $remaining phút học trong Video Call nữa để hoàn thành mục tiêu hôm nay.',
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w600,
                    color: isGoalDone
                        ? ChatStyles.tealDark
                        : const Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomStreaksCard(List<ConversationModel> rooms) {
    final sorted = [...rooms]..sort(
        (a, b) => b.effectiveRoomStreak().compareTo(a.effectiveRoomStreak()),
      );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ChatStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.forum_rounded,
                size: 19,
                color: ChatStyles.tealPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chuỗi theo từng phòng học (${sorted.length} phòng)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Mỗi phòng giữ 1 chuỗi lửa độc lập khi bạn học đủ phút trong buổi Video Call của phòng đó',
            style: ChatStyles.metaText,
          ),
          const SizedBox(height: 14),
          if (sorted.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2ECEE)),
              ),
              child: const Text(
                'Bạn chưa tham gia phòng học nào. Vào mục Phòng học → Khám phá để tham gia và bắt đầu giữ chuỗi nhé!',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            )
          else
            Column(
              children: sorted.map((room) {
                final streak = room.effectiveRoomStreak();
                final lit = room.isStreakLitToday();
                final atRisk = room.isStreakAtRisk();

                final Color badgeBg;
                final Color badgeFg;
                final String badgeText;
                if (lit) {
                  badgeBg = AppColors.streakBg;
                  badgeFg = const Color(0xFFC2410C);
                  badgeText = '🔥 $streak ngày • Đã giữ lửa';
                } else if (atRisk) {
                  badgeBg = const Color(0xFFFFFBEB);
                  badgeFg = const Color(0xFFB45309);
                  badgeText = '⏳ $streak ngày • Sắp mất chuỗi';
                } else {
                  badgeBg = const Color(0xFFF1F5F9);
                  badgeFg = AppColors.textMuted;
                  badgeText = '0 ngày • Chưa thắp lửa';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2ECEE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: lit
                              ? AppColors.streakBg
                              : ChatStyles.tealSoftBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.groups_rounded,
                          size: 20,
                          color: lit
                              ? AppColors.streakOrange
                              : ChatStyles.tealPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${room.targetLang.toUpperCase()} • ${room.levelLabel} • Kỷ lục phòng: ${room.bestStreak} ngày',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: badgeFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakRulesCard({required int dailyGoal}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ChatStyles.tealBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 19,
                color: ChatStyles.tealDark,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cách tính & cập nhật chuỗi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ChatStyles.tealDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _RuleBullet(
            text:
                'Chuỗi phòng: Tham gia buổi học Video Call do Chủ phòng hoặc Trợ giảng mở và học đủ số phút tối thiểu.',
          ),
          const SizedBox(height: 6),
          _RuleBullet(
            text:
                'Chuỗi cá nhân: Cộng dồn tổng số phút học Video Call trong ngày; đạt $dailyGoal phút/ngày sẽ tự động tăng chuỗi cá nhân.',
          ),
          const SizedBox(height: 6),
          const _RuleBullet(
            text:
                'Giữ kỷ luật đều đặn: Bỏ lỡ trọn vẹn 1 ngày không học, chuỗi phòng sẽ tự đặt lại về 0 để bắt đầu lại.',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistoryCard({
    required List<StreakHistoryItem> history,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ChatStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 19,
                color: AppColors.streakOrange,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lịch sử cập nhật chuỗi gần đây',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Các buổi học Video Call gần nhất được hệ thống điểm danh tự động',
            style: ChatStyles.metaText,
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: ChatStyles.tealPrimary),
              ),
            )
          else if (history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2ECEE)),
              ),
              child: const Text(
                'Chưa có lịch sử điểm danh buổi học Video Call nào. Vào phòng học và tham gia Video Call để ghi nhận buổi đầu tiên!',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            )
          else
            Column(
              children: history.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2ECEE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: item.streakAwarded
                              ? AppColors.streakBg
                              : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.streakAwarded
                              ? Icons.local_fire_department_rounded
                              : Icons.videocam_outlined,
                          size: 18,
                          color: item.streakAwarded
                              ? AppColors.streakOrange
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.roomName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.sessionTitle} • ${_formatHistoryTime(item.updatedAt)} • Học ${item.attendedMinutes}p',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.streakAwarded
                              ? AppColors.streakBg
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.streakAwarded
                              ? '+1 chuỗi 🔥'
                              : 'Chưa đủ ${item.minMinutes}p',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.streakAwarded
                                ? const Color(0xFFC2410C)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String subtext;
  final Color? highlightBorder;

  const _KpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtext,
    this.highlightBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlightBorder ?? const Color(0xFFE2ECEE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 11.8,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WeekDayColumn extends StatelessWidget {
  final DailyStreakDay day;

  const _WeekDayColumn({required this.day});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Widget inner;

    if (day.isCompleted) {
      bg = AppColors.streakOrange;
      border = AppColors.streakOrange;
      inner = const Icon(
        Icons.local_fire_department_rounded,
        size: 22,
        color: Colors.white,
      );
    } else if (day.hasPartialProgress) {
      bg = AppColors.streakBg;
      border = const Color(0xFFFDBA74);
      inner = Text(
        '${day.completedMinutes}p',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFFC2410C),
        ),
      );
    } else if (day.isToday) {
      bg = ChatStyles.tealSoftBg;
      border = ChatStyles.tealPrimary;
      inner = const Text(
        '0p',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: ChatStyles.tealDark,
        ),
      );
    } else if (day.isFuture) {
      bg = Colors.white;
      border = const Color(0xFFE2E8F0);
      inner = const SizedBox.shrink();
    } else {
      bg = const Color(0xFFF1F5F9);
      border = const Color(0xFFCBD5E1);
      inner = const Text(
        '-',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message:
              '${day.shortWeekdayLabel} (${day.date.day}/${day.date.month}): ${day.completedMinutes}/${day.goalMinutes} phút',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: border,
                width: day.isToday ? 2.2 : 1.3,
              ),
            ),
            alignment: Alignment.center,
            child: inner,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day.isToday ? 'Hôm nay' : day.shortWeekdayLabel,
          style: TextStyle(
            fontSize: day.isToday ? 11.5 : 12,
            fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
            color: day.isToday ? ChatStyles.tealDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${day.date.day}/${day.date.month}',
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _RuleBullet extends StatelessWidget {
  final String text;

  const _RuleBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(
            Icons.circle,
            size: 6,
            color: ChatStyles.tealPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
