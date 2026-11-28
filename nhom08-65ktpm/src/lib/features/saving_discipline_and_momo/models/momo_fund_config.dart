import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/saving_calculator.dart';
import 'saving_plan.dart';

class MoMoFundConfig {
  final String tripId;
  final String fundName;
  final String hostUserId;
  final String hostName;
  final String momoPhoneNumber;
  final String? momoFundDeeplink;
  final String? qrCodeUrl;
  final double targetTotalAmount;
  final double currentCollectedAmount;
  final SavingFrequency defaultFrequency;
  final double? suggestedPerMemberAmount;
  final String currency;
  final DateTime updatedAt;

  const MoMoFundConfig({
    required this.tripId,
    required this.fundName,
    required this.hostUserId,
    required this.hostName,
    required this.momoPhoneNumber,
    this.momoFundDeeplink,
    this.qrCodeUrl,
    required this.targetTotalAmount,
    this.currentCollectedAmount = 0.0,
    this.defaultFrequency = SavingFrequency.weekly,
    this.suggestedPerMemberAmount,
    this.currency = 'VND',
    required this.updatedAt,
  });

  /// Vietnamese unit label for a [SavingFrequency] cycle.
  static String cycleUnitLabel(SavingFrequency frequency) => switch (frequency) {
        SavingFrequency.daily => 'ngày',
        SavingFrequency.weekly => 'tuần',
        SavingFrequency.monthly => 'tháng',
      };

  /// Computes the suggested per-member contribution per cycle using the group split formula.
  static double computeSuggestedPerMemberAmount({
    required double targetTotalAmount,
    required int memberCount,
    required SavingFrequency frequency,
  }) {
    if (targetTotalAmount <= 0) return 0.0;
    final safeMembers = memberCount.clamp(1, 100);
    final perMemberTotal = targetTotalAmount / safeMembers;
    return switch (frequency) {
      SavingFrequency.daily => (perMemberTotal / 30).roundToDouble(),
      SavingFrequency.weekly => (perMemberTotal / 4).roundToDouble(),
      SavingFrequency.monthly => perMemberTotal.roundToDouble(),
    };
  }

  /// Resolves the per-cycle group split amount across Fund & Deposit screens.
  static double resolveGroupSplitAmount({
    required MoMoFundConfig? config,
    required double targetTotalAmount,
    required int memberCount,
  }) {
    final frequency = config?.defaultFrequency ?? SavingFrequency.weekly;
    if (config != null &&
        config.suggestedPerMemberAmount != null &&
        config.suggestedPerMemberAmount! > 0 &&
        (targetTotalAmount <= 0 ||
            (config.targetTotalAmount - targetTotalAmount).abs() <= 1)) {
      return config.suggestedPerMemberAmount!;
    }
    if (targetTotalAmount > 0) {
      return computeSuggestedPerMemberAmount(
        targetTotalAmount: targetTotalAmount,
        memberCount: memberCount,
        frequency: frequency,
      );
    }
    return 0.0;
  }

  /// Resolves deposit sheet defaults (`amount`, `cycleLabel`, `installmentIndex`, `frequency`)
  /// consistently between [MomoFundScreen] and `/momo-deposit`.
  static ({
    double amount,
    String cycleLabel,
    int installmentIndex,
    SavingFrequency? frequency,
  }) resolveDepositDefaults({
    required MoMoFundConfig? config,
    required SavingPlan? plan,
    required double targetTotalAmount,
    required int memberCount,
    double fallbackAmount = 212000.0,
  }) {
    final nextInstallment = (plan?.completedInstallments ?? 0) + 1;
    final totalInstallments = plan?.totalInstallments ?? 0;
    final groupSplitAmount = resolveGroupSplitAmount(
      config: config,
      targetTotalAmount: targetTotalAmount,
      memberCount: memberCount,
    );
    final frequency = plan?.frequency ?? config?.defaultFrequency;
    final defaultFreq = config?.defaultFrequency ?? SavingFrequency.weekly;
    final cycleLabel = totalInstallments > 0
        ? 'Kỳ $nextInstallment/$totalInstallments'
        : (groupSplitAmount > 0
            ? 'Theo ${cycleUnitLabel(defaultFreq)}'
            : 'Kỳ hiện tại');
    final amount = (plan != null && plan.installmentAmount > 0)
        ? plan.installmentAmount
        : (groupSplitAmount > 0 ? groupSplitAmount : fallbackAmount);
    return (
      amount: amount,
      cycleLabel: cycleLabel,
      installmentIndex: nextInstallment,
      frequency: frequency,
    );
  }

  /// Applies the host's saved group split & frequency to an existing [SavingPlan].
  static SavingPlan applyGroupConfigToPlan({
    required SavingPlan plan,
    required double perMemberTotalTarget,
    required SavingFrequency defaultFrequency,
  }) {
    final target =
        perMemberTotalTarget > 0 ? perMemberTotalTarget : plan.targetAmount;
    final effectiveDeadline = plan.deadlineDate.isAfter(plan.startDate)
        ? plan.deadlineDate
        : plan.startDate.add(const Duration(days: 30));
    final calc = SavingCalculator.calculateInstallments(
      targetAmount: target,
      startDate: plan.startDate,
      deadlineDate: effectiveDeadline,
      preferredFrequency: defaultFrequency,
      alreadyPaidAmount: plan.paidAmount,
    );
    final newStatus = (target > 0 && plan.paidAmount >= target)
        ? SavingPlanStatus.completed
        : SavingPlanStatus.active;
    return plan.copyWith(
      targetAmount: target,
      frequency: calc.frequency,
      installmentAmount: calc.installmentAmount,
      totalInstallments: calc.totalInstallments,
      status: newStatus,
    );
  }

  factory MoMoFundConfig.fromMap(Map<String, dynamic> map, {String? tripId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final freqStr = (map['defaultFrequency'] as String? ?? 'weekly').toLowerCase();
    final defaultFrequency = SavingFrequency.values.firstWhere(
      (e) => e.name == freqStr,
      orElse: () => SavingFrequency.weekly,
    );

    return MoMoFundConfig(
      tripId: tripId ?? (map['tripId'] as String? ?? ''),
      fundName: map['fundName'] as String? ?? '',
      hostUserId: map['hostUserId'] as String? ?? '',
      hostName: map['hostName'] as String? ?? '',
      momoPhoneNumber: map['momoPhoneNumber'] as String? ?? '',
      momoFundDeeplink: map['momoFundDeeplink'] as String?,
      qrCodeUrl: map['qrCodeUrl'] as String?,
      targetTotalAmount: (map['targetTotalAmount'] as num?)?.toDouble() ?? 0.0,
      currentCollectedAmount: (map['currentCollectedAmount'] as num?)?.toDouble() ?? 0.0,
      defaultFrequency: defaultFrequency,
      suggestedPerMemberAmount:
          (map['suggestedPerMemberAmount'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'VND',
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'fundName': fundName,
      'hostUserId': hostUserId,
      'hostName': hostName,
      'momoPhoneNumber': momoPhoneNumber,
      if (momoFundDeeplink != null) 'momoFundDeeplink': momoFundDeeplink,
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
      'targetTotalAmount': targetTotalAmount,
      'currentCollectedAmount': currentCollectedAmount,
      'defaultFrequency': defaultFrequency.name,
      if (suggestedPerMemberAmount != null)
        'suggestedPerMemberAmount': suggestedPerMemberAmount,
      'currency': currency,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MoMoFundConfig copyWith({
    String? tripId,
    String? fundName,
    String? hostUserId,
    String? hostName,
    String? momoPhoneNumber,
    String? momoFundDeeplink,
    String? qrCodeUrl,
    double? targetTotalAmount,
    double? currentCollectedAmount,
    SavingFrequency? defaultFrequency,
    double? suggestedPerMemberAmount,
    String? currency,
    DateTime? updatedAt,
  }) {
    return MoMoFundConfig(
      tripId: tripId ?? this.tripId,
      fundName: fundName ?? this.fundName,
      hostUserId: hostUserId ?? this.hostUserId,
      hostName: hostName ?? this.hostName,
      momoPhoneNumber: momoPhoneNumber ?? this.momoPhoneNumber,
      momoFundDeeplink: momoFundDeeplink ?? this.momoFundDeeplink,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      targetTotalAmount: targetTotalAmount ?? this.targetTotalAmount,
      currentCollectedAmount: currentCollectedAmount ?? this.currentCollectedAmount,
      defaultFrequency: defaultFrequency ?? this.defaultFrequency,
      suggestedPerMemberAmount:
          suggestedPerMemberAmount ?? this.suggestedPerMemberAmount,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
