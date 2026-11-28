class StreakCalculator {
  /// Updates a streak once per local calendar day, resetting after a 24-hour gap.
  static int updateStreak({
    required int currentStreak,
    required DateTime? lastActiveDate,
    required DateTime today,
  }) {
    if (lastActiveDate == null) {
      return 1;
    }

    final lastLocal = lastActiveDate.toLocal();
    final todayLocal = today.toLocal();
    final elapsed = todayLocal.difference(lastLocal);

    if (elapsed.isNegative) {
      return currentStreak > 0 ? currentStreak : 1;
    }

    if (elapsed > const Duration(hours: 24)) {
      return 1;
    }

    final completedToday = lastLocal.year == todayLocal.year &&
        lastLocal.month == todayLocal.month &&
        lastLocal.day == todayLocal.day;
    if (completedToday) {
      return currentStreak > 0 ? currentStreak : 1;
    }

    return currentStreak > 0 ? currentStreak + 1 : 1;
  }

  /// Định dạng ngày YYYY-MM-DD theo múi giờ địa phương
  static String formatDate(DateTime date) {
    final localDate = date.toLocal();
    final y = localDate.year.toString().padLeft(4, '0');
    final m = localDate.month.toString().padLeft(2, '0');
    final d = localDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Kiểm tra xem bé đã hoàn thành bài tập trong ngày hôm nay chưa
  static bool isCompletedToday(String? lastCompletedDate, DateTime today) {
    if (lastCompletedDate == null || lastCompletedDate.trim().isEmpty) {
      return false;
    }
    final todayStr = formatDate(today);
    return lastCompletedDate.startsWith(todayStr);
  }
}
