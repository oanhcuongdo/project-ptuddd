class StreakCalculator {
  /// Tính toán chuỗi Streak dựa trên ngày hoạt động gần nhất
  static int updateStreak({
    required int currentStreak,
    required DateTime? lastActiveDate,
    required DateTime today,
  }) {
    if (lastActiveDate == null) {
      return 1;
    }

    final lastDateOnly = DateTime(
      lastActiveDate.year,
      lastActiveDate.month,
      lastActiveDate.day,
    );
    final todayDateOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final differenceInDays = todayDateOnly.difference(lastDateOnly).inDays;

    if (differenceInDays == 0) {
      // Đã học hôm nay rồi, giữ nguyên streak
      return currentStreak > 0 ? currentStreak : 1;
    } else if (differenceInDays == 1) {
      // Học ngày kế tiếp liên tục, tăng 1 ngày streak
      return currentStreak + 1;
    } else {
      // Bị gián đoạn trên 1 ngày, reset streak về 1
      return 1;
    }
  }
}
