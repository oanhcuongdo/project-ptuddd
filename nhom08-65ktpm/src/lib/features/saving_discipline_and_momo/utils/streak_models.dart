import '../models/saving_plan.dart';

/// Status of a single day cell in the DailyYou Saving Streak Calendar.
enum StreakDayStatus { checkedIn, late, pending, missed, upcoming }

/// Urgency level for reminding a member to deposit today based on their saving term.
enum DepositReminderUrgency { none, dueToday, overdue }

/// Reminder summary indicating whether the member must deposit today for their active term.
class TodayDepositReminder {
  final bool shouldWarn;
  final DepositReminderUrgency urgency;
  final SavingFrequency frequency;
  final int? installmentIndex;
  final DateTime? dueDate;
  final double amountDue;
  final int overdueTermCount;

  const TodayDepositReminder({
    required this.shouldWarn,
    required this.urgency,
    required this.frequency,
    this.installmentIndex,
    this.dueDate,
    this.amountDue = 0,
    this.overdueTermCount = 0,
  });

  const TodayDepositReminder.none(SavingFrequency frequency)
      : this(
          shouldWarn: false,
          urgency: DepositReminderUrgency.none,
          frequency: frequency,
        );
}

/// Term-based streak summary computed against a member's [SavingPlan] schedule.
class TermStreakSummary {
  final int currentStreak;
  final int longestStreak;
  final int onTimeTerms;
  final int lateTerms;
  final bool isOnStreak;
  final SavingFrequency frequency;

  const TermStreakSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.onTimeTerms,
    required this.lateTerms,
    required this.isOnStreak,
    required this.frequency,
  });
}

/// Presentation-ready upcoming deposit schedule metadata.
class IncomingDepositInfo {
  final int installmentIndex;
  final DateTime dueDate;
  final double amount;
  final int daysUntilDue;
  final SavingFrequency frequency;

  const IncomingDepositInfo({
    required this.installmentIndex,
    required this.dueDate,
    required this.amount,
    required this.daysUntilDue,
    required this.frequency,
  });
}

/// Presentation-ready data for one day in the DailyYou Streak Calendar.
class StreakCalendarDay {
  final DateTime date;
  final String isoDate;
  final StreakDayStatus status;
  final String? emotionEmoji;
  final String? journalNote;
  final bool isNextDue;
  final bool isScheduledDue;
  final int? scheduledInstallmentIndex;
  final double? scheduledAmount;

  const StreakCalendarDay({
    required this.date,
    required this.isoDate,
    required this.status,
    this.emotionEmoji,
    this.journalNote,
    this.isNextDue = false,
    this.isScheduledDue = false,
    this.scheduledInstallmentIndex,
    this.scheduledAmount,
  });
}
