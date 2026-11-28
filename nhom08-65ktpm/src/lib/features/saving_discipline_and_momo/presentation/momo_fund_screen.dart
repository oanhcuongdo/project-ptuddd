import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/local_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../models/trip_member.dart';
import '../models/deposit_record.dart';
import '../models/member_streak.dart';
import '../models/momo_fund_config.dart';
import '../models/saving_plan.dart';
import '../providers/momo_fund_provider.dart';
import '../providers/receipt_approval_provider.dart';
import '../utils/momo_deeplink_helper.dart';
import '../utils/saving_streak_calculator.dart';
import 'approve_receipt_screen.dart';
import 'deposit_receipt_sheet.dart';
import 'screens/momo_payment_screen.dart';
import 'screens/saving_plan_screen.dart';
import 'setup_momo_sheet.dart';
import 'widgets/daily_you_streak_calendar.dart';
import 'widgets/deposit_due_warning_banner.dart';
import 'widgets/fund_progress_card.dart';
import 'widgets/module_notification.dart';
import 'widgets/module_provider_scope.dart';

/// Tab 2 — Quỹ MoMo (Module 2 — Trọng tâm Liên kết Quỹ trong app với Quỹ nhóm MoMo).
/// Gồm: Thẻ liên kết MoMo, Tiến độ Gây dựng Quỹ, Kỳ đóng quỹ hiện tại,
/// Lịch chuỗi kỷ luật Saving Streak kiểu DailyYou, Hàng đợi duyệt biên lai & Bảng xếp hạng thành viên.
class MomoFundScreen extends StatelessWidget {
  const MomoFundScreen({
    super.key,
    this.tripId = 'trip_demo_01',
    this.memberId = 'member_demo_01',
    this.memberName = 'Đỗ Đình An',
    this.isHost,
    this.tripTargetBudget,
    this.tripDepartureDate,
    this.tripMemberCount,
  });

  final String tripId;
  final String memberId;
  final String memberName;
  final bool? isHost;
  final double? tripTargetBudget;
  final DateTime? tripDepartureDate;
  final int? tripMemberCount;

  @override
  Widget build(BuildContext context) {
    return ModuleProviderScope(
      child: _MomoFundContent(
        tripId: tripId,
        memberId: memberId,
        memberName: memberName,
        isHost: isHost,
        tripTargetBudget: tripTargetBudget,
        tripDepartureDate: tripDepartureDate,
        tripMemberCount: tripMemberCount,
      ),
    );
  }
}

class _MomoFundContent extends ConsumerStatefulWidget {
  const _MomoFundContent({
    required this.tripId,
    required this.memberId,
    required this.memberName,
    this.isHost,
    this.tripTargetBudget,
    this.tripDepartureDate,
    this.tripMemberCount,
  });

  final String tripId;
  final String memberId;
  final String memberName;
  final bool? isHost;
  final double? tripTargetBudget;
  final DateTime? tripDepartureDate;
  final int? tripMemberCount;

  @override
  ConsumerState<_MomoFundContent> createState() => _MomoFundContentState();
}

class _MomoFundContentState extends ConsumerState<_MomoFundContent> {
  Future<void> _openSetupMoMoSheet([
    MoMoFundConfig? currentConfig,
    int memberCount = 1,
    double? fallbackTarget,
  ]) async {
    final realTarget = (fallbackTarget != null && fallbackTarget > 0)
        ? fallbackTarget
        : ((widget.tripTargetBudget != null && widget.tripTargetBudget! > 0)
            ? widget.tripTargetBudget!
            : (currentConfig != null && currentConfig.targetTotalAmount > 0
                ? currentConfig.targetTotalAmount
                : 8450000.0));
    final savedName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SetupMomoSheet(
        tripId: widget.tripId,
        hostUserId: currentConfig?.hostUserId ?? widget.memberId,
        hostName: currentConfig?.hostName ?? widget.memberName,
        targetTotalAmount: realTarget,
        memberCount: memberCount,
        initialFrequency:
            currentConfig?.defaultFrequency ?? SavingFrequency.weekly,
        initialFundName: currentConfig?.fundName ?? 'Quỹ chuyến đi',
        initialPhoneNumber: currentConfig?.momoPhoneNumber ?? '',
        initialFundLink: currentConfig?.momoFundDeeplink ?? '',
        initialQrCodeUrl: currentConfig?.qrCodeUrl,
      ),
    );
    if (savedName != null && mounted) {
      ModuleNotification.success(
        context,
        'Đã lưu cấu hình "$savedName" & đồng bộ mức chia quỹ!',
      );
    }
  }

  void _openPaymentScreen(MoMoFundConfig config, {double? suggestedAmount}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MomoPaymentScreen(
          config: config,
          memberName: widget.memberName,
          suggestedAmount: suggestedAmount,
        ),
      ),
    );
  }

  void _openApproveScreen() {
    final router = GoRouter.maybeOf(context);
    if (router != null &&
        widget.tripId == 'trip_demo_01' &&
        widget.memberId == 'member_demo_01') {
      context.push('/trip/momo/approve');
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ApproveReceiptScreen(
            tripId: widget.tripId,
            reviewerId: widget.memberId,
          ),
        ),
      );
    }
  }

  void _openSavingPlanScreen({
    MoMoFundConfig? fundConfig,
    int memberCount = 1,
    double? tripTargetBudget,
    DateTime? tripDepartureDate,
  }) {
    final totalTarget =
        (fundConfig != null && fundConfig.targetTotalAmount > 0)
            ? fundConfig.targetTotalAmount
            : (tripTargetBudget ?? widget.tripTargetBudget ?? 3000000);
    final divisor = (widget.tripMemberCount ?? memberCount).clamp(1, 100);
    final perMemberDefault = (totalTarget / divisor).roundToDouble();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SavingPlanScreen(
          tripId: widget.tripId,
          memberId: widget.memberId,
          memberName: widget.memberName,
          defaultTargetAmount: perMemberDefault,
          defaultFrequency:
              fundConfig?.defaultFrequency ?? SavingFrequency.weekly,
          tripDepartureDate: tripDepartureDate ?? widget.tripDepartureDate,
        ),
      ),
    );
  }

  Future<void> _openDepositSheet({
    required MoMoFundConfig? fundConfig,
    required SavingPlan? memberPlan,
    required double targetAmount,
    required int memberCount,
    double fallbackAmount = 212000.0,
  }) async {
    final defaults = MoMoFundConfig.resolveDepositDefaults(
      config: fundConfig,
      plan: memberPlan,
      targetTotalAmount: targetAmount,
      memberCount: memberCount,
      fallbackAmount: fallbackAmount,
    );
    final termDueDate = memberPlan != null
        ? SavingStreakCalculator.termDueDateForInstallment(
            plan: memberPlan,
            installmentIndex: defaults.installmentIndex,
          )
        : null;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepositReceiptSheet(
        tripId: widget.tripId,
        memberId: widget.memberId,
        memberName: memberPlan?.memberName ?? widget.memberName,
        fundName: fundConfig?.fundName ?? 'Quỹ nhóm MoMo',
        amount: defaults.amount,
        installmentIndex: defaults.installmentIndex,
        cycleLabel: defaults.cycleLabel,
        termDueDate: termDueDate,
        termFrequency: defaults.frequency,
        momoLink: fundConfig?.momoFundDeeplink,
        phoneNumber: fundConfig?.momoPhoneNumber,
        qrData: fundConfig?.qrCodeUrl,
        allowAmountEdit: true,
      ),
    );
  }

  (String, AppBadgeTone) _memberCycleBadge(List<DepositRecord> memberDeposits) {
    if (memberDeposits.isEmpty) {
      return ('Chưa nộp', AppBadgeTone.neutral);
    }
    final latest = memberDeposits.first;
    return switch (latest.status) {
      DepositStatus.approved => ('Đã xác nhận', AppBadgeTone.mint),
      DepositStatus.pending => ('Chờ duyệt', AppBadgeTone.amber),
      DepositStatus.rejected => ('Bị từ chối', AppBadgeTone.error),
    };
  }

  @override
  Widget build(BuildContext context) {
    final fundConfigAsync = ref.watch(momoFundStreamProvider(widget.tripId));
    final depositsAsync = ref.watch(tripDepositsStreamProvider(widget.tripId));
    final plansAsync = ref.watch(tripSavingPlansStreamProvider(widget.tripId));
    final streaksAsync = ref.watch(tripStreaksStreamProvider(widget.tripId));
    final tripSummaryAsync = ref.watch(tripSummaryStreamProvider(widget.tripId));
    final tripMembersAsync = ref.watch(tripMembersStreamProvider(widget.tripId));

    ref.listen(tripSavingPlansStreamProvider(widget.tripId), (_, next) {
      final planList = next.asData?.value;
      if (planList == null) return;
      final myPlan = planList.where((p) => p.memberId == widget.memberId).firstOrNull;
      final myDeposits = (ref.read(tripDepositsStreamProvider(widget.tripId)).value ??
              const <DepositRecord>[])
          .where((d) => d.memberId == widget.memberId)
          .toList();
      ref.read(localNotificationServiceProvider).syncSavingPlanReminder(
            plan: myPlan,
            memberDeposits: myDeposits,
            tripId: widget.tripId,
            memberId: widget.memberId,
          );
    });
    ref.listen(tripDepositsStreamProvider(widget.tripId), (_, next) {
      final depositList = next.asData?.value;
      if (depositList == null) return;
      final planList =
          ref.read(tripSavingPlansStreamProvider(widget.tripId)).value ??
              const <SavingPlan>[];
      final myPlan = planList.where((p) => p.memberId == widget.memberId).firstOrNull;
      final myDeposits =
          depositList.where((d) => d.memberId == widget.memberId).toList();
      ref.read(localNotificationServiceProvider).syncSavingPlanReminder(
            plan: myPlan,
            memberDeposits: myDeposits,
            tripId: widget.tripId,
            memberId: widget.memberId,
          );
    });

    final fundConfig = fundConfigAsync.value;
    final deposits = depositsAsync.value ?? const <DepositRecord>[];
    final plans = List<SavingPlan>.from(plansAsync.value ?? const <SavingPlan>[]);
    final memberPlan = plans.where((p) => p.memberId == widget.memberId).firstOrNull;
    final streaks = streaksAsync.value ?? const <MemberStreak>[];
    final tripSummary = tripSummaryAsync.value;
    final tripMembers = tripMembersAsync.value ?? const <TripMember>[];

    final isInitialLoading =
        (fundConfigAsync.isLoading && !fundConfigAsync.hasValue) ||
        (plansAsync.isLoading && !plansAsync.hasValue) ||
        (depositsAsync.isLoading && !depositsAsync.hasValue);
    final firstError = fundConfigAsync.error ??
        depositsAsync.error ??
        plansAsync.error ??
        streaksAsync.error ??
        tripSummaryAsync.error ??
        tripMembersAsync.error;

    final isLinked = fundConfig != null &&
        (fundConfig.momoPhoneNumber.isNotEmpty ||
            (fundConfig.momoFundDeeplink?.isNotEmpty ?? false) ||
            (fundConfig.qrCodeUrl?.isNotEmpty ?? false));
    final fundName = fundConfig?.fundName ?? 'Quỹ nhóm MoMo';
    final isHost = widget.isHost ??
        (tripSummary != null
            ? tripSummary.hostId == widget.memberId
            : (fundConfig != null && fundConfig.hostUserId == widget.memberId));

    final pendingCount =
        deposits.where((r) => r.status == DepositStatus.pending).length;

    final effectiveTargetBudget = widget.tripTargetBudget ??
        (tripSummary != null && tripSummary.targetBudget > 0
            ? tripSummary.targetBudget.toDouble()
            : null);
    final effectiveDepartureDate = widget.tripDepartureDate ?? tripSummary?.startDate;

    final totalPlanTarget = plans.fold<double>(0.0, (sum, p) => sum + p.targetAmount);
    final totalPlanPaid = plans.fold<double>(0.0, (sum, p) => sum + p.paidAmount);
    final collectedAmount = fundConfig?.currentCollectedAmount ??
        (tripSummary != null && tripSummary.totalSavedAmount > 0
            ? tripSummary.totalSavedAmount.toDouble()
            : totalPlanPaid);
    final targetAmount = (effectiveTargetBudget != null && effectiveTargetBudget > 0)
        ? effectiveTargetBudget
        : ((fundConfig != null && fundConfig.targetTotalAmount > 0)
            ? fundConfig.targetTotalAmount
            : (totalPlanTarget > 0 ? totalPlanTarget : 0.0));
    final memberCount = tripMembers.isNotEmpty
        ? tripMembers.length
        : (plans.isNotEmpty ? plans.length : (widget.tripMemberCount ?? 1));
    final groupDefaultFrequency =
        fundConfig?.defaultFrequency ?? SavingFrequency.weekly;
    final groupSplitAmount = MoMoFundConfig.resolveGroupSplitAmount(
      config: fundConfig,
      targetTotalAmount: targetAmount,
      memberCount: memberCount,
    );
    final perMemberTotalTarget = (tripSummary != null && tripSummary.perMemberTarget > 0)
        ? tripSummary.perMemberTarget.toDouble()
        : (targetAmount > 0
            ? (targetAmount / memberCount.clamp(1, 100)).roundToDouble()
            : 212000.0);
    final fallbackDepositAmount =
        groupSplitAmount > 0 ? groupSplitAmount : perMemberTotalTarget;

    final cycleLabel = (memberPlan != null && memberPlan.totalInstallments > 0)
        ? 'Kỳ hiện tại (Kỳ ${memberPlan.completedInstallments + 1}/${memberPlan.totalInstallments})'
        : 'Kỳ hiện tại';
    final installmentText = (memberPlan != null && memberPlan.installmentAmount > 0)
        ? '${MoMoDeeplinkHelper.formatVnd(memberPlan.installmentAmount.round())} / kỳ'
        : (groupSplitAmount > 0
            ? '${MoMoDeeplinkHelper.formatVnd(groupSplitAmount.round())} / ${MoMoFundConfig.cycleUnitLabel(groupDefaultFrequency)} (đề xuất)'
            : 'Chạm Nộp biên lai để đóng quỹ');
    final currentMemberDeposits =
        deposits.where((d) => d.memberId == widget.memberId).toList();
    final currentMember = tripMembers
        .where((m) => m.userId == widget.memberId)
        .firstOrNull;
    final currentMemberSaved = currentMember?.contributedAmount.toDouble() ?? 0.0;
    final currentMemberTarget =
        (currentMember != null && currentMember.targetContribution > 0)
            ? currentMember.targetContribution.toDouble()
            : perMemberTotalTarget;
    final depositReminder = memberPlan != null
        ? SavingStreakCalculator.evaluateTodayDepositWarning(
            plan: memberPlan,
            deposits: currentMemberDeposits,
          )
        : (groupSplitAmount > 0
            ? SavingStreakCalculator.evaluateGroupDefaultDepositWarning(
                frequency: groupDefaultFrequency,
                amount: groupSplitAmount,
                anchorDate: fundConfig?.updatedAt ?? DateTime.now(),
                deposits: currentMemberDeposits,
                totalTargetAmount: currentMemberTarget,
                alreadySavedAmount: currentMemberSaved,
                deadlineDate: effectiveDepartureDate,
              )
            : null);
    final nextIncoming = memberPlan != null
        ? SavingStreakCalculator.nextIncomingDeposit(
            plan: memberPlan,
            deposits: currentMemberDeposits,
          )
        : (groupSplitAmount > 0
            ? SavingStreakCalculator.nextIncomingDepositFromGroupDefault(
                frequency: groupDefaultFrequency,
                amount: groupSplitAmount,
                anchorDate: fundConfig?.updatedAt ?? DateTime.now(),
                deposits: currentMemberDeposits,
                totalTargetAmount: currentMemberTarget,
                alreadySavedAmount: currentMemberSaved,
                deadlineDate: effectiveDepartureDate,
              )
            : null);
    final nextDepositText = nextIncoming != null
        ? 'Kỳ tới: ${SavingStreakCalculator.formatIncomingDepositDate(nextIncoming)}'
        : null;

    final streakByMember = {for (final s in streaks) s.memberId: s};
    final planByMember = {for (final p in plans) p.memberId: p};
    final leaderboardEntries = <_LeaderboardEntry>[
      for (final plan in plans)
        _LeaderboardEntry(
          memberId: plan.memberId,
          memberName: plan.memberName,
          paidAmount: plan.paidAmount,
          targetAmount: plan.targetAmount,
          plan: plan,
          fallbackStreak: 0,
        ),
      for (final member in tripMembers)
        if (!planByMember.containsKey(member.userId))
          _LeaderboardEntry(
            memberId: member.userId,
            memberName: member.displayName,
            paidAmount: member.contributedAmount.toDouble(),
            targetAmount: member.targetContribution > 0
                ? member.targetContribution.toDouble()
                : perMemberTotalTarget,
            plan: null,
            fallbackStreak: member.currentStreak,
          ),
    ];
    leaderboardEntries.sort((a, b) {
      final ratioA = a.targetAmount > 0 ? a.paidAmount / a.targetAmount : 0.0;
      final ratioB = b.targetAmount > 0 ? b.paidAmount / b.targetAmount : 0.0;
      final cmp = ratioB.compareTo(ratioA);
      if (cmp != 0) return cmp;
      return b.paidAmount.compareTo(a.paidAmount);
    });

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: () {
            if (GoRouter.maybeOf(context) != null) {
              context.go('/trips');
            } else {
              Navigator.of(context).maybePop();
            }
          },
          icon: const Icon(Icons.chevron_left, color: AppColors.onPrimaryContainer),
          label: const Text('Chuyến đi', style: TextStyle(color: AppColors.onPrimaryContainer)),
        ),
        title: const Text('Quỹ MoMo'),
        actions: [
          IconButton(
            tooltip: 'Kế hoạch tích góp',
            icon: const Icon(Icons.event_repeat_rounded, color: AppColors.onPrimaryContainer),
            onPressed: () => _openSavingPlanScreen(
              fundConfig: fundConfig,
              memberCount: memberCount,
              tripTargetBudget: effectiveTargetBudget,
              tripDepartureDate: effectiveDepartureDate,
            ),
          ),
          if (isHost)
            IconButton(
              tooltip: 'Thiết lập kế hoạch & Liên kết MoMo',
              icon: const Icon(Icons.settings_outlined, color: AppColors.onPrimaryContainer),
              onPressed: () => _openSetupMoMoSheet(
                fundConfig,
                memberCount,
                effectiveTargetBudget,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (isInitialLoading)
            const LinearProgressIndicator(minHeight: 2),
          if (isHost && pendingCount > 0)
            Material(
              color: AppColors.amberContainer,
              child: InkWell(
                onTap: _openApproveScreen,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.amber.withValues(alpha: 0.45)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.pending_actions_rounded,
                        color: AppColors.onAmberContainer,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Có $pendingCount biên lai đang chờ Trưởng nhóm duyệt',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onAmberContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.onAmberContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
          if (firstError != null) ...[
            AppInsetCard(
              borderRadius: 12,
              padding: const EdgeInsets.all(12),
              borderColor: AppColors.error,
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Không thể đồng bộ dữ liệu quỹ: $firstError',
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(momoFundStreamProvider(widget.tripId));
                      ref.invalidate(tripDepositsStreamProvider(widget.tripId));
                      ref.invalidate(tripSavingPlansStreamProvider(widget.tripId));
                      ref.invalidate(tripStreaksStreamProvider(widget.tripId));
                      ref.invalidate(tripSummaryStreamProvider(widget.tripId));
                      ref.invalidate(tripMembersStreamProvider(widget.tripId));
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // 1. Thẻ Liên kết Quỹ nhóm MoMo
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.momoContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'M',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.momo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLinked ? fundName : 'Chưa liên kết Quỹ nhóm MoMo',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          AppStatusBadge(
                            label: isLinked
                                ? 'Đã liên kết Quỹ nhóm MoMo'
                                : 'Cần Trưởng nhóm gắn link/QR',
                            tone: isLinked ? AppBadgeTone.mint : AppBadgeTone.amber,
                            icon: isLinked ? Icons.verified : Icons.link_off,
                          ),
                        ],
                      ),
                    ),
                    if (isHost)
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: IconButton(
                          tooltip: 'Cấu hình liên kết MoMo',
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: AppColors.outlineVariantSoft),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.onSurfaceVariant),
                          onPressed: () => _openSetupMoMoSheet(
                            fundConfig,
                            memberCount,
                            effectiveTargetBudget,
                          ),
                        ),
                      ),
                  ],
                ),
                if (isLinked && fundConfig.momoPhoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.outlineVariantSoft),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.phone_iphone_rounded, size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Chủ quỹ: ${fundConfig.hostName} • ${fundConfig.momoPhoneNumber}',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: isLinked
                            ? 'Mở MoMo nạp quỹ'
                            : (isHost
                                ? 'Gắn link / QR MoMo'
                                : 'Chờ Trưởng nhóm liên kết MoMo'),
                        icon: isLinked ? Icons.open_in_new : Icons.qr_code_scanner,
                        backgroundColor: AppColors.momo,
                        onPressed: isLinked
                            ? () => _openPaymentScreen(
                                  fundConfig,
                                  suggestedAmount:
                                      memberPlan?.installmentAmount ?? fallbackDepositAmount,
                                )
                            : (isHost
                                ? () => _openSetupMoMoSheet(
                                      fundConfig,
                                      memberCount,
                                      effectiveTargetBudget,
                                    )
                                : null),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (depositReminder != null && depositReminder.shouldWarn) ...[
            DepositDueWarningBanner(
              reminder: depositReminder,
              onDepositTap: () => _openDepositSheet(
                fundConfig: fundConfig,
                memberPlan: memberPlan,
                targetAmount: targetAmount,
                memberCount: memberCount,
                fallbackAmount: fallbackDepositAmount,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Thẻ Tiến độ Gây dựng Quỹ & Kỳ đóng quỹ hiện tại
          FundProgressCard(
            collectedAmount: collectedAmount,
            targetAmount: targetAmount,
            memberCount: memberCount,
            cycleLabel: cycleLabel,
            installmentText: installmentText,
            nextDepositText: nextDepositText,
            onDepositPressed: () => _openDepositSheet(
              fundConfig: fundConfig,
              memberPlan: memberPlan,
              targetAmount: targetAmount,
              memberCount: memberCount,
              fallbackAmount: fallbackDepositAmount,
            ),
          ),
          const SizedBox(height: 24),

          // 4. Lịch Chuỗi Kỷ luật Tích góp (Saving Streak Calendar — kế thừa DailyYou)
          DailyYouStreakCalendar(
            tripId: widget.tripId,
            memberId: widget.memberId,
            showDepositWarning: false,
          ),
          const SizedBox(height: 24),

          // 5. Bảng xếp hạng & Tiến độ đóng góp từng thành viên
          AppSectionHeader(
            title: 'Bảng xếp hạng đóng góp',
            trailing: isHost
                ? GestureDetector(
                    onTap: _openApproveScreen,
                    child: const Text(
                      'Duyệt biên lai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  )
                : null,
          ),
          AppInsetCard(
            child: leaderboardEntries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Chưa có thành viên nào tạo kế hoạch tích góp.',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(leaderboardEntries.length, (idx) {
                      final entry = leaderboardEntries[idx];
                      final memberDeposits =
                          deposits.where((d) => d.memberId == entry.memberId).toList();
                      final (badgeText, tone) = _memberCycleBadge(memberDeposits);
                      final memberStreak = streakByMember[entry.memberId];
                      final streakCount = entry.plan != null
                          ? SavingStreakCalculator.calculateTermStreak(
                              plan: entry.plan!,
                              deposits: memberDeposits,
                              streak: memberStreak,
                            ).currentStreak
                          : (memberStreak?.currentStreak ?? entry.fallbackStreak);

                      return Column(
                        children: [
                          ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: idx == 0
                                  ? AppColors.amberContainer
                                  : AppColors.surfaceContainerHigh,
                              child: Text(
                                MoMoDeeplinkHelper.formatInitials(entry.memberName),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: idx == 0
                                      ? AppColors.onAmberContainer
                                      : AppColors.onSurface,
                                ),
                              ),
                            ),
                            title: Text(
                              '${idx + 1}. ${entry.memberName}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${MoMoDeeplinkHelper.formatVnd(entry.paidAmount.round())} / ${MoMoDeeplinkHelper.formatVnd(entry.targetAmount.round())}',
                              style: AppTheme.monoAmount(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 13,
                                      color: streakCount > 0
                                          ? AppColors.amber
                                          : AppColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$streakCount',
                                      style: AppTheme.monoAmount(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: streakCount > 0
                                            ? AppColors.onAmberContainer
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                AppStatusBadge(label: badgeText, tone: tone),
                              ],
                            ),
                          ),
                          if (idx < leaderboardEntries.length - 1) const Divider(indent: 72),
                        ],
                      );
                    }),
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

class _LeaderboardEntry {
  const _LeaderboardEntry({
    required this.memberId,
    required this.memberName,
    required this.paidAmount,
    required this.targetAmount,
    required this.plan,
    required this.fallbackStreak,
  });

  final String memberId;
  final String memberName;
  final double paidAmount;
  final double targetAmount;
  final SavingPlan? plan;
  final int fallbackStreak;
}
