import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/streak_board_model.dart';
import '../providers/chat_provider.dart';
import '../styles/chat_styles.dart';

/// Trang Dashboard "Bảng cập nhật chuỗi" (tập trung duy nhất vào Chuỗi phòng học):
/// - 4 thẻ KPI tổng quan: Chuỗi phòng cao nhất, Kỷ lục chuỗi phòng, Phòng đang giữ lửa, Thời lượng học tuần này
/// - Bố cục 2 cột rộng trên Desktop:
///   + Trái: Hoạt động học 7 ngày tuần này (T2 -> CN) + Danh sách chuỗi từng phòng học
///   + Phải: Cách giữ chuỗi phòng + Lịch sử điểm danh Video Call gần đây
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

    // Tính chỉ số hoàn toàn từ Chuỗi phòng học
    var topRoomStreak = 0;
    String? topRoomName;
    var bestRoomStreak = 0;
    var activeRoomsCount = 0;
    var litTodayCount = 0;

    for (final room in rooms) {
      final effective = room.effectiveRoomStreak();
      if (effective > 0) activeRoomsCount++;
      if (room.isStreakLitToday()) litTodayCount++;
      if (effective > topRoomStreak) {
        topRoomStreak = effective;
        topRoomName = room.name;
      }
      if (room.bestStreak > bestRoomStreak) {
        bestRoomStreak = room.bestStreak;
      }
    }
    if (topRoomStreak > bestRoomStreak) bestRoomStreak = topRoomStreak;

    final weekDays = board?.weekDays ??
        StreakBoardData.buildCurrentWeekDays(
          referenceDate: DateTime.now(),
          dailyGoalMinutes: dailyGoal,
          logsByDateKey: const {},
        );
    final todayMinutes = board?.todayMinutes ?? 0;
    final totalWeekMinutes = weekDays.fold<int>(
      0,
      (sum, d) => sum + d.completedMinutes,
    );
    final activeDaysThisWeek =
        weekDays.where((d) => d.completedMinutes > 0).length;

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

              // 4 thẻ KPI tổng quan Chuỗi phòng
              _buildKpiGrid(
                topRoomStreak: topRoomStreak,
                topRoomName: topRoomName,
                bestRoomStreak: bestRoomStreak,
                activeRoomsCount: activeRoomsCount,
                litTodayCount: litTodayCount,
                totalRoomsCount: rooms.length,
                totalWeekMinutes: totalWeekMinutes,
                todayMinutes: todayMinutes,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Bố cục Dashboard 2 cột rộng hiển thị đầy đủ
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 920;

                  final leftColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWeekActivityCard(
                        weekDays: weekDays,
                        activeDaysThisWeek: activeDaysThisWeek,
                        isLoading: isLoading && board == null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildRoomStreaksCard(rooms),
                    ],
                  );

                  final rightColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStreakRulesCard(),
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
                    'Theo dõi chuỗi từng phòng học, thời lượng luyện Video Call và lịch sử điểm danh',
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
    required int topRoomStreak,
    required String? topRoomName,
    required int bestRoomStreak,
    required int activeRoomsCount,
    required int litTodayCount,
    required int totalRoomsCount,
    required int totalWeekMinutes,
    required int todayMinutes,
  }) {
    final cards = [
      _KpiCard(
        icon: Icons.local_fire_department_rounded,
        iconBg: AppColors.streakBg,
        iconColor: AppColors.streakOrange,
        label: 'Chuỗi phòng cao nhất',
        value: '$topRoomStreak ngày',
        subtext: topRoomName != null
            ? 'Tại phòng: $topRoomName'
            : 'Vào buổi Video Call để thắp lửa',
        highlightBorder: const Color(0xFFFDBA74),
      ),
      _KpiCard(
        icon: Icons.emoji_events_rounded,
        iconBg: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
        label: 'Kỷ lục chuỗi phòng',
        value: 'Kỷ lục: $bestRoomStreak ngày',
        subtext: 'Chuỗi dài nhất từng đạt trong phòng',
      ),
      _KpiCard(
        icon: Icons.groups_rounded,
        iconBg: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
        label: 'Phòng đang giữ lửa',
        value: '$activeRoomsCount / $totalRoomsCount phòng',
        subtext: '$litTodayCount phòng đã thắp lửa hôm nay',
      ),
      _KpiCard(
        icon: Icons.videocam_rounded,
        iconBg: ChatStyles.tealSoftBg,
        iconColor: ChatStyles.tealPrimary,
        label: 'Thời lượng học tuần này',
        value: '$totalWeekMinutes phút',
        subtext: 'Hôm nay đã học $todayMinutes phút',
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

  Widget _buildWeekActivityCard({
    required List<DailyStreakDay> weekDays,
    required int activeDaysThisWeek,
    required bool isLoading,
  }) {
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
                      'Hoạt động học 7 ngày tuần này',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ghi nhận tự động số phút học qua Video Call mỗi ngày trong tuần',
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
                  '$activeDaysThisWeek/7 ngày học',
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
        ],
      ),
    );
  }

  Widget _buildRoomStreaksCard(List<ConversationModel> rooms) {
    final sorted = [...rooms]..sort(
        (a, b) {
          final cmp = b.effectiveRoomStreak().compareTo(a.effectiveRoomStreak());
          if (cmp != 0) return cmp;
          return b.bestStreak.compareTo(a.bestStreak);
        },
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
                              '${room.targetLang.toUpperCase()} • ${room.levelLabel} • Kỷ lục: ${room.bestStreak} ngày',
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

  Widget _buildStreakRulesCard() {
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 19,
                color: ChatStyles.tealDark,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cách giữ chuỗi phòng học',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ChatStyles.tealDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _RuleBullet(
            text:
                'Tham gia buổi học Video Call do Chủ phòng hoặc Trợ giảng mở và học đủ số phút tối thiểu để cộng +1 chuỗi phòng.',
          ),
          SizedBox(height: 6),
          _RuleBullet(
            text:
                'Bỏ lỡ trọn vẹn 1 ngày không học, chuỗi phòng sẽ đặt lại về 0 (kỷ lục cao nhất vẫn được lưu lại).',
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
                  'Lịch sử điểm danh gần đây',
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
    final hasStudied = day.completedMinutes > 0;
    Color bg;
    Color border;
    Widget inner;

    if (hasStudied) {
      bg = AppColors.streakOrange;
      border = AppColors.streakOrange;
      inner = Text(
        '${day.completedMinutes}p',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
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
              '${day.shortWeekdayLabel} (${day.date.day}/${day.date.month}): Đã học ${day.completedMinutes} phút',
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
