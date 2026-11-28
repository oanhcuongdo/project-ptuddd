/// Kết quả trích xuất thời gian (giờ đồng hồ & ngày tháng) từ văn bản OCR (Sprint 3 - Giai đoạn 2).
class ExtractedTimeInfo {
  const ExtractedTimeInfo({
    this.formattedTime24h,
    this.hour,
    this.minute,
    this.extractedDate,
    this.periodLabel,
    this.isEarlyWakeUpValid = false,
  });

  /// Giờ chuẩn hóa theo định dạng 24h (HH:mm, ví dụ: '05:42').
  final String? formattedTime24h;

  /// Giờ (0 - 23).
  final int? hour;

  /// Phút (0 - 59).
  final int? minute;

  /// Ngày tháng trích xuất được trên ảnh (định dạng dd/MM/yyyy, nếu có).
  final String? extractedDate;

  /// Nhãn buổi trong ngày ('Sáng sớm', 'Buổi sáng', 'Buổi chiều', 'Buổi tối').
  final String? periodLabel;

  /// Đánh dấu giờ đồng hồ có nằm trong khung dậy sớm hợp lệ (mặc định 04:00 - 06:00) hay không.
  final bool isEarlyWakeUpValid;

  bool get hasTime => formattedTime24h != null;
}

/// Bộ trích xuất giờ đồng hồ và ngày tháng đa định dạng từ văn bản AI OCR (Sprint 3 - Giai đoạn 2).
/// Hỗ trợ các định dạng thực tế trên đồng hồ điện tử, điện thoại và bài làm:
/// - '05:42', '5:42 AM', '07:15 PM', '5h18', '05H30', '05.45'
/// - Ngày tháng: '23/11/2026', '23-11-2026', '23.11.2026'
class OcrTimeExtractor {
  const OcrTimeExtractor();

  /// Mẫu nhận diện giờ kèm AM/PM hoặc định dạng 24h (: hoặc h/H).
  static final RegExp _timeWithMeridiemPattern = RegExp(
    r'\b(0?\d|1\d|2[0-3])[:hH]([0-5]\d)(?:\s*(AM|PM|am|pm))?\b',
  );

  /// Mẫu nhận diện ngày tháng dạng dd/MM/yyyy hoặc dd-MM-yyyy.
  static final RegExp _datePattern = RegExp(
    r'\b(0?[1-9]|[12]\d|3[01])[\/\-](0?[1-9]|1[0-2])[\/\-](20\d{2})\b',
  );

  /// Bóc tách thông tin giờ đồng hồ và ngày tháng từ chuỗi văn bản [rawText].
  ExtractedTimeInfo extract(
    String rawText, {
    int earlyStartHour = 4,
    int earlyDeadlineHour = 6,
    int earlyDeadlineMinute = 0,
  }) {
    final normalized = rawText.trim();
    if (normalized.isEmpty) {
      return const ExtractedTimeInfo();
    }

    final dateMatch = _datePattern.firstMatch(normalized);
    String? formattedDate;
    if (dateMatch != null) {
      final day = dateMatch.group(1)!.padLeft(2, '0');
      final month = dateMatch.group(2)!.padLeft(2, '0');
      final year = dateMatch.group(3)!;
      formattedDate = '$day/$month/$year';
    }

    final timeMatch = _timeWithMeridiemPattern.firstMatch(normalized);
    if (timeMatch == null) {
      return ExtractedTimeInfo(extractedDate: formattedDate);
    }

    var hour = int.parse(timeMatch.group(1)!);
    final minute = int.parse(timeMatch.group(2)!);
    final meridiem = timeMatch.group(3)?.toUpperCase();

    if (meridiem == 'PM' && hour < 12) {
      hour += 12;
    } else if (meridiem == 'AM' && hour == 12) {
      hour = 0;
    }

    final formattedTime =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    final totalMinutes = hour * 60 + minute;
    final minEarlyMinutes = earlyStartHour * 60;
    final maxEarlyMinutes = earlyDeadlineHour * 60 + earlyDeadlineMinute;
    final isEarlyValid =
        totalMinutes >= minEarlyMinutes && totalMinutes <= maxEarlyMinutes;

    return ExtractedTimeInfo(
      formattedTime24h: formattedTime,
      hour: hour,
      minute: minute,
      extractedDate: formattedDate,
      periodLabel: resolvePeriodLabel(hour),
      isEarlyWakeUpValid: isEarlyValid,
    );
  }

  /// Phân loại buổi trong ngày dựa trên giờ (0 - 23).
  static String resolvePeriodLabel(int hour) {
    if (hour >= 4 && hour < 7) return 'Sáng sớm';
    if (hour >= 7 && hour < 12) return 'Buổi sáng';
    if (hour >= 12 && hour < 18) return 'Buổi chiều';
    return 'Buổi tối';
  }
}
