import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_buddy/features/saving_discipline_and_momo/models/deposit_record.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/member_streak.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/saving_plan.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/saving_plan_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/saving_streak_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/in_memory_saving_repository.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/saving_repository_impl.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/utils/saving_streak_calculator.dart';

void main() {
  group('SavingStreakCalculator Tests', () {
    test('returns 0 streaks for empty deposit dates', () {
      expect(SavingStreakCalculator.calculateCurrentStreak([]), 0);
      expect(SavingStreakCalculator.calculateLongestStreak([]), 0);
    });

    test('calculates active streak when latest check-in is today or yesterday', () {
      final today = DateTime(2026, 11, 26);
      final dates = ['2026-11-23', '2026-11-24', '2026-11-25'];

      expect(
        SavingStreakCalculator.calculateCurrentStreak(dates, referenceDate: today),
        3,
      );
      expect(SavingStreakCalculator.calculateLongestStreak(dates), 3);
    });

    test('resets active streak to 0 when gap exceeds 1 day while preserving longest', () {
      final today = DateTime(2026, 11, 28);
      final dates = ['2026-11-22', '2026-11-23', '2026-11-24', '2026-11-25'];

      expect(
        SavingStreakCalculator.calculateCurrentStreak(dates, referenceDate: today),
        0,
      );
      expect(SavingStreakCalculator.calculateLongestStreak(dates), 4);
    });

    test('recordCheckIn is idempotent for duplicate check-in on same day', () {
      final initial = MemberStreak(
        memberId: 'm1',
        tripId: 't1',
        currentStreak: 1,
        longestStreak: 1,
        lastDepositDate: DateTime(2026, 11, 25),
        depositDates: ['2026-11-25'],
        totalDisciplinedDays: 1,
      );

      final updated = SavingStreakCalculator.recordCheckIn(
        initial,
        DateTime(2026, 11, 25, 22, 30),
        referenceDate: DateTime(2026, 11, 25),
      );

      expect(updated.depositDates, ['2026-11-25']);
      expect(updated.currentStreak, 1);
      expect(updated.totalDisciplinedDays, 1);
    });

    test('recordCheckIn extends streak and updates longestStreak across consecutive days', () {
      final day1 = SavingStreakCalculator.recordCheckIn(
        const MemberStreak(memberId: 'm1', tripId: 't1'),
        DateTime(2026, 11, 24),
      );
      final day2 = SavingStreakCalculator.recordCheckIn(
        day1,
        DateTime(2026, 11, 25),
      );
      final day3 = SavingStreakCalculator.recordCheckIn(
        day2,
        DateTime(2026, 11, 26),
      );

      expect(day3.currentStreak, 3);
      expect(day3.longestStreak, 3);
      expect(day3.totalDisciplinedDays, 3);
      expect(day3.depositDates, ['2026-11-24', '2026-11-25', '2026-11-26']);
    });

    test('buildMonthCalendar marks checkedIn, pending, missed, and upcoming days', () {
      final streak = MemberStreak(
        memberId: 'm1',
        tripId: 't1',
        depositDates: ['2026-11-02', '2026-11-04'],
      );
      final deposits = [
        DepositRecord(
          id: 'd1',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 212000,
          depositDate: DateTime(2026, 11, 5),
          status: DepositStatus.pending,
        ),
      ];

      final cells = SavingStreakCalculator.buildMonthCalendar(
        month: DateTime(2026, 11),
        streak: streak,
        deposits: deposits,
        journals: {
          '2026-11-02': (emoji: '🔥', note: 'Nhịn trà sữa'),
        },
        today: DateTime(2026, 11, 6),
      );

      expect(cells.length, 30);
      expect(cells[1].status, StreakDayStatus.checkedIn); // Nov 2
      expect(cells[1].emotionEmoji, '🔥');
      expect(cells[1].journalNote, 'Nhịn trà sữa');
      expect(cells[2].status, StreakDayStatus.missed); // Nov 3 (between Nov 2 and Nov 6)
      expect(cells[3].status, StreakDayStatus.checkedIn); // Nov 4
      expect(cells[4].status, StreakDayStatus.pending); // Nov 5
      expect(cells[6].status, StreakDayStatus.upcoming); // Nov 7
    });

    test('buildMonthCalendar marks approved deposit as checkedIn and uses planStartDate for missed', () {
      final deposits = [
        DepositRecord(
          id: 'd_app',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 212000,
          depositDate: DateTime(2026, 11, 3),
          status: DepositStatus.approved,
        ),
      ];

      final cells = SavingStreakCalculator.buildMonthCalendar(
        month: DateTime(2026, 11),
        streak: const MemberStreak(memberId: 'm1', tripId: 't1'),
        deposits: deposits,
        planStartDate: DateTime(2026, 11, 2),
        today: DateTime(2026, 11, 5),
      );

      expect(cells[1].status, StreakDayStatus.missed); // Nov 2 (planStartDate, missed)
      expect(cells[2].status, StreakDayStatus.checkedIn); // Nov 3 (approved deposit)
      expect(cells[3].status, StreakDayStatus.missed); // Nov 4 (missed)
      expect(cells[4].status, StreakDayStatus.upcoming); // Nov 5 (today, not yet checked in)
    });

    test('backfilling an old date preserves currentStreak 0 relative to today', () {
      final updated = SavingStreakCalculator.recordCheckIn(
        const MemberStreak(memberId: 'm1', tripId: 't1'),
        DateTime(2026, 11, 10),
        referenceDate: DateTime(2026, 11, 26),
      );

      expect(updated.currentStreak, 0);
      expect(updated.longestStreak, 1);
      expect(updated.totalDisciplinedDays, 1);
    });
  });

  group('SavingStreakProvider Tests', () {
    test('checkIn updates repository streak and stores journal entry', () async {
      final repo = InMemorySavingRepository();
      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const params = SavingPlanParams(tripId: 't_streak', memberId: 'm_streak');
      final date = DateTime.now();
      final iso = SavingStreakCalculator.formatIsoDate(date);

      final updated = await container
          .read(savingStreakProvider(params).notifier)
          .checkIn(date: date, emoji: '💪', note: 'Bỏ bữa ăn vặt');

      expect(updated.currentStreak, 1);
      expect(updated.totalDisciplinedDays, 1);
      expect(updated.depositDates, [iso]);

      final journals = container.read(savingJournalProvider(params));
      expect(journals[iso]?.emoji, '💪');
      expect(journals[iso]?.note, 'Bỏ bữa ăn vặt');

      final persisted = await repo.getMemberStreak('t_streak', 'm_streak');
      expect(persisted.depositDates, [iso]);
    });
  });

  group('Term-Based Streak & Late Detection Tests', () {
    test('weekly plan counts consecutive on-time approved terms as active streak', () {
      final plan = SavingPlan(
        id: 'p_weekly',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 1000000,
        frequency: SavingFrequency.weekly,
        installmentAmount: 250000,
        totalInstallments: 4,
        startDate: DateTime(2026, 11, 1),
        deadlineDate: DateTime(2026, 11, 29),
      );
      // Term 1 due Nov 8, Term 2 due Nov 15, Term 3 due Nov 22, Term 4 due Nov 29
      final deposits = [
        DepositRecord(
          id: 'd1',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 250000,
          installmentIndex: 1,
          depositDate: DateTime(2026, 11, 7),
          status: DepositStatus.approved,
        ),
        DepositRecord(
          id: 'd2',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 250000,
          installmentIndex: 2,
          depositDate: DateTime(2026, 11, 15), // exact dueDate is on-time
          status: DepositStatus.approved,
        ),
      ];

      final summary = SavingStreakCalculator.calculateTermStreak(
        plan: plan,
        deposits: deposits,
        today: DateTime(2026, 11, 18), // inside Term 3 (not overdue yet)
      );

      expect(summary.frequency, SavingFrequency.weekly);
      expect(summary.onTimeTerms, 2);
      expect(summary.lateTerms, 0);
      expect(summary.currentStreak, 2);
      expect(summary.longestStreak, 2);
      expect(summary.isOnStreak, isTrue);
    });

    test('late approved receipt breaks on-time streak while preserving longestStreak', () {
      final plan = SavingPlan(
        id: 'p_weekly_late',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 1000000,
        frequency: SavingFrequency.weekly,
        installmentAmount: 250000,
        totalInstallments: 4,
        startDate: DateTime(2026, 11, 1),
        deadlineDate: DateTime(2026, 11, 29),
      );
      // Term 1 due Nov 8 (on-time), Term 2 due Nov 15 (on-time), Term 3 due Nov 22 (submitted Nov 23 -> LATE!)
      final deposits = [
        DepositRecord(
          id: 'd1',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 250000,
          installmentIndex: 1,
          depositDate: DateTime(2026, 11, 6),
          status: DepositStatus.approved,
        ),
        DepositRecord(
          id: 'd2',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 250000,
          installmentIndex: 2,
          depositDate: DateTime(2026, 11, 14),
          status: DepositStatus.approved,
        ),
        DepositRecord(
          id: 'd3',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 250000,
          installmentIndex: 3,
          depositDate: DateTime(2026, 11, 23),
          status: DepositStatus.approved,
        ),
      ];

      final summary = SavingStreakCalculator.calculateTermStreak(
        plan: plan,
        deposits: deposits,
        today: DateTime(2026, 11, 24),
      );

      expect(summary.onTimeTerms, 2);
      expect(summary.lateTerms, 1);
      expect(summary.longestStreak, 2);
      expect(summary.currentStreak, 0);
      expect(summary.isOnStreak, isFalse);
    });

    test('monthly plan marks late approved deposit day as StreakDayStatus.late in calendar', () {
      final plan = SavingPlan(
        id: 'p_monthly',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 2000000,
        frequency: SavingFrequency.monthly,
        installmentAmount: 1000000,
        totalInstallments: 2,
        startDate: DateTime(2026, 10, 1),
        deadlineDate: DateTime(2026, 11, 30),
      );
      // Term 1 due Oct 31 -> submitted Nov 2 (late & approved)
      final deposits = [
        DepositRecord(
          id: 'd1',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 1000000,
          installmentIndex: 1,
          depositDate: DateTime(2026, 11, 2),
          status: DepositStatus.approved,
        ),
      ];

      final cells = SavingStreakCalculator.buildMonthCalendar(
        month: DateTime(2026, 11),
        streak: const MemberStreak(memberId: 'm1', tripId: 't1'),
        deposits: deposits,
        plan: plan,
        today: DateTime(2026, 11, 10),
      );

      expect(cells[1].status, StreakDayStatus.late); // Nov 2
    });

    test('weekly plan does not mark non-deposit days of a paid or open term as missed', () {
      final plan = SavingPlan(
        id: 'p_weekly_cal',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 1000000,
        frequency: SavingFrequency.weekly,
        installmentAmount: 250000,
        totalInstallments: 4,
        startDate: DateTime(2026, 11, 1),
        deadlineDate: DateTime(2026, 11, 29),
      );
      // Term 1 (Nov 1..Nov 8) paid on Nov 3; Term 2 (Nov 9..Nov 15) missed; Term 3 (Nov 16..Nov 22) open on Nov 18
      final deposits = [
        DepositRecord(
          id: 'd1',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 250000,
          installmentIndex: 1,
          depositDate: DateTime(2026, 11, 3),
          status: DepositStatus.approved,
        ),
      ];

      final cells = SavingStreakCalculator.buildMonthCalendar(
        month: DateTime(2026, 11),
        streak: const MemberStreak(memberId: 'm1', tripId: 't1'),
        deposits: deposits,
        plan: plan,
        today: DateTime(2026, 11, 18),
      );

      expect(cells[2].status, StreakDayStatus.checkedIn); // Nov 3 (paid)
      expect(cells[3].status, StreakDayStatus.upcoming); // Nov 4 (same paid term -> NOT missed)
      expect(cells[13].status, StreakDayStatus.upcoming); // Nov 14 (before Term 2 due Nov 15)
      expect(cells[14].status, StreakDayStatus.missed); // Nov 15 (Term 2 dueDate missed)
      expect(cells[16].status, StreakDayStatus.upcoming); // Nov 17 (open Term 3 -> NOT missed)
    });

    test('calculateTermStreak includes manual calendar check-ins from MemberStreak', () {
      final plan = SavingPlan(
        id: 'p_checkin',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 500000,
        frequency: SavingFrequency.weekly,
        installmentAmount: 250000,
        totalInstallments: 2,
        startDate: DateTime(2026, 11, 1),
        deadlineDate: DateTime(2026, 11, 15),
      );
      final streak = MemberStreak(
        memberId: 'm1',
        tripId: 't1',
        depositDates: ['2026-11-05'],
      );

      final summary = SavingStreakCalculator.calculateTermStreak(
        plan: plan,
        deposits: const [],
        streak: streak,
        today: DateTime(2026, 11, 10),
      );

      expect(summary.onTimeTerms, 1);
      expect(summary.currentStreak, 1);
      expect(summary.isOnStreak, isTrue);
    });

    test('changing saving plan does not mistakenly mark previous on-time term deposits as late', () {
      // Previously paid Term 3 of a weekly plan on time (Nov 15, due Nov 15)
      final deposits = [
        DepositRecord(
          id: 'd_old_weekly',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 212000,
          installmentIndex: 3,
          depositDate: DateTime(2026, 11, 15),
          termDueDate: DateTime(2026, 11, 15),
          termFrequency: SavingFrequency.weekly,
          status: DepositStatus.approved,
        ),
        // Also paid today (Nov 27) before switching from weekly to daily
        DepositRecord(
          id: 'd_today',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 212000,
          installmentIndex: 4,
          depositDate: DateTime(2026, 11, 27),
          termDueDate: DateTime(2026, 11, 29),
          termFrequency: SavingFrequency.weekly,
          status: DepositStatus.approved,
        ),
      ];

      // Switched to a daily plan starting Nov 27 (old Nov 15 deposit is before startDate,
      // and even with an earlier startDate like Nov 1, Nov 15 must NOT be compared to daily term #3 = Nov 4!)
      final dailyPlanFromNov1 = SavingPlan(
        id: 'p_daily_switched',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 1500000,
        frequency: SavingFrequency.daily,
        installmentAmount: 50000,
        totalInstallments: 30,
        startDate: DateTime(2026, 11, 1),
        deadlineDate: DateTime(2026, 12, 1),
      );

      final lateDates = SavingStreakCalculator.lateDepositIsoDates(
        plan: dailyPlanFromNov1,
        deposits: deposits,
      );
      expect(lateDates, isEmpty);

      final cells = SavingStreakCalculator.buildMonthCalendar(
        month: DateTime(2026, 11),
        streak: const MemberStreak(memberId: 'm1', tripId: 't1'),
        deposits: deposits,
        plan: dailyPlanFromNov1,
        today: DateTime(2026, 11, 27),
      );
      expect(cells[14].status, StreakDayStatus.checkedIn); // Nov 15 stays checkedIn, NOT late!
      expect(cells[26].status, StreakDayStatus.checkedIn); // Nov 27 stays checkedIn!

      // New daily plan starting today (Nov 27) should credit today's deposit as Term 1 on-time
      final dailyPlanFromToday = SavingPlan(
        id: 'p_daily_today',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 500000,
        frequency: SavingFrequency.daily,
        installmentAmount: 50000,
        totalInstallments: 10,
        startDate: DateTime(2026, 11, 27),
        deadlineDate: DateTime(2026, 12, 7),
      );

      final summaryToday = SavingStreakCalculator.calculateTermStreak(
        plan: dailyPlanFromToday,
        deposits: deposits,
        today: DateTime(2026, 11, 27),
      );
      expect(summaryToday.lateTerms, 0);
      expect(summaryToday.onTimeTerms, 5);
      expect(summaryToday.currentStreak, 5);
      expect(summaryToday.isOnStreak, isTrue);
    });

    test('switching from weekly to daily starting today does not mark prior days as missed or late', () {
      final oldWeeklyDeposits = [
        DepositRecord(
          id: 'd_w1',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 212000,
          installmentIndex: 1,
          depositDate: DateTime(2026, 11, 5),
          termDueDate: DateTime(2026, 11, 8),
          termFrequency: SavingFrequency.weekly,
          status: DepositStatus.approved,
        ),
        DepositRecord(
          id: 'd_w2',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 212000,
          installmentIndex: 2,
          depositDate: DateTime(2026, 11, 12),
          termDueDate: DateTime(2026, 11, 15),
          termFrequency: SavingFrequency.weekly,
          status: DepositStatus.approved,
        ),
      ];

      final newDailyPlan = SavingPlan(
        id: 'p_daily_new',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 1000000,
        frequency: SavingFrequency.daily,
        installmentAmount: 50000,
        totalInstallments: 20,
        startDate: DateTime(2026, 11, 27),
        deadlineDate: DateTime(2026, 12, 17),
      );

      final cells = SavingStreakCalculator.buildMonthCalendar(
        month: DateTime(2026, 11),
        streak: const MemberStreak(memberId: 'm1', tripId: 't1'),
        deposits: oldWeeklyDeposits,
        plan: newDailyPlan,
        today: DateTime(2026, 11, 27),
      );

      expect(cells[4].status, StreakDayStatus.checkedIn); // Nov 5
      expect(cells[5].status, StreakDayStatus.checkedIn); // Nov 6 (filled gap day of paid weekly term)
      expect(cells[11].status, StreakDayStatus.checkedIn); // Nov 12
      expect(cells[12].status, StreakDayStatus.checkedIn); // Nov 13 (filled gap day of paid weekly term)
      expect(cells[25].status, StreakDayStatus.upcoming); // Nov 26 (NOT missed)
    });

    test('fills gap days of an on-time paid weekly/monthly term when switching to another term type', () {
      // Paid Term 1 of weekly plan (Nov 21..Nov 27, due Nov 27) on Nov 25
      final weeklyDeposit = DepositRecord(
        id: 'd_fill',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        amount: 212000,
        installmentIndex: 1,
        depositDate: DateTime(2026, 11, 25),
        termDueDate: DateTime(2026, 11, 27),
        termFrequency: SavingFrequency.weekly,
        status: DepositStatus.approved,
      );

      // Switch to daily plan starting Nov 27
      final dailyPlan = SavingPlan(
        id: 'p_daily_gap',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 500000,
        frequency: SavingFrequency.daily,
        installmentAmount: 50000,
        totalInstallments: 10,
        startDate: DateTime(2026, 11, 27),
        deadlineDate: DateTime(2026, 12, 7),
      );

      final cells = SavingStreakCalculator.buildMonthCalendar(
        month: DateTime(2026, 11),
        streak: const MemberStreak(memberId: 'm1', tripId: 't1'),
        deposits: [weeklyDeposit],
        plan: dailyPlan,
        today: DateTime(2026, 11, 27),
      );

      // Nov 21..Nov 27 are covered by the paid weekly term (Nov 27 - 6d .. Nov 27)
      expect(cells[20].status, StreakDayStatus.checkedIn); // Nov 21
      expect(cells[24].status, StreakDayStatus.checkedIn); // Nov 25 (actual deposit day)
      expect(cells[25].status, StreakDayStatus.checkedIn); // Nov 26 (gap filled)
      expect(cells[26].status, StreakDayStatus.checkedIn); // Nov 27 (today, gap filled)
      expect(cells[27].status, StreakDayStatus.upcoming); // Nov 28 (future day stays upcoming)

      final summary = SavingStreakCalculator.calculateTermStreak(
        plan: dailyPlan,
        deposits: [weeklyDeposit],
        today: DateTime(2026, 11, 27),
      );
      expect(summary.onTimeTerms, 7);
      expect(summary.currentStreak, 7);
      expect(summary.isOnStreak, isTrue);
    });

    test('switching from 5 consecutive weekly deposits to daily preserves full 35-day streak', () {
      final start = DateTime(2026, 10, 23);
      final today = DateTime(2026, 11, 27); // start + 35 days
      final weeklyDeposits = List.generate(5, (i) {
        final idx = i + 1;
        return DepositRecord(
          id: 'w_$idx',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'An',
          amount: 212000,
          installmentIndex: idx,
          depositDate: start.add(Duration(days: idx * 7 - 1)),
          termDueDate: start.add(Duration(days: idx * 7)),
          termFrequency: SavingFrequency.weekly,
          status: DepositStatus.approved,
        );
      });

      final dailyPlanToday = SavingPlan(
        id: 'p_daily_after_5_weeks',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'An',
        targetAmount: 1500000,
        frequency: SavingFrequency.daily,
        installmentAmount: 50000,
        totalInstallments: 30,
        startDate: today,
        deadlineDate: today.add(const Duration(days: 30)),
      );

      final summary = SavingStreakCalculator.calculateTermStreak(
        plan: dailyPlanToday,
        deposits: weeklyDeposits,
        today: today,
      );
      expect(summary.currentStreak, 35);
      expect(summary.longestStreak, 35);
      expect(summary.onTimeTerms, 35);
      expect(summary.lateTerms, 0);
      expect(summary.isOnStreak, isTrue);
    });
  });

  group('SavingStreakCalculator Today Deposit Warning Tests', () {
    test('daily plan warns dueToday until deposited or pending, or covered cross-term', () {
      final dailyPlan = SavingPlan(
        id: 'p_warn_daily',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 500000,
        frequency: SavingFrequency.daily,
        installmentAmount: 50000,
        totalInstallments: 10,
        startDate: DateTime(2026, 11, 27),
        deadlineDate: DateTime(2026, 12, 7),
      );

      final emptyWarn = SavingStreakCalculator.evaluateTodayDepositWarning(
        plan: dailyPlan,
        deposits: const [],
        today: DateTime(2026, 11, 27),
      );
      expect(emptyWarn.shouldWarn, isTrue);
      expect(emptyWarn.urgency, DepositReminderUrgency.dueToday);
      expect(emptyWarn.installmentIndex, 1);

      final pendingTodayWarn = SavingStreakCalculator.evaluateTodayDepositWarning(
        plan: dailyPlan,
        deposits: [
          DepositRecord(
            id: 'd_pending',
            tripId: 't1',
            memberId: 'm1',
            memberName: 'Bình',
            amount: 50000,
            installmentIndex: 1,
            depositDate: DateTime(2026, 11, 27),
            termDueDate: DateTime(2026, 11, 28),
            termFrequency: SavingFrequency.daily,
            status: DepositStatus.pending,
          ),
        ],
        today: DateTime(2026, 11, 27),
      );
      expect(pendingTodayWarn.shouldWarn, isFalse);

      // Cross-term weekly deposit covering Nov 21..Nov 27 also clears warning today
      final crossTermWarn = SavingStreakCalculator.evaluateTodayDepositWarning(
        plan: dailyPlan,
        deposits: [
          DepositRecord(
            id: 'd_weekly',
            tripId: 't1',
            memberId: 'm1',
            memberName: 'Bình',
            amount: 212000,
            installmentIndex: 4,
            depositDate: DateTime(2026, 11, 25),
            termDueDate: DateTime(2026, 11, 27),
            termFrequency: SavingFrequency.weekly,
            status: DepositStatus.approved,
          ),
        ],
        today: DateTime(2026, 11, 27),
      );
      expect(crossTermWarn.shouldWarn, isFalse);
    });

    test('weekly plan warns only on due date or when overdue', () {
      final weeklyPlan = SavingPlan(
        id: 'p_warn_weekly',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 800000,
        frequency: SavingFrequency.weekly,
        installmentAmount: 200000,
        totalInstallments: 4,
        startDate: DateTime(2026, 11, 1),
        deadlineDate: DateTime(2026, 11, 29),
      );
      final week1Approved = DepositRecord(
        id: 'w1',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        amount: 200000,
        installmentIndex: 1,
        depositDate: DateTime(2026, 11, 7),
        termDueDate: DateTime(2026, 11, 8),
        termFrequency: SavingFrequency.weekly,
        status: DepositStatus.approved,
      );

      // Mid-week (Nov 12): Term 1 is paid, Term 2 due Nov 15 -> no warning yet
      final midWeek = SavingStreakCalculator.evaluateTodayDepositWarning(
        plan: weeklyPlan,
        deposits: [week1Approved],
        today: DateTime(2026, 11, 12),
      );
      expect(midWeek.shouldWarn, isFalse);

      // Exact due date (Nov 15): Term 2 unpaid -> dueToday warning
      final onDueDate = SavingStreakCalculator.evaluateTodayDepositWarning(
        plan: weeklyPlan,
        deposits: [week1Approved],
        today: DateTime(2026, 11, 15),
      );
      expect(onDueDate.shouldWarn, isTrue);
      expect(onDueDate.urgency, DepositReminderUrgency.dueToday);
      expect(onDueDate.installmentIndex, 2);

      // Past Term 2 & Term 3 due dates (Nov 23): overdue warning with count 2
      final overdue = SavingStreakCalculator.evaluateTodayDepositWarning(
        plan: weeklyPlan,
        deposits: [week1Approved],
        today: DateTime(2026, 11, 23),
      );
      expect(overdue.shouldWarn, isTrue);
      expect(overdue.urgency, DepositReminderUrgency.overdue);
      expect(overdue.overdueTermCount, 2);
      expect(overdue.installmentIndex, 2);
    });

    test('completed saving plan never shows deposit warning', () {
      final completedPlan = SavingPlan(
        id: 'p_done',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 500000,
        paidAmount: 500000,
        frequency: SavingFrequency.daily,
        installmentAmount: 50000,
        totalInstallments: 10,
        startDate: DateTime(2026, 11, 27),
        deadlineDate: DateTime(2026, 12, 7),
        status: SavingPlanStatus.completed,
      );

      final result = SavingStreakCalculator.evaluateTodayDepositWarning(
        plan: completedPlan,
        deposits: const [],
        today: DateTime(2026, 11, 27),
      );
      expect(result.shouldWarn, isFalse);
      expect(result.urgency, DepositReminderUrgency.none);
    });
  });

  group('SavingStreakCalculator Incoming Deposit Calendar Tests', () {
    test('weekly plan returns next incoming deposit and marks future due dates on calendar', () {
      final weeklyPlan = SavingPlan(
        id: 'p_inc_weekly',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 800000,
        frequency: SavingFrequency.weekly,
        installmentAmount: 200000,
        totalInstallments: 4,
        startDate: DateTime(2026, 11, 1),
        deadlineDate: DateTime(2026, 11, 29),
      );
      final week1Approved = DepositRecord(
        id: 'w1',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        amount: 200000,
        installmentIndex: 1,
        depositDate: DateTime(2026, 11, 7),
        termDueDate: DateTime(2026, 11, 8),
        termFrequency: SavingFrequency.weekly,
        status: DepositStatus.approved,
      );

      final nextInfo = SavingStreakCalculator.nextIncomingDeposit(
        plan: weeklyPlan,
        deposits: [week1Approved],
        today: DateTime(2026, 11, 10),
      );
      expect(nextInfo, isNotNull);
      expect(nextInfo!.installmentIndex, 2);
      expect(nextInfo.dueDate, DateTime(2026, 11, 15));
      expect(nextInfo.daysUntilDue, 5);
      expect(
        SavingStreakCalculator.formatIncomingDepositDate(nextInfo),
        '15/11 (Còn 5 ngày)',
      );

      final cells = SavingStreakCalculator.buildMonthCalendar(
        month: DateTime(2026, 11),
        streak: const MemberStreak(memberId: 'm1', tripId: 't1'),
        deposits: [week1Approved],
        plan: weeklyPlan,
        today: DateTime(2026, 11, 10),
      );
      expect(cells[14].isNextDue, isTrue); // Nov 15 (next incoming deposit)
      expect(cells[14].isScheduledDue, isTrue);
      expect(cells[14].scheduledInstallmentIndex, 2);
      expect(cells[21].isNextDue, isFalse); // Nov 22 (later scheduled weekly due date)
      expect(cells[21].isScheduledDue, isTrue);
      expect(cells[28].isScheduledDue, isTrue); // Nov 29
      expect(cells[15].isScheduledDue, isFalse); // Nov 16 (not a due date)
    });

    test('daily plan after cross-term weekly coverage marks first uncovered day after paid week', () {
      final dailyPlan = SavingPlan(
        id: 'p_inc_daily',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        targetAmount: 1000000,
        frequency: SavingFrequency.daily,
        installmentAmount: 50000,
        totalInstallments: 10,
        startDate: DateTime(2026, 11, 27),
        deadlineDate: DateTime(2026, 12, 7),
      );
      // Paid weekly covering Nov 24..Nov 30
      final weeklyDeposit = DepositRecord(
        id: 'w_cov',
        tripId: 't1',
        memberId: 'm1',
        memberName: 'Bình',
        amount: 212000,
        installmentIndex: 4,
        depositDate: DateTime(2026, 11, 26),
        termDueDate: DateTime(2026, 11, 30),
        termFrequency: SavingFrequency.weekly,
        status: DepositStatus.approved,
      );

      final nextInfo = SavingStreakCalculator.nextIncomingDeposit(
        plan: dailyPlan,
        deposits: [weeklyDeposit],
        today: DateTime(2026, 11, 27),
      );
      expect(nextInfo, isNotNull);
      expect(nextInfo!.dueDate, DateTime(2026, 12, 1));
      expect(nextInfo.daysUntilDue, 4);

      final decCells = SavingStreakCalculator.buildMonthCalendar(
        month: DateTime(2026, 12),
        streak: const MemberStreak(memberId: 'm1', tripId: 't1'),
        deposits: [weeklyDeposit],
        plan: dailyPlan,
        today: DateTime(2026, 11, 27),
      );
      expect(decCells[0].isNextDue, isTrue); // Dec 1
      expect(decCells[0].isScheduledDue, isTrue);
    });
  });
}
