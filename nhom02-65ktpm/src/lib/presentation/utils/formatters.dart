import 'package:intl/intl.dart';

import '../../core/strings/diary_strings.dart';
import '../../domain/rules/vn_calendar.dart';

/// Định dạng ngày giờ hiển thị theo giờ Việt Nam (locale vi_VN).
class Formatters {
  Formatters._();

  /// "07:30" theo giờ Việt Nam.
  static String time(DateTime instant) =>
      DateFormat('HH:mm', 'vi_VN').format(VnCalendar.toVnWallClock(instant));

  /// "23/11".
  static String shortDate(DateTime vnDate) => DateFormat('dd/MM', 'vi_VN').format(vnDate);

  /// "23/11 07:30".
  static String dateTime(DateTime instant) =>
      DateFormat('dd/MM HH:mm', 'vi_VN').format(VnCalendar.toVnWallClock(instant));

  /// "Hôm nay", "Hôm qua" hoặc "Thứ Hai, 23/11".
  static String dayLabel(DateTime vnDate, {DateTime? now}) {
    final today = VnCalendar.vnDateOf(now ?? DateTime.now());
    final diff = today.difference(vnDate).inDays;
    if (diff == 0) return DiaryStrings.today;
    if (diff == 1) return DiaryStrings.yesterday;
    final text = DateFormat('EEEE, dd/MM', 'vi_VN').format(vnDate);
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }
}
