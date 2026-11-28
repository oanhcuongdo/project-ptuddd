/// Cấu hình chung của ứng dụng (Dart thuần, không phụ thuộc Flutter/Firebase).
///
/// Mọi "con số ma thuật" (giới hạn, ngưỡng, tên model...) đều đặt ở đây để
/// dễ chỉnh sửa và dễ trình bày khi bảo vệ đồ án.
class AppConfig {
  AppConfig._();

  /// Tên model Gemini dùng cho Firebase AI Logic (Gemini Developer API).
  ///
  /// Chỉ khai báo ở MỘT chỗ duy nhất. `gemini-3.8-flash` là model Flash ổn định,
  /// không cần bật billing (chạy được trên gói Spark) theo trang
  /// https://firebase.google.com/docs/ai-logic/models (11/2026).
  /// Nếu model này bị ngừng, đổi sang `gemini-3.5-flash-lite`.
  static const String geminiModel = 'gemini-3.8-flash';

  /// Số lần gọi AI tối đa trong 1 phút (giới hạn phía client).
  static const int maxAiCallsPerMinute = 6;

  /// Thời gian chờ tối đa cho một lần gọi AI.
  static const Duration aiTimeout = Duration(seconds: 30);

  /// Số món tối đa AI được trả về trong một ảnh.
  static const int maxItemsPerScan = 5;

  /// Số gợi ý tối đa gắn với một món.
  static const int maxTipsPerItem = 3;

  /// Số gợi ý tự chọn (theo quy tắc) khi người dùng nhập món thủ công.
  static const int maxTipsForManualItem = 2;

  /// Độ dài tối đa của ghi chú ngắn AI mô tả món.
  static const int shortNoteMaxLength = 100;

  /// Độ dài tối đa của câu "cách gọi món" trong chế độ Gọi món thông minh.
  static const int howToOrderMaxLength = 80;

  /// Một tuần được coi là "đủ dữ liệu" khi có ít nhất ngần này ngày có ghi nhận.
  static const int minLoggedDaysForSufficientWeek = 4;

  /// Ứng dụng chỉ dành cho người từ 18 tuổi trở lên.
  static const int minAge = 18;

  /// Múi giờ dùng để tính ngày/tuần và hiển thị.
  static const String timezone = 'Asia/Ho_Chi_Minh';

  /// Kích thước cạnh dài tối đa và chất lượng JPEG khi nén ảnh trước khi gửi AI.
  static const int imageMaxDimension = 1024;
  static const int imageJpegQuality = 80;

  /// Số món hiển thị trong danh sách "Ăn lại".
  static const int relogListLimit = 20;

  /// Giờ nhắc ghi bữa mặc định (định dạng HH:mm, giờ Việt Nam).
  static const List<String> defaultReminderTimes = ['07:30', '11:45', '18:30'];
}
