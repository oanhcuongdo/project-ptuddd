import 'package:flutter_test/flutter_test.dart';
import 'package:src/models/analytics_model.dart';
import 'package:src/models/reminder_model.dart';

void main() {
  group('Kiểm thử Đơn vị (Unit Test) - Phân hệ 5: Analytics & Reminders (Nguyễn Hồng Thái)', () {
    test('1. DailyDisciplineStat tính toán tỷ lệ % hoàn thành chính xác', () {
      final stat1 = DailyDisciplineStat(
        date: DateTime(2026, 11, 22),
        completedHabits: 3,
        totalHabits: 4,
      );
      expect(stat1.completionRate, equals(75.0));

      final statZero = DailyDisciplineStat(
        date: DateTime(2026, 11, 22),
        completedHabits: 0,
        totalHabits: 0,
      );
      expect(statZero.completionRate, equals(0.0));

      final statFull = DailyDisciplineStat(
        date: DateTime(2026, 11, 22),
        completedHabits: 5,
        totalHabits: 5,
      );
      expect(statFull.completionRate, equals(100.0));
    });

    test('2. Chuyển đổi JSON DailyDisciplineStat và WeeklyFitnessStat chuẩn xác', () {
      final jsonStat = {
        'date': '2026-11-22',
        'completed_habits': 4,
        'total_habits': 5,
      };
      final daily = DailyDisciplineStat.fromJson(jsonStat);
      expect(daily.completedHabits, equals(4));
      expect(daily.totalHabits, equals(5));
      expect(daily.completionRate, equals(80.0));

      final weeklyJson = {
        'day_name': 'T2',
        'date': '2026-11-22',
        'duration_minutes': 60,
        'drills_count': 3,
      };
      final weekly = WeeklyFitnessStat.fromJson(weeklyJson);
      expect(weekly.dayName, equals('T2'));
      expect(weekly.durationMinutes, equals(60));
      expect(weekly.drillsCount, equals(3));
    });

    test('3. HeatmapDayData tính toán mức độ nhiệt intensityLevel từ 0 đến 4', () {
      expect(HeatmapDayData.calculateIntensity(0, 4), equals(0));
      expect(HeatmapDayData.calculateIntensity(1, 4), equals(1)); // 25%
      expect(HeatmapDayData.calculateIntensity(2, 4), equals(2)); // 50%
      expect(HeatmapDayData.calculateIntensity(3, 4), equals(3)); // 75%
      expect(HeatmapDayData.calculateIntensity(4, 4), equals(4)); // 100%
      expect(HeatmapDayData.calculateIntensity(0, 0), equals(0));
    });

    test('4. OverallSummaryReport khởi tạo, copyWith và chuyển đổi JSON toàn diện', () {
      const initial = OverallSummaryReport(
        totalTrainingMinutesWeek: 180,
        totalTrainingMinutesMonth: 720,
        totalMatches: 6,
        totalGoals: 4,
        totalAssists: 2,
        averageRating: 4.5,
        currentStreakDays: 10,
        disciplineRateMonth: 88.5,
      );

      final updated = initial.copyWith(
        totalMatches: 7,
        totalGoals: 5,
        averageRating: 4.8,
      );

      expect(updated.totalMatches, equals(7));
      expect(updated.totalGoals, equals(5));
      expect(updated.averageRating, equals(4.8));
      expect(updated.totalTrainingMinutesWeek, equals(180));
      expect(updated.currentStreakDays, equals(10));

      final json = updated.toJson();
      expect(json['total_matches'], equals(7));
      expect(json['total_goals'], equals(5));

      final restored = OverallSummaryReport.fromJson(json);
      expect(restored.totalMatches, equals(7));
      expect(restored.totalGoals, equals(5));
      expect(restored.averageRating, equals(4.8));
    });

    test('5. TrainingReminder định dạng thời gian và nhãn ngày lặp lại chuẩn xác', () {
      const reminder1 = TrainingReminder(
        id: 'rem_test_1',
        title: 'Tập sút phạt hàng rào',
        category: ReminderCategory.training,
        hour: 8,
        minute: 5,
        repeatDays: [1, 3, 5],
      );

      expect(reminder1.formattedTime, equals('08:05'));
      expect(reminder1.repeatDaysText, equals('T2, T4, T6'));
      expect(reminder1.isEnabled, isTrue);

      const reminderDaily = TrainingReminder(
        id: 'rem_test_2',
        title: 'Giãn cơ đêm',
        category: ReminderCategory.stretching,
        hour: 21,
        minute: 30,
        repeatDays: [1, 2, 3, 4, 5, 6, 7],
      );
      expect(reminderDaily.formattedTime, equals('21:30'));
      expect(reminderDaily.repeatDaysText, equals('Hàng ngày'));

      const reminderOnce = TrainingReminder(
        id: 'rem_test_3',
        title: 'Khám sức khỏe thể lực',
        category: ReminderCategory.fitness,
        hour: 15,
        minute: 0,
        repeatDays: [],
      );
      expect(reminderOnce.repeatDaysText, equals('Một lần'));

      final toggled = reminder1.copyWith(isEnabled: false);
      expect(toggled.isEnabled, isFalse);
      expect(toggled.id, equals('rem_test_1'));
    });
  });
}
