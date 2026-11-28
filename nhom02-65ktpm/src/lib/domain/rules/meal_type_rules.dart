import '../enums.dart';
import 'vn_calendar.dart';

/// Chọn bữa mặc định theo giờ Việt Nam:
/// - 04:00–10:29: bữa sáng
/// - 10:30–14:29: bữa trưa
/// - 17:00–21:59: bữa tối
/// - còn lại: bữa phụ
class MealTypeRules {
  MealTypeRules._();

  static MealType defaultFor(DateTime instant) {
    final minute = VnCalendar.minuteOfDayVn(instant);
    if (minute >= 4 * 60 && minute < 10 * 60 + 30) return MealType.breakfast;
    if (minute >= 10 * 60 + 30 && minute < 14 * 60 + 30) return MealType.lunch;
    if (minute >= 17 * 60 && minute < 22 * 60) return MealType.dinner;
    return MealType.snack;
  }

  /// Giờ đại diện khi người dùng thêm bữa cho một ngày trong quá khứ.
  static ({int hour, int minute}) typicalTime(MealType type) => switch (type) {
        MealType.breakfast => (hour: 7, minute: 0),
        MealType.lunch => (hour: 12, minute: 0),
        MealType.dinner => (hour: 19, minute: 0),
        MealType.snack => (hour: 15, minute: 30),
      };
}
