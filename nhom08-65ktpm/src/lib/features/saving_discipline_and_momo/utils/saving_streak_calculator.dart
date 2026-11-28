import '../models/deposit_record.dart';
import '../models/member_streak.dart';
import '../models/saving_plan.dart';
import 'saving_calculator.dart';
import 'streak_models.dart';

export 'streak_models.dart';

part 'streak_calendar_builder.dart';

class _TermCoverageSnapshot {
  final SavingPlan plan;
  final DateTime todayDay;
  final DateTime startDay;
  final DateTime deadlineDay;
  final List<InstallmentItem> schedule;
  final List<DepositRecord> memberDeposits;
  final Map<int, List<DepositRecord>> approvedByTerm;
  final Set<int> pendingTerms;
  final Set<String> crossTermFilled;
  final Set<String> crossTermCoveredAll;
  final Set<String> activeDepositDates;
  final bool hasDepositToday;
  final double effectiveTotalSaved;
  final List<double> cumulativeTargets;

  const _TermCoverageSnapshot({
    required this.plan,
    required this.todayDay,
    required this.startDay,
    required this.deadlineDay,
    required this.schedule,
    required this.memberDeposits,
    required this.approvedByTerm,
    required this.pendingTerms,
    required this.crossTermFilled,
    required this.crossTermCoveredAll,
    required this.activeDepositDates,
    required this.hasDepositToday,
    required this.effectiveTotalSaved,
    required this.cumulativeTargets,
  });

  bool isTermCovered(int index) {
    final termIndex = index + 1;
    if (termIndex <= plan.completedInstallments) {
      return true;
    }
    if ((approvedByTerm[termIndex]?.isNotEmpty ?? false) ||
        pendingTerms.contains(termIndex)) {
      return true;
    }
    if (index < cumulativeTargets.length &&
        effectiveTotalSaved > 0 &&
        effectiveTotalSaved + 1e-6 >= cumulativeTargets[index]) {
      return true;
    }
    if (plan.frequency == SavingFrequency.daily) {
      final dueIso = SavingStreakCalculator.formatIsoDate(
        SavingStreakCalculator._toLocalDay(schedule[index].dueDate),
      );
      if (crossTermFilled.contains(dueIso)) return true;
    }
    return false;
  }
}

enum _TermOutcome { onTime, late, missed, open }

/// Pure domain helper for DailyYou-style saving streak calculations.
class SavingStreakCalculator {
  const SavingStreakCalculator._();

  /// Formats a [DateTime] as local `YYYY-MM-DD`.
  static String formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses a `YYYY-MM-DD` string into a local midnight [DateTime].
  static DateTime? parseIsoDate(String isoDate) {
    final parts = isoDate.trim().split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Normalizes a list of ISO date strings into sorted, unique local dates.
  static List<DateTime> normalizeDates(Iterable<String> isoDates) {
    final unique = <String, DateTime>{};
    for (final raw in isoDates) {
      final parsed = parseIsoDate(raw);
      if (parsed != null) {
        unique[formatIsoDate(parsed)] = parsed;
      }
    }
    final list = unique.values.toList()..sort();
    return list;
  }

  /// Computes the longest consecutive-day streak in [isoDates].
  static int calculateLongestStreak(Iterable<String> isoDates) {
    final dates = normalizeDates(isoDates);
    if (dates.isEmpty) return 0;

    var longest = 1;
    var run = 1;
    for (var i = 1; i < dates.length; i++) {
      final diffDays = _calendarDayDiff(dates[i - 1], dates[i]);
      if (diffDays == 1) {
        run += 1;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    return longest;
  }

  /// Computes the active consecutive-day streak relative to [referenceDate].
  ///
  /// A streak remains active if the most recent check-in is on [referenceDate]
  /// or 1 day prior (yesterday). If older than 1 day, the active streak is `0`.
  static int calculateCurrentStreak(
    Iterable<String> isoDates, {
    DateTime? referenceDate,
  }) {
    final dates = normalizeDates(isoDates);
    if (dates.isEmpty) return 0;

    final ref = _toLocalDay(referenceDate ?? DateTime.now());
    final latest = dates.last;
    final daysSinceLatest = _calendarDayDiff(latest, ref);
    if (daysSinceLatest > 1 || daysSinceLatest < 0) {
      // If latest is in the future, anchor from latest; if gap > 1 day, streak broke.
      if (daysSinceLatest > 1) return 0;
    }

    var streak = 1;
    for (var i = dates.length - 2; i >= 0; i--) {
      if (_calendarDayDiff(dates[i], dates[i + 1]) == 1) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Records a disciplined saving check-in on [checkInDate] and returns an updated [MemberStreak].
  static MemberStreak recordCheckIn(
    MemberStreak current,
    DateTime checkInDate, {
    DateTime? referenceDate,
  }) {
    final normalizedDay = _toLocalDay(checkInDate);
    final iso = formatIsoDate(normalizedDay);
    final updatedIsoSet = {...current.depositDates, iso};
    final sortedDates = normalizeDates(updatedIsoSet).map(formatIsoDate).toList();

    final ref = _toLocalDay(referenceDate ?? normalizedDay);
    final currentStreak = calculateCurrentStreak(sortedDates, referenceDate: ref);
    final longestCandidate = calculateLongestStreak(sortedDates);
    final longestStreak =
        longestCandidate > current.longestStreak ? longestCandidate : current.longestStreak;

    final latestDate = parseIsoDate(sortedDates.last);
    return current.copyWith(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastDepositDate: latestDate,
      depositDates: sortedDates,
      totalDisciplinedDays: sortedDates.length,
    );
  }

  /// Evaluates consecutive on-time saving terms for [plan] based on approved [deposits].
  ///
  /// A deposit is considered late if `depositDate` is after its term's `dueDate`.
  /// Late or missed terms break the active on-time streak while preserving [longestStreak].
  static TermStreakSummary calculateTermStreak({
    required SavingPlan plan,
    required List<DepositRecord> deposits,
    MemberStreak? streak,
    DateTime? today,
  }) {
    final todayDay = _toLocalDay(today ?? DateTime.now());
    final schedule = _buildTermSchedule(plan);
    if (schedule.isEmpty) {
      return TermStreakSummary(
        currentStreak: 0,
        longestStreak: 0,
        onTimeTerms: 0,
        lateTerms: 0,
        isOnStreak: false,
        frequency: plan.frequency,
      );
    }

    final approvedByTerm = _mapApprovedDepositsToTerms(
      plan: plan,
      schedule: schedule,
      deposits: deposits,
    );
    final checkInTerms = _mapManualCheckInsToTerms(
      plan: plan,
      schedule: schedule,
      deposits: deposits,
      streak: streak,
    );

    final priorCarry = _priorCarryStreak(
      plan: plan,
      deposits: deposits,
      streak: streak,
      todayDay: todayDay,
    );
    var onTimeTerms = priorCarry;
    var lateTerms = 0;
    var run = priorCarry;
    var longest = priorCarry;

    for (var i = 0; i < schedule.length; i++) {
      if (i > 0) {
        final termStart = _toLocalDay(schedule[i - 1].dueDate).add(
          const Duration(days: 1),
        );
        if (todayDay.isBefore(termStart)) {
          break;
        }
      }
      final termIndex = i + 1;
      final dueDay = _toLocalDay(schedule[i].dueDate);
      final termDeposits = approvedByTerm[termIndex] ?? const <DepositRecord>[];
      final hasManualCheckIn = checkInTerms.contains(termIndex);

      final _TermOutcome outcome;
      if (termDeposits.isNotEmpty) {
        final hasOnTime = termDeposits.any(
          (d) => !_isDepositLate(d: d, termDueDay: dueDay, plan: plan),
        );
        outcome = hasOnTime ? _TermOutcome.onTime : _TermOutcome.late;
      } else if (hasManualCheckIn) {
        outcome = _TermOutcome.onTime;
      } else if (todayDay.isAfter(dueDay)) {
        outcome = _TermOutcome.missed;
      } else {
        outcome = _TermOutcome.open;
      }

      switch (outcome) {
        case _TermOutcome.onTime:
          onTimeTerms += 1;
          run += 1;
          if (run > longest) longest = run;
        case _TermOutcome.late:
          lateTerms += 1;
          run = 0;
        case _TermOutcome.missed:
          run = 0;
        case _TermOutcome.open:
          // Current/future open term has not passed its due date yet, so stop scanning.
          break;
      }

      if (outcome == _TermOutcome.open) {
        break;
      }
    }

    return TermStreakSummary(
      currentStreak: run,
      longestStreak: longest,
      onTimeTerms: onTimeTerms,
      lateTerms: lateTerms,
      isOnStreak: run > 0,
      frequency: plan.frequency,
    );
  }

  /// Evaluates whether the member should be warned to deposit today based on [plan]'s term.
  ///
  /// - `daily`: warns on any active day in the schedule unless an approved/pending deposit
  ///   (or cross-term paid span) already covers today, or the user is ahead of schedule.
  /// - `weekly` / `monthly`: warns when an unpaid/non-pending term is due today or overdue.
  static TodayDepositReminder evaluateTodayDepositWarning({
    required SavingPlan plan,
    required List<DepositRecord> deposits,
    DateTime? today,
  }) {
    final coverage = _prepareCoverageSnapshot(
      plan: plan,
      deposits: deposits,
      today: today,
    );
    if (coverage == null || coverage.todayDay.isBefore(coverage.startDay)) {
      return TodayDepositReminder.none(plan.frequency);
    }

    final schedule = coverage.schedule;
    final todayDay = coverage.todayDay;
    var overdueCount = 0;
    InstallmentItem? firstOverdue;
    InstallmentItem? dueTodayItem;

    for (var i = 0; i < schedule.length; i++) {
      final dueDay = _toLocalDay(schedule[i].dueDate);
      final covered = coverage.isTermCovered(i);
      if (dueDay.isBefore(todayDay)) {
        if (!covered) {
          overdueCount += 1;
          firstOverdue ??= schedule[i];
        }
      } else if (_isSameDay(dueDay, todayDay)) {
        if (!covered &&
            !(plan.frequency == SavingFrequency.daily &&
                coverage.hasDepositToday)) {
          dueTodayItem ??= schedule[i];
        }
      }
    }

    if (overdueCount > 0 && firstOverdue != null) {
      return TodayDepositReminder(
        shouldWarn: true,
        urgency: DepositReminderUrgency.overdue,
        frequency: plan.frequency,
        installmentIndex: firstOverdue.index,
        dueDate: _toLocalDay(firstOverdue.dueDate),
        amountDue: firstOverdue.amount,
        overdueTermCount: overdueCount,
      );
    }

    if (dueTodayItem == null &&
        plan.frequency == SavingFrequency.daily &&
        !coverage.hasDepositToday &&
        !todayDay.isAfter(coverage.deadlineDay)) {
      dueTodayItem = _firstActiveUnpaidDailyTerm(coverage, todayDay);
    }

    if (dueTodayItem != null) {
      return TodayDepositReminder(
        shouldWarn: true,
        urgency: DepositReminderUrgency.dueToday,
        frequency: plan.frequency,
        installmentIndex: dueTodayItem.index,
        dueDate: _toLocalDay(dueTodayItem.dueDate),
        amountDue: dueTodayItem.amount,
      );
    }

    return TodayDepositReminder.none(plan.frequency);
  }

  /// Returns the next incoming deposit due date and amount for [plan], or `null` if finished.
  static IncomingDepositInfo? nextIncomingDeposit({
    required SavingPlan plan,
    required List<DepositRecord> deposits,
    DateTime? today,
  }) {
    final coverage = _prepareCoverageSnapshot(
      plan: plan,
      deposits: deposits,
      today: today,
    );
    if (coverage == null || coverage.todayDay.isAfter(coverage.deadlineDay)) {
      return null;
    }

    final schedule = coverage.schedule;
    final todayDay = coverage.todayDay;

    if (plan.frequency != SavingFrequency.daily) {
      for (var i = 0; i < schedule.length; i++) {
        final dueDay = _toLocalDay(schedule[i].dueDate);
        if (dueDay.isBefore(todayDay) || coverage.isTermCovered(i)) continue;
        return IncomingDepositInfo(
          installmentIndex: schedule[i].index,
          dueDate: dueDay,
          amount: schedule[i].amount,
          daysUntilDue: _calendarDayDiff(todayDay, dueDay),
          frequency: plan.frequency,
        );
      }
      return null;
    }

    // Daily plans: if today is active and uncovered, today is the next deposit day.
    if (!coverage.hasDepositToday && !todayDay.isBefore(coverage.startDay)) {
      final activeToday = _firstActiveUnpaidDailyTerm(coverage, todayDay);
      if (activeToday != null) {
        return IncomingDepositInfo(
          installmentIndex: activeToday.index,
          dueDate: todayDay,
          amount: activeToday.amount,
          daysUntilDue: 0,
          frequency: plan.frequency,
        );
      }
    }

    // Otherwise scan forward up to deadline to locate the next uncovered daily day.
    final firstScanDay = todayDay.isBefore(coverage.startDay)
        ? coverage.startDay
        : todayDay.add(const Duration(days: 1));
    for (var day = firstScanDay;
        !day.isAfter(coverage.deadlineDay);
        day = day.add(const Duration(days: 1))) {
      final iso = formatIsoDate(day);
      if (coverage.crossTermCoveredAll.contains(iso) ||
          coverage.activeDepositDates.contains(iso)) {
        continue;
      }
      final candidate = _firstActiveUnpaidDailyTerm(coverage, day);
      if (candidate != null) {
        return IncomingDepositInfo(
          installmentIndex: candidate.index,
          dueDate: day,
          amount: candidate.amount,
          daysUntilDue: _calendarDayDiff(todayDay, day),
          frequency: plan.frequency,
        );
      }
    }
    return null;
  }

  /// Evaluates whether the member should be warned to deposit today from the
  /// host's group default schedule when [SavingPlan] is not yet created.
  static TodayDepositReminder evaluateGroupDefaultDepositWarning({
    required SavingFrequency frequency,
    required double amount,
    required DateTime anchorDate,
    required List<DepositRecord> deposits,
    double totalTargetAmount = 0.0,
    double alreadySavedAmount = 0.0,
    DateTime? deadlineDate,
    DateTime? today,
  }) {
    return _evaluateGroupDefaultScheduleImpl(
      frequency: frequency,
      amount: amount,
      anchorDate: anchorDate,
      deposits: deposits,
      totalTargetAmount: totalTargetAmount,
      alreadySavedAmount: alreadySavedAmount,
      deadlineDate: deadlineDate,
      today: today,
    ).reminder;
  }

  /// Computes the next incoming deposit info from the host's group default cycle
  /// when the member has not created a personal [SavingPlan] yet.
  static IncomingDepositInfo? nextIncomingDepositFromGroupDefault({
    required SavingFrequency frequency,
    required double amount,
    required DateTime anchorDate,
    required List<DepositRecord> deposits,
    double totalTargetAmount = 0.0,
    double alreadySavedAmount = 0.0,
    DateTime? deadlineDate,
    DateTime? today,
  }) {
    return _evaluateGroupDefaultScheduleImpl(
      frequency: frequency,
      amount: amount,
      anchorDate: anchorDate,
      deposits: deposits,
      totalTargetAmount: totalTargetAmount,
      alreadySavedAmount: alreadySavedAmount,
      deadlineDate: deadlineDate,
      today: today,
    ).nextIncoming;
  }

  /// Formats a human-readable countdown label for an [IncomingDepositInfo].
  static String formatIncomingDepositDate(IncomingDepositInfo info) {
    final dd = info.dueDate.day.toString().padLeft(2, '0');
    final mm = info.dueDate.month.toString().padLeft(2, '0');
    final ddMm = '$dd/$mm';
    if (info.daysUntilDue <= 0) return 'Hôm nay ($ddMm)';
    if (info.daysUntilDue == 1) return 'Ngày mai ($ddMm)';
    return '$ddMm (Còn ${info.daysUntilDue} ngày)';
  }

  static InstallmentItem? _firstActiveUnpaidDailyTerm(
    _TermCoverageSnapshot coverage,
    DateTime day,
  ) {
    final schedule = coverage.schedule;
    for (var i = 0; i < schedule.length; i++) {
      final dueDay = _toLocalDay(schedule[i].dueDate);
      if (dueDay.isBefore(day) || coverage.isTermCovered(i)) continue;
      final windowStarted = i == 0
          ? !day.isBefore(coverage.startDay)
          : !_toLocalDay(schedule[i - 1].dueDate).isAfter(day);
      return windowStarted ? schedule[i] : null;
    }
    return null;
  }

  static _TermCoverageSnapshot? _prepareCoverageSnapshot({
    required SavingPlan plan,
    required List<DepositRecord> deposits,
    DateTime? today,
  }) {
    if (plan.status == SavingPlanStatus.completed ||
        (plan.targetAmount > 0 && plan.paidAmount >= plan.targetAmount)) {
      return null;
    }
    final schedule = _buildTermSchedule(plan);
    if (schedule.isEmpty) return null;

    final todayDay = _toLocalDay(today ?? DateTime.now());
    final startDay = _toLocalDay(plan.startDate);
    final deadlineDay = _toLocalDay(plan.deadlineDate);
    if (!deadlineDay.isAfter(startDay)) return null;

    final memberDeposits = plan.memberId.isEmpty
        ? deposits
        : deposits
            .where((d) => d.memberId.isEmpty || d.memberId == plan.memberId)
            .toList();

    final approvedSum = memberDeposits
        .where((d) => d.status == DepositStatus.approved)
        .fold<double>(0.0, (s, d) => s + d.amount);
    final pendingSum = memberDeposits
        .where((d) => d.status == DepositStatus.pending)
        .fold<double>(0.0, (s, d) => s + d.amount);
    final effectiveTotalSaved =
        (plan.paidAmount > approvedSum ? plan.paidAmount : approvedSum) +
            pendingSum;
    if (plan.targetAmount > 0 && effectiveTotalSaved + 1e-6 >= plan.targetAmount) {
      return null;
    }

    final cumulativeTargets = <double>[];
    var runningTarget = 0.0;
    for (final item in schedule) {
      runningTarget += item.amount;
      cumulativeTargets.add(runningTarget);
    }

    final approvedByTerm = _mapApprovedDepositsToTerms(
      plan: plan,
      schedule: schedule,
      deposits: memberDeposits,
    );
    final pendingTerms = _mapPendingDepositsToTerms(
      plan: plan,
      planStart: startDay,
      schedule: schedule,
      deposits: memberDeposits,
    );
    final crossTermFilled = _crossTermFilledDates(
      plan: plan,
      deposits: memberDeposits,
      todayDay: todayDay,
    );
    final crossTermCoveredAll = _crossTermFilledDates(
      plan: plan,
      deposits: memberDeposits,
      todayDay: todayDay,
      clampToToday: false,
    );
    final activeDepositDates = memberDeposits
        .where(
          (d) =>
              d.status == DepositStatus.approved ||
              d.status == DepositStatus.pending,
        )
        .map((d) => formatIsoDate(_toLocalDay(d.depositDate)))
        .toSet();

    final todayIso = formatIsoDate(todayDay);
    final hasDepositToday = crossTermFilled.contains(todayIso) ||
        activeDepositDates.contains(todayIso);

    return _TermCoverageSnapshot(
      plan: plan,
      todayDay: todayDay,
      startDay: startDay,
      deadlineDay: deadlineDay,
      schedule: schedule,
      memberDeposits: memberDeposits,
      approvedByTerm: approvedByTerm,
      pendingTerms: pendingTerms,
      crossTermFilled: crossTermFilled,
      crossTermCoveredAll: crossTermCoveredAll,
      activeDepositDates: activeDepositDates,
      hasDepositToday: hasDepositToday,
      effectiveTotalSaved: effectiveTotalSaved,
      cumulativeTargets: cumulativeTargets,
    );
  }

  static Set<int> _mapPendingDepositsToTerms({
    required SavingPlan plan,
    required DateTime planStart,
    required List<InstallmentItem> schedule,
    required List<DepositRecord> deposits,
  }) {
    final pendingTerms = <int>{};
    for (final d in deposits) {
      if (d.status != DepositStatus.pending) continue;
      final depDay = _toLocalDay(d.depositDate);
      final isDifferentFrequency =
          d.termFrequency != null && d.termFrequency != plan.frequency;
      if (isDifferentFrequency) {
        if (d.termDueDate != null) {
          final spanDays = _termSpanDays(d.termFrequency!);
          final dueDay = _toLocalDay(d.termDueDate!);
          final termStart = dueDay.subtract(Duration(days: spanDays - 1));
          for (var i = 0; i < schedule.length; i++) {
            final termPrevDue = i == 0
                ? planStart.subtract(const Duration(days: 1))
                : _toLocalDay(schedule[i - 1].dueDate);
            final termWindowStart = termPrevDue.add(const Duration(days: 1));
            final termDue = _toLocalDay(schedule[i].dueDate);
            if (!termWindowStart.isBefore(planStart) &&
                !dueDay.isBefore(termWindowStart) &&
                !termStart.isAfter(termDue)) {
              pendingTerms.add(i + 1);
            }
          }
          continue;
        }
        if (!depDay.isBefore(planStart)) {
          final matched = _matchTermWindow(
            depDay: depDay,
            planStart: planStart,
            schedule: schedule,
          );
          if (matched != null) {
            pendingTerms.add(matched);
          }
        }
        continue;
      }
      if (depDay.isBefore(planStart)) continue;
      final termIndex = _resolveTermIndexForSamePlan(
        deposit: d,
        planStart: planStart,
        schedule: schedule,
      );
      if (termIndex != null) {
        pendingTerms.add(termIndex);
      }
    }
    return pendingTerms;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns the due date for [installmentIndex] (1-indexed) in [plan]'s schedule.
  static DateTime? termDueDateForInstallment({
    required SavingPlan plan,
    required int installmentIndex,
  }) {
    final schedule = _buildTermSchedule(plan);
    if (schedule.isEmpty || installmentIndex < 1) return null;
    final idx = (installmentIndex - 1).clamp(0, schedule.length - 1);
    return schedule[idx].dueDate;
  }

  /// Returns ISO dates of approved [deposits] that were submitted late relative to their term.
  static Set<String> lateDepositIsoDates({
    required SavingPlan plan,
    required List<DepositRecord> deposits,
  }) {
    final schedule = _buildTermSchedule(plan);
    if (schedule.isEmpty) return const {};

    final start = _toLocalDay(plan.startDate);
    final lateDates = <String>{};

    for (final d in deposits) {
      if (d.status != DepositStatus.approved) continue;
      final depDay = _toLocalDay(d.depositDate);

      // Deposits with an explicit term snapshot are judged strictly against their own term.
      if (d.termDueDate != null) {
        if (depDay.isAfter(_toLocalDay(d.termDueDate!))) {
          lateDates.add(formatIsoDate(depDay));
        }
        continue;
      }

      // Deposits from a different saving frequency or prior to the new plan start are never late.
      if ((d.termFrequency != null && d.termFrequency != plan.frequency) ||
          depDay.isBefore(start)) {
        continue;
      }

      final termIndex = _resolveTermIndexForSamePlan(
        deposit: d,
        planStart: start,
        schedule: schedule,
      );
      if (termIndex != null) {
        final dueDay = _toLocalDay(schedule[termIndex - 1].dueDate);
        if (depDay.isAfter(dueDay)) {
          lateDates.add(formatIsoDate(depDay));
        }
      }
    }
    return lateDates;
  }

  static bool _isDepositLate({
    required DepositRecord d,
    required DateTime termDueDay,
    required SavingPlan plan,
  }) {
    final depDay = _toLocalDay(d.depositDate);
    if (d.termDueDate != null) {
      return depDay.isAfter(_toLocalDay(d.termDueDate!));
    }
    if ((d.termFrequency != null && d.termFrequency != plan.frequency) ||
        depDay.isBefore(_toLocalDay(plan.startDate))) {
      return false;
    }
    return depDay.isAfter(termDueDay);
  }

  /// Builds calendar cells for [month] combining [streak], [deposits], [journals], and optional [plan].
  static List<StreakCalendarDay> buildMonthCalendar({
    required DateTime month,
    required MemberStreak streak,
    List<DepositRecord> deposits = const [],
    Map<String, ({String emoji, String note})> journals = const {},
    SavingPlan? plan,
    DateTime? planStartDate,
    IncomingDepositInfo? nextIncomingOverride,
    DateTime? groupAnchorDate,
    DateTime? scheduleDeadlineDate,
    DateTime? today,
  }) {
    return _buildMonthCalendarImpl(
      month: month,
      streak: streak,
      deposits: deposits,
      journals: journals,
      plan: plan,
      planStartDate: planStartDate,
      nextIncomingOverride: nextIncomingOverride,
      groupAnchorDate: groupAnchorDate,
      scheduleDeadlineDate: scheduleDeadlineDate,
      today: today,
    );
  }

  static List<InstallmentItem> _buildTermSchedule(SavingPlan plan) {
    final start = _toLocalDay(plan.startDate);
    final deadline = _toLocalDay(plan.deadlineDate);
    if (!deadline.isAfter(start)) return const [];

    final effectiveTarget = plan.targetAmount > 0 ? plan.targetAmount : 100000.0;
    try {
      return SavingCalculator.calculateInstallments(
        targetAmount: effectiveTarget,
        startDate: start,
        deadlineDate: deadline,
        preferredFrequency: plan.frequency,
      ).schedule;
    } catch (_) {
      return const [];
    }
  }

  static Map<int, List<DepositRecord>> _mapApprovedDepositsToTerms({
    required SavingPlan plan,
    required List<InstallmentItem> schedule,
    required List<DepositRecord> deposits,
  }) {
    final result = <int, List<DepositRecord>>{};
    final approved = deposits.where((d) => d.status == DepositStatus.approved).toList();
    final start = _toLocalDay(plan.startDate);

    for (final d in approved) {
      final depDay = _toLocalDay(d.depositDate);
      final isDifferentFrequency =
          d.termFrequency != null && d.termFrequency != plan.frequency;
      if (isDifferentFrequency) {
        // Match by the paid term's date span (or deposit day) so switching terms credits covered days.
        final isOnTimeCrossTerm = d.termDueDate == null ||
            !depDay.isAfter(_toLocalDay(d.termDueDate!));
        if (isOnTimeCrossTerm && d.termDueDate != null) {
          final spanDays = _termSpanDays(d.termFrequency!);
          final dueDay = _toLocalDay(d.termDueDate!);
          final termStart = dueDay.subtract(Duration(days: spanDays - 1));
          for (var i = 0; i < schedule.length; i++) {
            final termPrevDue = i == 0
                ? start.subtract(const Duration(days: 1))
                : _toLocalDay(schedule[i - 1].dueDate);
            final termWindowStart = termPrevDue.add(const Duration(days: 1));
            final termDue = _toLocalDay(schedule[i].dueDate);
            if (!termWindowStart.isBefore(start) &&
                !dueDay.isBefore(termWindowStart) &&
                !termStart.isAfter(termDue)) {
              result.putIfAbsent(i + 1, () => []).add(d);
            }
          }
          continue;
        }
        if (!depDay.isBefore(start)) {
          final termIndex =
              _matchTermWindow(depDay: depDay, planStart: start, schedule: schedule);
          if (termIndex != null) {
            result.putIfAbsent(termIndex, () => []).add(d);
          }
        }
        continue;
      }

      if (depDay.isBefore(start)) {
        continue;
      }
      final termIndex = _resolveTermIndexForSamePlan(
        deposit: d,
        planStart: start,
        schedule: schedule,
      );
      if (termIndex != null) {
        result.putIfAbsent(termIndex, () => []).add(d);
      }
    }
    return result;
  }

  static int _priorCarryStreak({
    required SavingPlan plan,
    required List<DepositRecord> deposits,
    MemberStreak? streak,
    required DateTime todayDay,
  }) {
    final planStart = _toLocalDay(plan.startDate);
    final yesterday = planStart.subtract(const Duration(days: 1));
    final upperBound = yesterday.isAfter(todayDay) ? todayDay : yesterday;

    final coveredDays = <String>{};
    final lateDays = <String>{};
    final blockedDates = deposits
        .where((d) => d.status != DepositStatus.approved)
        .map((d) => formatIsoDate(_toLocalDay(d.depositDate)))
        .toSet();

    for (final d in deposits) {
      if (d.status != DepositStatus.approved) continue;
      final depDay = _toLocalDay(d.depositDate);
      if (d.termDueDate != null) {
        final dueDay = _toLocalDay(d.termDueDate!);
        if (depDay.isAfter(dueDay)) {
          lateDays.add(formatIsoDate(depDay));
          continue;
        }
        final freq = d.termFrequency ?? plan.frequency;
        final spanDays = _termSpanDays(freq);
        final termStart = dueDay.subtract(Duration(days: spanDays - 1));
        final endDay = dueDay.isAfter(upperBound) ? upperBound : dueDay;
        for (var day = termStart;
            !day.isAfter(endDay);
            day = day.add(const Duration(days: 1))) {
          coveredDays.add(formatIsoDate(day));
        }
      } else if (depDay.isBefore(planStart) && !depDay.isAfter(upperBound)) {
        coveredDays.add(formatIsoDate(depDay));
      }
    }

    if (streak != null) {
      for (final rawIso in streak.depositDates) {
        if (blockedDates.contains(rawIso) || lateDays.contains(rawIso)) continue;
        final day = parseIsoDate(rawIso);
        if (day == null || !day.isBefore(planStart) || day.isAfter(upperBound)) {
          continue;
        }
        coveredDays.add(formatIsoDate(day));
      }
    }

    if (coveredDays.isEmpty) return 0;

    var consecutiveDays = 0;
    var cursor = upperBound;
    while (coveredDays.contains(formatIsoDate(cursor))) {
      consecutiveDays += 1;
      cursor = cursor.subtract(const Duration(days: 1));
      if (consecutiveDays >= 3650) break;
    }

    return consecutiveDays ~/ _termSpanDays(plan.frequency);
  }

  static int _termSpanDays(SavingFrequency frequency) => switch (frequency) {
        SavingFrequency.daily => 1,
        SavingFrequency.weekly => 7,
        SavingFrequency.monthly => 30,
      };

  static Set<String> _crossTermFilledDates({
    required SavingPlan plan,
    required List<DepositRecord> deposits,
    required DateTime todayDay,
    bool clampToToday = true,
  }) {
    final filled = <String>{};
    for (final d in deposits) {
      if (d.status != DepositStatus.approved &&
          d.status != DepositStatus.pending) {
        continue;
      }
      if (d.termFrequency == null || d.termFrequency == plan.frequency) continue;
      if (d.termDueDate == null) continue;

      final depDay = _toLocalDay(d.depositDate);
      final dueDay = _toLocalDay(d.termDueDate!);
      if (depDay.isAfter(dueDay)) continue; // Late deposits should not fill gap days as on-time.

      final spanDays = _termSpanDays(d.termFrequency!);
      final termStart = dueDay.subtract(Duration(days: spanDays - 1));
      final endDay = (clampToToday && dueDay.isAfter(todayDay)) ? todayDay : dueDay;
      for (var day = termStart;
          !day.isAfter(endDay);
          day = day.add(const Duration(days: 1))) {
        filled.add(formatIsoDate(day));
      }
    }
    return filled;
  }

  static int? _resolveTermIndexForSamePlan({
    required DepositRecord deposit,
    required DateTime planStart,
    required List<InstallmentItem> schedule,
  }) {
    if (deposit.installmentIndex >= 1 && deposit.installmentIndex <= schedule.length) {
      return deposit.installmentIndex;
    }
    final depDay = _toLocalDay(deposit.depositDate);
    return _matchTermWindow(depDay: depDay, planStart: planStart, schedule: schedule) ??
        schedule.length;
  }

  static int? _matchTermWindow({
    required DateTime depDay,
    required DateTime planStart,
    required List<InstallmentItem> schedule,
  }) {
    for (var i = 0; i < schedule.length; i++) {
      final prevDue = i == 0
          ? planStart.subtract(const Duration(days: 1))
          : _toLocalDay(schedule[i - 1].dueDate);
      final due = _toLocalDay(schedule[i].dueDate);
      if (depDay.isAfter(prevDue) && !depDay.isAfter(due)) {
        return i + 1;
      }
    }
    return null;
  }

  static Set<int> _mapManualCheckInsToTerms({
    required SavingPlan plan,
    required List<InstallmentItem> schedule,
    required List<DepositRecord> deposits,
    MemberStreak? streak,
  }) {
    if (streak == null || streak.depositDates.isEmpty || schedule.isEmpty) {
      return const {};
    }
    final blockedDates = deposits
        .where((d) => d.status != DepositStatus.approved)
        .map((d) => formatIsoDate(_toLocalDay(d.depositDate)))
        .toSet();
    final start = _toLocalDay(plan.startDate);
    final matched = <int>{};

    for (final rawIso in streak.depositDates) {
      if (blockedDates.contains(rawIso)) continue;
      final day = parseIsoDate(rawIso);
      if (day == null) continue;
      for (var i = 0; i < schedule.length; i++) {
        final prevDue = i == 0
            ? start.subtract(const Duration(days: 1))
            : _toLocalDay(schedule[i - 1].dueDate);
        final due = _toLocalDay(schedule[i].dueDate);
        if (day.isAfter(prevDue) && !day.isAfter(due)) {
          matched.add(i + 1);
          break;
        }
      }
    }
    return matched;
  }

  static Set<String> _missedTermDueIsoDates({
    required SavingPlan plan,
    required List<DepositRecord> deposits,
    required MemberStreak streak,
    required DateTime todayDay,
  }) {
    final schedule = _buildTermSchedule(plan);
    if (schedule.isEmpty) return const {};

    final approvedByTerm = _mapApprovedDepositsToTerms(
      plan: plan,
      schedule: schedule,
      deposits: deposits,
    );
    final checkInTerms = _mapManualCheckInsToTerms(
      plan: plan,
      schedule: schedule,
      deposits: deposits,
      streak: streak,
    );

    final missed = <String>{};
    for (var i = 0; i < schedule.length; i++) {
      final termIndex = i + 1;
      final dueDay = _toLocalDay(schedule[i].dueDate);
      if (!todayDay.isAfter(dueDay)) break;
      final hasPayment = (approvedByTerm[termIndex]?.isNotEmpty ?? false) ||
          checkInTerms.contains(termIndex);
      if (!hasPayment) {
        missed.add(formatIsoDate(dueDay));
      }
    }
    return missed;
  }

  static DateTime? _resolveFirstActivityDay({
    required MemberStreak streak,
    required List<DepositRecord> deposits,
    DateTime? planStartDate,
  }) {
    final candidates = <DateTime>[
      ...normalizeDates(streak.depositDates),
      ...deposits.map((d) => _toLocalDay(d.depositDate)),
      if (planStartDate != null) _toLocalDay(planStartDate),
    ];
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.first;
  }

  static DateTime _toLocalDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static int _calendarDayDiff(DateTime a, DateTime b) {
    final utcA = DateTime.utc(a.year, a.month, a.day);
    final utcB = DateTime.utc(b.year, b.month, b.day);
    return utcB.difference(utcA).inDays;
  }
}
