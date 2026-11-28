/// Mô hình dữ liệu Thống kê & Phân tích phong độ cầu thủ (Analytics)
/// Tác giả: Nguyễn Hồng Thái (Phân hệ 5 - Thống kê & Nhắc lịch ra sân)
class DailyDisciplineStat {
  final DateTime date;
  final int completedHabits;
  final int totalHabits;

  const DailyDisciplineStat({
    required this.date,
    required this.completedHabits,
    required this.totalHabits,
  });

  /// Tỷ lệ hoàn thành kỷ luật trong ngày (%)
  double get completionRate {
    if (totalHabits == 0) return 0.0;
    return (completedHabits / totalHabits * 100).clamp(0.0, 100.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().substring(0, 10),
      'completed_habits': completedHabits,
      'total_habits': totalHabits,
      'completion_rate': completionRate,
    };
  }

  factory DailyDisciplineStat.fromJson(Map<String, dynamic> json) {
    return DailyDisciplineStat(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      completedHabits: json['completed_habits'] as int? ?? 0,
      totalHabits: json['total_habits'] as int? ?? 0,
    );
  }
}

/// Thống kê thể lực & thời lượng tập luyện trong tuần (7 ngày)
class WeeklyFitnessStat {
  final String dayName; // T2, T3, T4, T5, T6, T7, CN
  final DateTime date;
  final int durationMinutes; // Số phút tập luyện
  final int drillsCount; // Số bài drill hoàn thành

  const WeeklyFitnessStat({
    required this.dayName,
    required this.date,
    required this.durationMinutes,
    required this.drillsCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'day_name': dayName,
      'date': date.toIso8601String().substring(0, 10),
      'duration_minutes': durationMinutes,
      'drills_count': drillsCount,
    };
  }

  factory WeeklyFitnessStat.fromJson(Map<String, dynamic> json) {
    return WeeklyFitnessStat(
      dayName: json['day_name'] as String? ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      drillsCount: json['drills_count'] as int? ?? 0,
    );
  }
}

/// Dữ liệu từng ô trong Lưới lịch nhiệt Heatmap cả tháng
class HeatmapDayData {
  final DateTime date;
  final int intensityLevel; // 0: Chưa tập, 1: Nhẹ (1-25%), 2: Vừa (26-50%), 3: Tốt (51-75%), 4: Xuất sắc (76-100%)
  final int completedCount;
  final int totalCount;

  const HeatmapDayData({
    required this.date,
    required this.intensityLevel,
    required this.completedCount,
    required this.totalCount,
  });

  /// Tính mức độ nhiệt từ 0 đến 4 dựa trên tỷ lệ %
  static int calculateIntensity(int completed, int total) {
    if (total == 0 || completed == 0) return 0;
    final rate = completed / total;
    if (rate <= 0.25) return 1;
    if (rate <= 0.50) return 2;
    if (rate <= 0.75) return 3;
    return 4;
  }
}

/// Báo cáo tổng hợp phong độ & chỉ số thi đấu của cầu thủ
class OverallSummaryReport {
  final int totalTrainingMinutesWeek; // Tổng phút tập trong tuần
  final int totalTrainingMinutesMonth; // Tổng phút tập trong tháng
  final int totalMatches; // Tổng số trận đã ra sân
  final int totalGoals; // Tổng số bàn thắng
  final int totalAssists; // Tổng số kiến tạo
  final double averageRating; // Đánh giá phong độ trung bình (1.0 - 5.0 ⭐)
  final int currentStreakDays; // Chuỗi ngày kỷ luật liên tục (Streak 🔥)
  final double disciplineRateMonth; // Tỷ lệ hoàn thành kỷ luật tháng (%)

  const OverallSummaryReport({
    this.totalTrainingMinutesWeek = 0,
    this.totalTrainingMinutesMonth = 0,
    this.totalMatches = 0,
    this.totalGoals = 0,
    this.totalAssists = 0,
    this.averageRating = 0.0,
    this.currentStreakDays = 0,
    this.disciplineRateMonth = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_training_minutes_week': totalTrainingMinutesWeek,
      'total_training_minutes_month': totalTrainingMinutesMonth,
      'total_matches': totalMatches,
      'total_goals': totalGoals,
      'total_assists': totalAssists,
      'average_rating': averageRating,
      'current_streak_days': currentStreakDays,
      'discipline_rate_month': disciplineRateMonth,
    };
  }

  factory OverallSummaryReport.fromJson(Map<String, dynamic> json) {
    return OverallSummaryReport(
      totalTrainingMinutesWeek: json['total_training_minutes_week'] as int? ?? 0,
      totalTrainingMinutesMonth: json['total_training_minutes_month'] as int? ?? 0,
      totalMatches: json['total_matches'] as int? ?? 0,
      totalGoals: json['total_goals'] as int? ?? 0,
      totalAssists: json['total_assists'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      currentStreakDays: json['current_streak_days'] as int? ?? 0,
      disciplineRateMonth: (json['discipline_rate_month'] as num?)?.toDouble() ?? 0.0,
    );
  }

  OverallSummaryReport copyWith({
    int? totalTrainingMinutesWeek,
    int? totalTrainingMinutesMonth,
    int? totalMatches,
    int? totalGoals,
    int? totalAssists,
    double? averageRating,
    int? currentStreakDays,
    double? disciplineRateMonth,
  }) {
    return OverallSummaryReport(
      totalTrainingMinutesWeek: totalTrainingMinutesWeek ?? this.totalTrainingMinutesWeek,
      totalTrainingMinutesMonth: totalTrainingMinutesMonth ?? this.totalTrainingMinutesMonth,
      totalMatches: totalMatches ?? this.totalMatches,
      totalGoals: totalGoals ?? this.totalGoals,
      totalAssists: totalAssists ?? this.totalAssists,
      averageRating: averageRating ?? this.averageRating,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      disciplineRateMonth: disciplineRateMonth ?? this.disciplineRateMonth,
    );
  }
}
