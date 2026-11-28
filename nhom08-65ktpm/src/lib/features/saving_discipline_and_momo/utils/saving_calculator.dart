import '../models/saving_plan.dart';

class InstallmentItem {
  final int index;
  final double amount;
  final DateTime dueDate;
  final bool isAdjusted;

  const InstallmentItem({
    required this.index,
    required this.amount,
    required this.dueDate,
    this.isAdjusted = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallmentItem &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          amount == other.amount &&
          dueDate.year == other.dueDate.year &&
          dueDate.month == other.dueDate.month &&
          dueDate.day == other.dueDate.day &&
          isAdjusted == other.isAdjusted;

  @override
  int get hashCode =>
      index.hashCode ^
      amount.hashCode ^
      dueDate.year.hashCode ^
      dueDate.month.hashCode ^
      dueDate.day.hashCode ^
      isAdjusted.hashCode;
}

class SavingPlanCalculationResult {
  final SavingFrequency frequency;
  final int totalInstallments;
  final double installmentAmount;
  final double finalInstallmentAmount;
  final List<InstallmentItem> schedule;
  final double totalAmount;

  const SavingPlanCalculationResult({
    required this.frequency,
    required this.totalInstallments,
    required this.installmentAmount,
    required this.finalInstallmentAmount,
    required this.schedule,
    required this.totalAmount,
  });
}

class SavingCalculator {
  const SavingCalculator();

  /// Adds [monthsToAdd] calendar months while clamping day-of-month to month length
  /// (e.g. Jan 31 + 1 month -> Feb 28/29 instead of overflowing into March).
  static DateTime addCalendarMonths(DateTime date, int monthsToAdd) {
    final zeroBasedMonth = (date.month - 1) + monthsToAdd;
    final targetYear = date.year + (zeroBasedMonth ~/ 12);
    final targetMonth = (zeroBasedMonth % 12) + 1;
    final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final clampedDay =
        date.day <= lastDayOfTargetMonth ? date.day : lastDayOfTargetMonth;
    return DateTime(targetYear, targetMonth, clampedDay);
  }

  /// Calculates saving installments partitioned over the countdown to departure.
  /// 
  /// Rules:
  /// - [targetAmount] must be > 0.
  /// - [deadlineDate] must be after [startDate].
  /// - If days remaining < 7, frequency automatically defaults to [SavingFrequency.daily].
  /// - If days remaining < 28 and frequency is [SavingFrequency.monthly], defaults to [SavingFrequency.weekly] or [SavingFrequency.daily].
  /// - Standard installments are rounded to the nearest 1,000 VND: `((raw / 1000).round() * 1000)`.
  /// - Any fractional remainder is adjusted into the final installment so that the sum matches [targetAmount] exactly.
  static SavingPlanCalculationResult calculateInstallments({
    required double targetAmount,
    required DateTime startDate,
    required DateTime deadlineDate,
    SavingFrequency preferredFrequency = SavingFrequency.weekly,
    double roundTo = 1000.0,
    double alreadyPaidAmount = 0.0,
  }) {
    if (targetAmount <= 0) {
      throw ArgumentError.value(targetAmount, 'targetAmount', 'Target amount must be greater than 0.');
    }

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final deadline = DateTime(deadlineDate.year, deadlineDate.month, deadlineDate.day);

    final totalDays = deadline.difference(start).inDays;
    if (totalDays <= 0) {
      throw ArgumentError('Deadline date must be at least 1 day after start date.');
    }

    SavingFrequency effectiveFrequency = preferredFrequency;
    if (totalDays < 7) {
      effectiveFrequency = SavingFrequency.daily;
    } else if (totalDays < 28 && preferredFrequency == SavingFrequency.monthly) {
      effectiveFrequency = SavingFrequency.weekly;
    }

    final effectivePaid = alreadyPaidAmount < 0 ? 0.0 : alreadyPaidAmount;
    final remainingAmount = targetAmount - effectivePaid;
    if (remainingAmount <= 0) {
      return SavingPlanCalculationResult(
        frequency: effectiveFrequency,
        totalInstallments: 0,
        installmentAmount: 0.0,
        finalInstallmentAmount: 0.0,
        schedule: const [],
        totalAmount: 0.0,
      );
    }

    int intervals;
    int dayStep;

    switch (effectiveFrequency) {
      case SavingFrequency.daily:
        intervals = totalDays;
        dayStep = 1;
        break;
      case SavingFrequency.weekly:
        intervals = (totalDays / 7).floor();
        if (intervals < 1) intervals = 1;
        dayStep = 7;
        break;
      case SavingFrequency.monthly:
        var monthCount = 0;
        while (!addCalendarMonths(start, monthCount + 1).isAfter(deadline)) {
          monthCount += 1;
        }
        final lastFullMonthEnd =
            monthCount == 0 ? start : addCalendarMonths(start, monthCount);
        if (deadline.difference(lastFullMonthEnd).inDays >= 28) {
          monthCount += 1;
        }
        intervals = monthCount < 1 ? 1 : monthCount;
        dayStep = 30;
        break;
    }

    if (intervals == 1) {
      final item = InstallmentItem(
        index: 1,
        amount: remainingAmount,
        dueDate: deadline,
        isAdjusted: false,
      );
      return SavingPlanCalculationResult(
        frequency: effectiveFrequency,
        totalInstallments: 1,
        installmentAmount: remainingAmount,
        finalInstallmentAmount: remainingAmount,
        schedule: [item],
        totalAmount: remainingAmount,
      );
    }

    // Base installment amount rounded to nearest roundTo
    final rawAmountPerInterval = remainingAmount / intervals;
    double roundedAmount = ((rawAmountPerInterval / roundTo).round() * roundTo).toDouble();
    if (roundedAmount <= 0) {
      roundedAmount = roundTo;
    }

    final totalForNMinus1 = roundedAmount * (intervals - 1);
    final lastInstallmentAmount = remainingAmount - totalForNMinus1;

    final schedule = <InstallmentItem>[];
    for (int i = 1; i < intervals; i++) {
      final dueDate = effectiveFrequency == SavingFrequency.monthly
          ? addCalendarMonths(start, i)
          : start.add(Duration(days: i * dayStep));
      schedule.add(
        InstallmentItem(
          index: i,
          amount: roundedAmount,
          dueDate: dueDate.isAfter(deadline) ? deadline : dueDate,
          isAdjusted: false,
        ),
      );
    }

    // Final installment
    schedule.add(
      InstallmentItem(
        index: intervals,
        amount: lastInstallmentAmount,
        dueDate: deadline,
        isAdjusted: lastInstallmentAmount != roundedAmount,
      ),
    );

    return SavingPlanCalculationResult(
      frequency: effectiveFrequency,
      totalInstallments: intervals,
      installmentAmount: roundedAmount,
      finalInstallmentAmount: lastInstallmentAmount,
      schedule: schedule,
      totalAmount: remainingAmount,
    );
  }
}
