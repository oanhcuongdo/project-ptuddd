part of 'saving_streak_calculator.dart';

({DateTime start, DateTime due}) _groupPeriodWindowImpl({
  required DateTime anchorDay,
  required SavingFrequency frequency,
  required int periodIndex,
  DateTime? deadlineDay,
}) {
  late final DateTime start;
  late final DateTime rawDue;
  switch (frequency) {
    case SavingFrequency.daily:
      rawDue = anchorDay.add(Duration(days: periodIndex - 1));
      start = rawDue;
    case SavingFrequency.weekly:
      start = anchorDay.add(Duration(days: (periodIndex - 1) * 7));
      rawDue = anchorDay.add(Duration(days: periodIndex * 7));
    case SavingFrequency.monthly:
      start = periodIndex == 1
          ? anchorDay
          : SavingCalculator.addCalendarMonths(anchorDay, periodIndex - 1)
              .add(const Duration(days: 1));
      rawDue = SavingCalculator.addCalendarMonths(anchorDay, periodIndex);
  }
  final clampedDue = (periodIndex == 1 &&
          deadlineDay != null &&
          rawDue.isAfter(deadlineDay) &&
          !deadlineDay.isBefore(start))
      ? deadlineDay
      : rawDue;
  return (start: start, due: clampedDue);
}

({
  TodayDepositReminder reminder,
  IncomingDepositInfo? nextIncoming,
}) _evaluateGroupDefaultScheduleImpl({
  required SavingFrequency frequency,
  required double amount,
  required DateTime anchorDate,
  required List<DepositRecord> deposits,
  required double totalTargetAmount,
  required double alreadySavedAmount,
  DateTime? deadlineDate,
  DateTime? today,
}) {
  if (amount <= 0) {
    return (reminder: TodayDepositReminder.none(frequency), nextIncoming: null);
  }
  final todayDay = SavingStreakCalculator._toLocalDay(today ?? DateTime.now());
  final deadlineDay =
      deadlineDate != null ? SavingStreakCalculator._toLocalDay(deadlineDate) : null;
  if (deadlineDay != null && todayDay.isAfter(deadlineDay)) {
    return (reminder: TodayDepositReminder.none(frequency), nextIncoming: null);
  }

  final activeDeposits =
      deposits.where((d) => d.status != DepositStatus.rejected).toList();
  final approvedSum = activeDeposits
      .where((d) => d.status == DepositStatus.approved)
      .fold<double>(0.0, (s, d) => s + d.amount);
  final pendingSum = activeDeposits
      .where((d) => d.status == DepositStatus.pending)
      .fold<double>(0.0, (s, d) => s + d.amount);
  final effectiveTotalSaved =
      (alreadySavedAmount > approvedSum ? alreadySavedAmount : approvedSum) +
          pendingSum;

  if (totalTargetAmount > 0 && effectiveTotalSaved + 1e-6 >= totalTargetAmount) {
    return (reminder: TodayDepositReminder.none(frequency), nextIncoming: null);
  }

  bool isDayCoveredByDepositTerm(DateTime day) {
    for (final d in activeDeposits) {
      final depDay = SavingStreakCalculator._toLocalDay(d.depositDate);
      final termFreq = d.termFrequency ?? frequency;
      final spanDays = SavingStreakCalculator._termSpanDays(termFreq);
      if (termFreq == SavingFrequency.daily) {
        if (SavingStreakCalculator._isSameDay(depDay, day)) return true;
      } else if (d.termDueDate != null) {
        final dueDay = SavingStreakCalculator._toLocalDay(d.termDueDate!);
        final termStart = dueDay.subtract(Duration(days: spanDays - 1));
        if (!day.isBefore(termStart) && !day.isAfter(dueDay)) {
          return true;
        }
      } else if (termFreq == SavingFrequency.weekly) {
        final endDay = depDay.add(const Duration(days: 6));
        if (!day.isBefore(depDay) && !day.isAfter(endDay)) {
          return true;
        }
      } else {
        final monthEnd = SavingCalculator.addCalendarMonths(depDay, 1);
        if (!day.isBefore(depDay) && day.isBefore(monthEnd)) {
          return true;
        }
      }
    }
    return false;
  }

  final rawAnchor = SavingStreakCalculator._toLocalDay(anchorDate);
  final anchorDay =
      (frequency == SavingFrequency.daily && todayDay.isBefore(rawAnchor))
          ? todayDay
          : rawAnchor;
  final paidTermsCount = (effectiveTotalSaved + 1e-6) ~/ amount;

  var overdueCount = 0;
  ({int index, DateTime due})? firstOverdue;
  ({int index, DateTime due})? dueToday;
  IncomingDepositInfo? nextIncoming;

  for (var period = 1; period <= 3650; period++) {
    final window = _groupPeriodWindowImpl(
      anchorDay: anchorDay,
      frequency: frequency,
      periodIndex: period,
      deadlineDay: deadlineDay,
    );
    if (deadlineDay != null && window.due.isAfter(deadlineDay)) {
      break;
    }

    final coveredByRecord = activeDeposits.any((d) {
          final depDay = SavingStreakCalculator._toLocalDay(d.depositDate);
          return (!depDay.isBefore(window.start) && !depDay.isAfter(window.due));
        }) ||
        isDayCoveredByDepositTerm(window.due) ||
        (frequency == SavingFrequency.daily &&
            isDayCoveredByDepositTerm(todayDay) &&
            SavingStreakCalculator._isSameDay(window.due, todayDay));
    final covered = (paidTermsCount >= period) || coveredByRecord;

    if (window.due.isBefore(todayDay)) {
      if (!covered) {
        overdueCount += 1;
        firstOverdue ??= (index: period, due: window.due);
      }
      continue;
    }

    if (!covered && SavingStreakCalculator._isSameDay(window.due, todayDay)) {
      dueToday ??= (index: period, due: window.due);
    }

    if (!covered) {
      nextIncoming = IncomingDepositInfo(
        installmentIndex: period,
        dueDate: window.due,
        amount: amount,
        daysUntilDue:
            SavingStreakCalculator._calendarDayDiff(todayDay, window.due),
        frequency: frequency,
      );
      break;
    }

    if (period > 1 && window.due.isAfter(todayDay)) {
      // Skip forward past pre-paid future cycles up to the first unpaid one.
      continue;
    }
  }

  final TodayDepositReminder reminder;
  if (overdueCount > 0 && firstOverdue != null) {
    reminder = TodayDepositReminder(
      shouldWarn: true,
      urgency: DepositReminderUrgency.overdue,
      frequency: frequency,
      installmentIndex: firstOverdue.index,
      dueDate: firstOverdue.due,
      amountDue: amount,
      overdueTermCount: overdueCount,
    );
  } else if (dueToday != null) {
    reminder = TodayDepositReminder(
      shouldWarn: true,
      urgency: DepositReminderUrgency.dueToday,
      frequency: frequency,
      installmentIndex: dueToday.index,
      dueDate: dueToday.due,
      amountDue: amount,
    );
  } else {
    reminder = TodayDepositReminder.none(frequency);
  }

  return (reminder: reminder, nextIncoming: nextIncoming);
}

List<StreakCalendarDay> _buildMonthCalendarImpl({
  required DateTime month,
  required MemberStreak streak,
  required List<DepositRecord> deposits,
  required Map<String, ({String emoji, String note})> journals,
  SavingPlan? plan,
  DateTime? planStartDate,
  IncomingDepositInfo? nextIncomingOverride,
  DateTime? groupAnchorDate,
  DateTime? scheduleDeadlineDate,
  DateTime? today,
}) {
  final todayDay = SavingStreakCalculator._toLocalDay(today ?? DateTime.now());
  final lateSet = plan != null
      ? SavingStreakCalculator.lateDepositIsoDates(plan: plan, deposits: deposits)
      : const <String>{};
  final crossTermFilled = plan != null
      ? SavingStreakCalculator._crossTermFilledDates(
          plan: plan,
          deposits: deposits,
          todayDay: todayDay,
        )
      : const <String>{};
  final approvedDepositDates = deposits
      .where((d) => d.status == DepositStatus.approved)
      .map((d) => SavingStreakCalculator.formatIsoDate(
          SavingStreakCalculator._toLocalDay(d.depositDate)))
      .where((iso) => !lateSet.contains(iso));
  final checkedSet = {
    ...streak.depositDates.where((iso) => !lateSet.contains(iso)),
    ...approvedDepositDates,
    ...crossTermFilled.where((iso) => !lateSet.contains(iso)),
  };
  final pendingSet = deposits
      .where((d) => d.status == DepositStatus.pending)
      .map((d) => SavingStreakCalculator.formatIsoDate(
          SavingStreakCalculator._toLocalDay(d.depositDate)))
      .toSet();

  final effectiveStart = planStartDate ?? plan?.startDate;
  final firstActivityDay = plan != null
      ? SavingStreakCalculator._toLocalDay(plan.startDate)
      : SavingStreakCalculator._resolveFirstActivityDay(
          streak: streak,
          deposits: deposits,
          planStartDate: effectiveStart,
        );
  final isPeriodicPlan = plan != null && plan.frequency != SavingFrequency.daily;
  final missedDueDates = isPeriodicPlan
      ? SavingStreakCalculator._missedTermDueIsoDates(
          plan: plan,
          deposits: deposits,
          streak: streak,
          todayDay: todayDay,
        )
      : const <String>{};
  final coverage = plan != null
      ? SavingStreakCalculator._prepareCoverageSnapshot(
          plan: plan,
          deposits: deposits,
          today: todayDay,
        )
      : null;
  final nextIncoming = plan != null
      ? SavingStreakCalculator.nextIncomingDeposit(
          plan: plan,
          deposits: deposits,
          today: todayDay,
        )
      : nextIncomingOverride;
  final nextDueIso = nextIncoming != null
      ? SavingStreakCalculator.formatIsoDate(nextIncoming.dueDate)
      : null;
  final scheduledMetaByIso = <String, ({int index, double amount})>{};
  if (nextIncoming != null && nextDueIso != null) {
    scheduledMetaByIso[nextDueIso] = (
      index: nextIncoming.installmentIndex,
      amount: nextIncoming.amount,
    );
  }
  if (coverage != null && plan != null) {
    if (plan.frequency != SavingFrequency.daily) {
      for (var i = 0; i < coverage.schedule.length; i++) {
        final item = coverage.schedule[i];
        final dueDay = SavingStreakCalculator._toLocalDay(item.dueDate);
        if (dueDay.isBefore(todayDay) || coverage.isTermCovered(i)) continue;
        scheduledMetaByIso[SavingStreakCalculator.formatIsoDate(dueDay)] = (
          index: item.index,
          amount: item.amount,
        );
      }
    }
  } else if (plan == null &&
      nextIncoming != null &&
      nextIncoming.frequency != SavingFrequency.daily) {
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final deadlineDay = scheduleDeadlineDate != null
        ? SavingStreakCalculator._toLocalDay(scheduleDeadlineDate)
        : null;
    final anchorDay = groupAnchorDate != null
        ? SavingStreakCalculator._toLocalDay(groupAnchorDate)
        : SavingStreakCalculator._toLocalDay(nextIncoming.dueDate);
    var termIndex =
        groupAnchorDate != null ? nextIncoming.installmentIndex : 0;
    var cursor = SavingStreakCalculator._toLocalDay(nextIncoming.dueDate);
    while (true) {
      termIndex += 1;
      if (groupAnchorDate != null) {
        cursor = _groupPeriodWindowImpl(
          anchorDay: anchorDay,
          frequency: nextIncoming.frequency,
          periodIndex: termIndex,
          deadlineDay: deadlineDay,
        ).due;
      } else if (nextIncoming.frequency == SavingFrequency.weekly) {
        cursor = cursor.add(const Duration(days: 7));
      } else {
        cursor = SavingCalculator.addCalendarMonths(anchorDay, termIndex);
      }
      if (cursor.isAfter(monthEnd)) break;
      if (deadlineDay != null && cursor.isAfter(deadlineDay)) break;
      if (!cursor.isBefore(todayDay)) {
        scheduledMetaByIso[SavingStreakCalculator.formatIsoDate(cursor)] = (
          index: termIndex,
          amount: nextIncoming.amount,
        );
      }
    }
  }

  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final cells = <StreakCalendarDay>[];

  for (var day = 1; day <= daysInMonth; day++) {
    final date = DateTime(month.year, month.month, day);
    final iso = SavingStreakCalculator.formatIsoDate(date);
    final journal = journals[iso];

    final StreakDayStatus status;
    if (lateSet.contains(iso)) {
      status = StreakDayStatus.late;
    } else if (checkedSet.contains(iso)) {
      status = StreakDayStatus.checkedIn;
    } else if (pendingSet.contains(iso)) {
      status = StreakDayStatus.pending;
    } else if (date.isAfter(todayDay)) {
      status = StreakDayStatus.upcoming;
    } else if (isPeriodicPlan) {
      status = missedDueDates.contains(iso)
          ? StreakDayStatus.missed
          : StreakDayStatus.upcoming;
    } else if (firstActivityDay != null &&
        !date.isBefore(firstActivityDay) &&
        date.isBefore(todayDay)) {
      status = StreakDayStatus.missed;
    } else {
      status = StreakDayStatus.upcoming;
    }

    final scheduledMeta =
        status == StreakDayStatus.upcoming ? scheduledMetaByIso[iso] : null;
    final isNextDue =
        status == StreakDayStatus.upcoming && nextDueIso == iso;

    cells.add(
      StreakCalendarDay(
        date: date,
        isoDate: iso,
        status: status,
        emotionEmoji: journal?.emoji,
        journalNote: journal?.note,
        isNextDue: isNextDue,
        isScheduledDue: scheduledMeta != null,
        scheduledInstallmentIndex: scheduledMeta?.index,
        scheduledAmount: scheduledMeta?.amount,
      ),
    );
  }

  return cells;
}
