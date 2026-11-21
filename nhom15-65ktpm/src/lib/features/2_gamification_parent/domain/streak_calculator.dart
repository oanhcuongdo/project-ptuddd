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
      // Bị gián đoạn trên 1 ngày (diffDays >= 2), reset streak về 1
      return 1;
    }
  }

  /// Định dạng ngày YYYY-MM-DD theo múi giờ địa phương
  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
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
