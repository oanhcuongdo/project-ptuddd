/// Kiểm tra chuỗi có đúng dạng UUID không.
///
/// Bảng `notes`/`subjects` trên Supabase dùng khoá `uuid`; nếu gửi một id
/// không phải UUID (ví dụ id cũ sinh bằng `microsecondsSinceEpoch`) thì
/// PostgreSQL trả `22P02 invalid input syntax for type uuid`. Kiểm tra trước
/// để lỗi hiện ra dưới dạng thông báo rõ ràng thay vì request hỏng.
final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isUuid(String? value) => value != null && _uuidPattern.hasMatch(value);
