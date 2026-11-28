/// Dữ liệu 1 ngày trong thanh tiến độ 7 ngày tuần này (T2 -> CN) lấy từ `user_quest_logs`.
class DailyStreakDay {
  final DateTime date;
  final int completedMinutes;
  final int goalMinutes;
  final bool isCompleted;
  final bool isToday;
  final bool isFuture;

  const DailyStreakDay({
    required this.date,
    this.completedMinutes = 0,
    this.goalMinutes = 15,
    this.isCompleted = false,
    this.isToday = false,
    this.isFuture = false,
  });

  bool get hasPartialProgress => !isCompleted && completedMinutes > 0;

  String get shortWeekdayLabel {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
      default:
        return 'CN';
    }
  }
}

/// Một dòng nhật ký cập nhật chuỗi gần đây lấy từ `room_meet_attendance` + `room_meet_sessions`.
class StreakHistoryItem {
  final String sessionId;
  final String conversationId;
  final String roomName;
  final String sessionTitle;
  final int attendedSeconds;
  final int minMinutes;
  final bool streakAwarded;
  final DateTime updatedAt;

  const StreakHistoryItem({
    required this.sessionId,
    required this.conversationId,
    required this.roomName,
    required this.sessionTitle,
    required this.attendedSeconds,
    required this.minMinutes,
    required this.streakAwarded,
    required this.updatedAt,
  });

  int get attendedMinutes => attendedSeconds ~/ 60;
}

/// Dữ liệu tổng hợp cho Bảng cập nhật chuỗi cá nhân & lịch sử điểm danh Meet.
class StreakBoardData {
  final int todayMinutes;
  final int dailyGoalMinutes;
  final List<DailyStreakDay> weekDays;
  final List<StreakHistoryItem> recentHistory;

  const StreakBoardData({
    required this.todayMinutes,
    required this.dailyGoalMinutes,
    required this.weekDays,
    required this.recentHistory,
  });

  int get safeDailyGoal => dailyGoalMinutes > 0 ? dailyGoalMinutes : 15;

  double get todayProgress => (todayMinutes / safeDailyGoal).clamp(0.0, 1.0);

  int get remainingMinutesToday =>
      (safeDailyGoal - todayMinutes).clamp(0, safeDailyGoal);

  bool get isTodayGoalCompleted => todayMinutes >= safeDailyGoal;

  int get completedDaysThisWeek =>
      weekDays.where((day) => day.isCompleted).length;

  /// Chuẩn hóa danh sách 7 ngày Thứ 2 -> Chủ nhật của tuần chứa `referenceDate`
  /// từ map dữ liệu thật đọc về từ bảng `user_quest_logs`.
  static List<DailyStreakDay> buildCurrentWeekDays({
    required DateTime referenceDate,
    required int dailyGoalMinutes,
    required Map<String, ({int completedMinutes, int goalMinutes, bool isCompleted})>
        logsByDateKey,
  }) {
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final fallbackGoal = dailyGoalMinutes > 0 ? dailyGoalMinutes : 15;

    return List<DailyStreakDay>.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final key = formatDateKey(day);
      final log = logsByDateKey[key];
      final goal = (log != null && log.goalMinutes > 0)
          ? log.goalMinutes
          : fallbackGoal;
      final completed = log?.completedMinutes ?? 0;
      final done = (log?.isCompleted ?? false) || completed >= goal;

      return DailyStreakDay(
        date: day,
        completedMinutes: completed,
        goalMinutes: goal,
        isCompleted: done,
        isToday: day == today,
        isFuture: day.isAfter(today),
      );
    });
  }

  static String formatDateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
