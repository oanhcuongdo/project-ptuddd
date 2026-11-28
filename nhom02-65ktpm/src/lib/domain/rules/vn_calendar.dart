/// Tiện ích ngày/tuần theo giờ Việt Nam (Dart thuần, không cần package).
///
/// Việt Nam dùng UTC+7 cố định, KHÔNG có giờ mùa hè, nên chỉ cần cộng 7 giờ.
/// Quy ước trong file này:
/// - "instant": DateTime UTC thật (giá trị lưu trong Firestore).
/// - "VN date": DateTime.utc(y, m, d) đại diện cho NGÀY theo lịch Việt Nam
///   (chỉ dùng phần năm/tháng/ngày, không mang nghĩa thời điểm).
///
/// Tuần bắt đầu thứ Hai 00:00 và kết thúc Chủ nhật 23:59:59 (giờ Việt Nam).
class VnCalendar {
  VnCalendar._();

  static const Duration offset = Duration(hours: 7);

  /// Đổi một thời điểm sang "giờ treo tường" Việt Nam (vẫn mang cờ UTC).
  static DateTime toVnWallClock(DateTime instant) => instant.toUtc().add(offset);

  /// Ngày (theo lịch Việt Nam) chứa thời điểm [instant].
  static DateTime vnDateOf(DateTime instant) {
    final wall = toVnWallClock(instant);
    return DateTime.utc(wall.year, wall.month, wall.day);
  }

  /// Ngày thứ Hai đầu tuần (theo lịch Việt Nam) chứa [instant].
  static DateTime weekStartOf(DateTime instant) {
    final date = vnDateOf(instant);
    // DateTime.weekday: Monday = 1 ... Sunday = 7
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  /// Thời điểm UTC tương ứng 00:00 giờ Việt Nam của ngày [vnDate].
  static DateTime startOfVnDateUtc(DateTime vnDate) =>
      DateTime.utc(vnDate.year, vnDate.month, vnDate.day).subtract(offset);

  /// Khoảng [start, end) theo UTC của tuần bắt đầu bằng thứ Hai [weekStart].
  static ({DateTime start, DateTime end}) weekRangeUtc(DateTime weekStart) {
    final start = startOfVnDateUtc(weekStart);
    return (start: start, end: start.add(const Duration(days: 7)));
  }

  /// Khoảng [start, end) theo UTC của một ngày Việt Nam.
  static ({DateTime start, DateTime end}) dayRangeUtc(DateTime vnDate) {
    final start = startOfVnDateUtc(vnDate);
    return (start: start, end: start.add(const Duration(days: 1)));
  }

  /// "yyyy-MM-dd" của một VN date (dùng cho `week_start`).
  static String dateKey(DateTime vnDate) {
    final m = vnDate.month.toString().padLeft(2, '0');
    final d = vnDate.day.toString().padLeft(2, '0');
    return '${vnDate.year}-$m-$d';
  }

  /// Đọc "yyyy-MM-dd" thành VN date.
  static DateTime parseDateKey(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime.utc(parts[0], parts[1], parts[2]);
  }

  /// Phút trong ngày theo giờ Việt Nam (0..1439), dùng để chọn bữa mặc định.
  static int minuteOfDayVn(DateTime instant) {
    final wall = toVnWallClock(instant);
    return wall.hour * 60 + wall.minute;
  }

  /// Ghép ngày Việt Nam [vnDate] với giờ/phút Việt Nam thành thời điểm UTC.
  static DateTime combineVn(DateTime vnDate, int hour, int minute) =>
      startOfVnDateUtc(vnDate).add(Duration(hours: hour, minutes: minute));
}
