import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_inset_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../models/deposit_record.dart';
import '../../models/member_streak.dart';
import '../../models/momo_fund_config.dart';
import '../../models/saving_plan.dart';
import '../../providers/momo_fund_provider.dart';
import '../../providers/receipt_approval_provider.dart';
import '../../providers/saving_plan_provider.dart';
import '../../providers/saving_streak_provider.dart';
import '../../utils/momo_deeplink_helper.dart';
import '../../utils/saving_streak_calculator.dart';
import 'deposit_due_warning_banner.dart';
import 'module_notification.dart';
import 'saving_journal_dialog.dart';

/// DailyYou-style interactive Saving Streak Calendar widget.
class DailyYouStreakCalendar extends ConsumerStatefulWidget {
  const DailyYouStreakCalendar({
    super.key,
    required this.tripId,
    required this.memberId,
    this.showDepositWarning = true,
  });

  final String tripId;
  final String memberId;
  final bool showDepositWarning;

  @override
  ConsumerState<DailyYouStreakCalendar> createState() =>
      _DailyYouStreakCalendarState();
}

class _DailyYouStreakCalendarState
    extends ConsumerState<DailyYouStreakCalendar> {
  late DateTime _visibleMonth;
  bool _isCheckingIn = false;

  SavingPlanParams get _params => SavingPlanParams(
        tripId: widget.tripId,
        memberId: widget.memberId,
      );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _returnToToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
    });
  }

  void _showInfoSnackBar(String message) {
    ModuleNotification.info(context, message);
  }

  Future<void> _openJournalForDay(
    DateTime date, {
    String? existingEmoji,
    String? existingNote,
    bool alreadyCheckedIn = false,
  }) async {
    if (_isCheckingIn) return;
    final result = await showDialog<SavingJournalDialogResult>(
      context: context,
      builder: (_) => SavingJournalDialog(
        date: date,
        initialEmoji: existingEmoji,
        initialNote: existingNote,
        alreadyCheckedIn: alreadyCheckedIn,
      ),
    );
    if (result == null || !mounted) return;

    setState(() => _isCheckingIn = true);
    try {
      await ref.read(savingStreakProvider(_params).notifier).checkIn(
            date: date,
            emoji: result.emoji,
            note: result.note,
          );
      if (mounted) {
        final now = DateTime.now();
        final isTodayDate =
            SavingStreakCalculator.formatIsoDate(date) ==
            SavingStreakCalculator.formatIsoDate(now);
        if (isTodayDate) {
          _returnToToday();
        }
        ModuleNotification.success(
          context,
          alreadyCheckedIn
              ? 'Đã cập nhật nhật ký tích góp ${result.emoji}!'
              : 'Điểm danh thành công ${result.emoji}!',
        );
      }
    } catch (e) {
      if (mounted) {
        ModuleNotification.error(context, 'Không thể lưu điểm danh: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final streakAsync = ref.watch(savingStreakStreamProvider(_params));
    final depositsAsync = ref.watch(memberDepositsStreamProvider(_params));
    final plansAsync = ref.watch(tripSavingPlansStreamProvider(widget.tripId));
    final membersAsync = ref.watch(tripMembersStreamProvider(widget.tripId));
    final fundConfigAsync = ref.watch(momoFundStreamProvider(widget.tripId));
    final tripSummaryAsync = ref.watch(tripSummaryStreamProvider(widget.tripId));
    final localJournals = ref.watch(savingJournalProvider(_params));

    final streak = streakAsync.value ??
        MemberStreak(memberId: widget.memberId, tripId: widget.tripId);
    final journals = {
      ...streak.journalEntries,
      ...localJournals,
    };
    final deposits = depositsAsync.value ?? const <DepositRecord>[];
    final plans = plansAsync.value ?? const <SavingPlan>[];
    final memberPlan = plans.where((p) => p.memberId == widget.memberId).firstOrNull;
    final fundConfig = fundConfigAsync.value;
    final tripSummary = tripSummaryAsync.value;
    final groupSplitAmount = fundConfig?.suggestedPerMemberAmount ?? 0.0;
    final membersList = membersAsync.value ?? const [];
    final currentMember = membersList
        .where((m) => m.userId == widget.memberId)
        .firstOrNull;
    final memberContributed = currentMember?.contributedAmount.toDouble() ?? 0.0;
    final memberTarget = (currentMember != null && currentMember.targetContribution > 0)
        ? currentMember.targetContribution.toDouble()
        : ((tripSummary != null && tripSummary.perMemberTarget > 0)
            ? tripSummary.perMemberTarget.toDouble()
            : ((fundConfig != null && fundConfig.targetTotalAmount > 0)
                ? (fundConfig.targetTotalAmount /
                        (membersList.isNotEmpty ? membersList.length : 1).clamp(1, 100))
                    .roundToDouble()
                : 0.0));
    final effectiveGroupSplitAmount = groupSplitAmount > 0
        ? groupSplitAmount
        : (fundConfig != null && fundConfig.targetTotalAmount > 0
            ? MoMoFundConfig.computeSuggestedPerMemberAmount(
                targetTotalAmount: fundConfig.targetTotalAmount,
                memberCount: membersList.isNotEmpty ? membersList.length : 1,
                frequency: fundConfig.defaultFrequency,
              )
            : 0.0);
    final joinedDay = currentMember == null
        ? null
        : DateTime(
            currentMember.joinedAt.year,
            currentMember.joinedAt.month,
            currentMember.joinedAt.day,
          );

    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final todayIso = SavingStreakCalculator.formatIsoDate(today);
    final checkedInToday = streak.depositDates.contains(todayIso);

    final termSummary = memberPlan != null
        ? SavingStreakCalculator.calculateTermStreak(
            plan: memberPlan,
            deposits: deposits,
            streak: streak,
            today: today,
          )
        : null;
    final depositReminder = widget.showDepositWarning
        ? (memberPlan != null
            ? SavingStreakCalculator.evaluateTodayDepositWarning(
                plan: memberPlan,
                deposits: deposits,
                today: today,
              )
            : (effectiveGroupSplitAmount > 0 && fundConfig != null
                ? SavingStreakCalculator.evaluateGroupDefaultDepositWarning(
                    frequency: fundConfig.defaultFrequency,
                    amount: effectiveGroupSplitAmount,
                    anchorDate: fundConfig.updatedAt,
                    deposits: deposits,
                    totalTargetAmount: memberTarget,
                    alreadySavedAmount: memberContributed,
                    deadlineDate: tripSummary?.startDate,
                    today: today,
                  )
                : null))
        : null;
    final nextIncoming = memberPlan != null
        ? SavingStreakCalculator.nextIncomingDeposit(
            plan: memberPlan,
            deposits: deposits,
            today: today,
          )
        : (effectiveGroupSplitAmount > 0 && fundConfig != null
            ? SavingStreakCalculator.nextIncomingDepositFromGroupDefault(
                frequency: fundConfig.defaultFrequency,
                amount: effectiveGroupSplitAmount,
                anchorDate: fundConfig.updatedAt,
                deposits: deposits,
                totalTargetAmount: memberTarget,
                alreadySavedAmount: memberContributed,
                deadlineDate: tripSummary?.startDate,
                today: today,
              )
            : null);

    final days = SavingStreakCalculator.buildMonthCalendar(
      month: _visibleMonth,
      streak: streak,
      deposits: deposits,
      journals: journals,
      plan: memberPlan,
      nextIncomingOverride: memberPlan == null ? nextIncoming : null,
      groupAnchorDate: memberPlan == null ? fundConfig?.updatedAt : null,
      scheduleDeadlineDate: tripSummary?.startDate,
      today: today,
    );

    final termUnit = switch (termSummary?.frequency) {
      SavingFrequency.daily => 'ngày',
      SavingFrequency.weekly => 'tuần',
      SavingFrequency.monthly => 'tháng',
      null => 'ngày',
    };
    final activeStreakCount = termSummary?.currentStreak ?? streak.currentStreak;
    final isOnStreak = termSummary?.isOnStreak ?? (streak.currentStreak > 0);
    final badgeLabel = termSummary != null
        ? (isOnStreak ? 'Chuỗi $activeStreakCount $termUnit' : 'Chưa vào chuỗi')
        : 'Chuỗi ${streak.currentStreak} ngày';

    final firstWeekdayOffset =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday - 1;
    final totalCells = firstWeekdayOffset + days.length;
    final currentMonth = DateTime(today.year, today.month);
    final isPastMonth = _visibleMonth.isBefore(currentMonth);
    final isFutureMonth = _visibleMonth.isAfter(currentMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'LỊCH CHUỖI KỶ LUẬT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: badgeLabel,
                tone: isOnStreak ? AppBadgeTone.amber : AppBadgeTone.neutral,
                icon: isOnStreak
                    ? Icons.local_fire_department_rounded
                    : Icons.timelapse_rounded,
              ),
            ],
          ),
        ),
        if (depositReminder != null && depositReminder.shouldWarn) ...[
          DepositDueWarningBanner(reminder: depositReminder),
          const SizedBox(height: 10),
        ],
        AppInsetCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStreakSummaryStrip(
                activeStreakCount: activeStreakCount,
                termUnit: termUnit,
                isOnStreak: isOnStreak,
                termSummary: termSummary,
                streak: streak,
              ),
              if (nextIncoming != null) ...[
                const SizedBox(height: 12),
                _buildIncomingDepositStrip(nextIncoming),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.outlineVariantSoft),
              const SizedBox(height: 10),
              _buildMonthBar(
                isPastMonth: isPastMonth,
                isFutureMonth: isFutureMonth,
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  _WeekdayHeader('T2'),
                  _WeekdayHeader('T3'),
                  _WeekdayHeader('T4'),
                  _WeekdayHeader('T5'),
                  _WeekdayHeader('T6'),
                  _WeekdayHeader('T7', isWeekend: true),
                  _WeekdayHeader('CN', isWeekend: true),
                ],
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.94,
                ),
                itemBuilder: (context, index) {
                  if (index < firstWeekdayOffset) {
                    return const SizedBox.shrink();
                  }
                  final cell = days[index - firstWeekdayOffset];
                  return _buildDayCell(
                    cell: cell,
                    isToday: cell.isoDate == todayIso,
                    todayDay: todayDay,
                    joinedDay: joinedDay,
                  );
                },
              ),
              const SizedBox(height: 14),
              _buildLegend(),
              const SizedBox(height: 14),
              _buildPrimaryCta(
                today: today,
                todayIso: todayIso,
                checkedInToday: checkedInToday,
                deposits: deposits,
                journals: journals,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakSummaryStrip({
    required int activeStreakCount,
    required String termUnit,
    required bool isOnStreak,
    required TermStreakSummary? termSummary,
    required MemberStreak streak,
  }) {
    final longest = termSummary?.longestStreak ?? streak.longestStreak;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isOnStreak ? null : AppColors.surfaceContainerHigh,
            gradient: isOnStreak
                ? const LinearGradient(
                    colors: [AppColors.amber, AppColors.error],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            isOnStreak
                ? Icons.local_fire_department_rounded
                : Icons.bolt_rounded,
            size: 22,
            color: isOnStreak
                ? AppColors.onPrimary
                : AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$activeStreakCount',
                    style: AppTheme.monoAmount(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '$termUnit liên tiếp',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                'Kỷ lục: $longest $termUnit',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (termSummary != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniStatPill(
                label: 'Đúng hạn',
                value: '${termSummary.onTimeTerms}',
                bgColor: AppColors.mintContainer,
                fgColor: AppColors.onMintContainer,
              ),
              const SizedBox(width: 6),
              _MiniStatPill(
                label: 'Trễ',
                value: '${termSummary.lateTerms}',
                bgColor: termSummary.lateTerms > 0
                    ? AppColors.errorContainer
                    : AppColors.surfaceContainerHigh,
                fgColor: termSummary.lateTerms > 0
                    ? AppColors.onErrorContainer
                    : AppColors.onSurfaceVariant,
              ),
            ],
          )
        else
          _MiniStatPill(
            label: 'Tổng',
            value: '${streak.totalDisciplinedDays}d',
            bgColor: AppColors.mintContainer,
            fgColor: AppColors.onMintContainer,
          ),
      ],
    );
  }

  Widget _buildIncomingDepositStrip(IncomingDepositInfo nextIncoming) {
    final amountText = nextIncoming.amount > 0
        ? MoMoDeeplinkHelper.formatVnd(nextIncoming.amount.round())
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 16,
            color: AppColors.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kỳ nạp tới: ${SavingStreakCalculator.formatIncomingDepositDate(nextIncoming)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimaryContainer,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (amountText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              amountText,
              style: AppTheme.monoAmount(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthBar({
    required bool isPastMonth,
    required bool isFutureMonth,
  }) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          _MonthNavButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () => _changeMonth(-1),
          ),
          if (isFutureMonth) ...[
            const SizedBox(width: 4),
            _buildTodayPill(),
          ],
          Expanded(
            child: Text(
              'Tháng ${_visibleMonth.month.toString().padLeft(2, '0')}/${_visibleMonth.year}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPastMonth) ...[
            _buildTodayPill(),
            const SizedBox(width: 4),
          ],
          _MonthNavButton(
            icon: Icons.chevron_right_rounded,
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPill() {
    return TextButton(
      onPressed: _returnToToday,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: const Text(
        'Hôm nay',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildDayCell({
    required StreakCalendarDay cell,
    required bool isToday,
    required DateTime todayDay,
    DateTime? joinedDay,
  }) {
    final Color bg;
    final Color fg;
    Widget? indicator;

    switch (cell.status) {
      case StreakDayStatus.checkedIn:
        bg = AppColors.mintContainer;
        fg = AppColors.onMintContainer;
        indicator = cell.emotionEmoji != null
            ? Text(
                cell.emotionEmoji!,
                style: const TextStyle(fontSize: 11, height: 1.1),
              )
            : Icon(Icons.check_rounded, size: 13, color: fg);
      case StreakDayStatus.late:
        bg = AppColors.errorContainer;
        fg = AppColors.onErrorContainer;
        indicator = Icon(Icons.schedule_rounded, size: 12, color: fg);
      case StreakDayStatus.pending:
        bg = AppColors.amberContainer;
        fg = AppColors.onAmberContainer;
        indicator = Icon(Icons.hourglass_top_rounded, size: 12, color: fg);
      case StreakDayStatus.missed:
        bg = AppColors.error.withValues(alpha: 0.08);
        fg = AppColors.error;
        indicator = Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
        );
      case StreakDayStatus.upcoming:
        if (cell.isNextDue) {
          bg = AppColors.primaryContainer;
          fg = AppColors.onPrimaryContainer;
          indicator = Icon(Icons.event_rounded, size: 12, color: fg);
        } else if (cell.isScheduledDue) {
          bg = AppColors.primaryContainer.withValues(alpha: 0.45);
          fg = AppColors.onPrimaryContainer;
          indicator = Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          );
        } else {
          bg = AppColors.surfaceContainerLow;
          fg = AppColors.onSurfaceVariant;
        }
    }

    final isPending = cell.status == StreakDayStatus.pending;
    final isLate = cell.status == StreakDayStatus.late;
    final isFuture = cell.date.isAfter(todayDay);
    final cellDay = DateTime(cell.date.year, cell.date.month, cell.date.day);
    final isBeforeJoined = joinedDay != null && cellDay.isBefore(joinedDay);
    final isFutureScheduled = cell.status == StreakDayStatus.upcoming &&
        (cell.isNextDue || cell.isScheduledDue) &&
        isFuture;
    final canTap = !isPending && !isLate && !isFuture && !isBeforeJoined;
    final hasNote =
        cell.journalNote != null && cell.journalNote!.trim().isNotEmpty;

    VoidCallback? onTap;
    if (isPending) {
      onTap = () => _showInfoSnackBar('Biên lai ngày này đang chờ Trưởng nhóm duyệt.');
    } else if (isLate) {
      onTap = () => _showInfoSnackBar('Biên lai ngày này được duyệt nhưng nộp trễ kỳ hạn.');
    } else if (isBeforeJoined) {
      onTap = () => _showInfoSnackBar('Bạn chưa tham gia chuyến đi vào ngày này.');
    } else if (canTap) {
      onTap = () => _openJournalForDay(
            cell.date,
            existingEmoji: cell.emotionEmoji,
            existingNote: cell.journalNote,
            alreadyCheckedIn: cell.status == StreakDayStatus.checkedIn,
          );
    } else if (isFutureScheduled) {
      onTap = () {
        final dd = cell.date.day.toString().padLeft(2, '0');
        final mm = cell.date.month.toString().padLeft(2, '0');
        final termText = cell.scheduledInstallmentIndex != null
            ? 'Kỳ ${cell.scheduledInstallmentIndex} '
            : '';
        final amountText = (cell.scheduledAmount ?? 0) > 0
            ? ' (${MoMoDeeplinkHelper.formatVnd(cell.scheduledAmount!.round())})'
            : '';
        _showInfoSnackBar(
          '${termText}dự kiến nạp ngày $dd/$mm/${cell.date.year}$amountText.',
        );
      };
    }

    final borderColor = isToday
        ? AppColors.primary
        : (cell.isNextDue
            ? AppColors.primary.withValues(alpha: 0.75)
            : AppColors.outlineVariantSoft);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: (isToday || cell.isNextDue) ? 1.5 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${cell.date.day}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: (isToday || cell.isNextDue)
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: fg,
                    height: 1.15,
                  ),
                ),
                if (indicator != null) ...[
                  const SizedBox(height: 2),
                  indicator,
                ],
              ],
            ),
            if (hasNote)
              Positioned(
                top: 3,
                right: 3,
                child: Icon(
                  Icons.sticky_note_2_rounded,
                  size: 9,
                  color: fg,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return const SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 10,
        runSpacing: 6,
        children: [
          _CalendarLegendDot(color: AppColors.mint, label: 'Đúng hạn'),
          _CalendarLegendDot(color: AppColors.amber, label: 'Chờ duyệt'),
          _CalendarLegendDot(color: AppColors.error, label: 'Trễ / Bỏ lỡ'),
          _CalendarLegendDot(color: AppColors.primary, label: 'Kỳ nạp tới'),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sticky_note_2_rounded,
                size: 11,
                color: AppColors.onMintContainer,
              ),
              SizedBox(width: 4),
              Text(
                'Ghi chú',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCta({
    required DateTime today,
    required String todayIso,
    required bool checkedInToday,
    required List<DepositRecord> deposits,
    required Map<String, ({String emoji, String note})> journals,
  }) {
    final pendingToday = !checkedInToday &&
        deposits.any(
          (d) =>
              d.status == DepositStatus.pending &&
              SavingStreakCalculator.formatIsoDate(d.depositDate) == todayIso,
        );
    return AppPrimaryButton(
      label: _isCheckingIn
          ? 'Đang ghi nhận...'
          : (pendingToday
              ? 'Đang chờ duyệt hôm nay'
              : (checkedInToday
                  ? 'Cập nhật nhật ký hôm nay'
                  : 'Điểm danh hôm nay')),
      icon: pendingToday
          ? Icons.hourglass_top_rounded
          : (checkedInToday
              ? Icons.edit_note_rounded
              : Icons.local_fire_department_rounded),
      backgroundColor: pendingToday
          ? AppColors.amber
          : (checkedInToday ? AppColors.primary : AppColors.mint),
      onPressed: (_isCheckingIn || pendingToday)
          ? null
          : () {
              final todayJournal = journals[todayIso];
              _openJournalForDay(
                today,
                existingEmoji: todayJournal?.emoji,
                existingNote: todayJournal?.note,
                alreadyCheckedIn: checkedInToday,
              );
            },
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.outlineVariantSoft),
          ),
        ),
        icon: Icon(icon, size: 18, color: AppColors.onSurface),
        onPressed: onPressed,
      ),
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  const _MiniStatPill({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.fgColor,
  });

  final String label;
  final String value;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTheme.monoAmount(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader(this.label, {this.isWeekend = false});

  final String label;
  final bool isWeekend;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isWeekend
                ? AppColors.onSurfaceVariant.withValues(alpha: 0.72)
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _CalendarLegendDot extends StatelessWidget {
  const _CalendarLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
