import '../enums.dart';

/// Một gợi ý trong thư viện `tips/{code}` (đã soạn và kiểm duyệt sẵn).
///
/// AI KHÔNG tự viết lời khuyên; AI chỉ chọn [code], nội dung lấy từ đây.
class Tip {
  const Tip({
    required this.code,
    required this.title,
    required this.content,
    required this.goals,
    this.appliesTo = const {},
    this.priority = 0,
    this.source,
    this.active = true,
  });

  final String code;
  final String title;
  final String content;

  /// Các mục tiêu mà gợi ý này phù hợp.
  final List<Goal> goals;

  /// Điều kiện áp dụng: khóa ("category", "sugar_level", ...) -> danh sách giá trị.
  /// AND giữa các khóa, OR trong từng danh sách. Rỗng = áp dụng cho mọi món.
  final Map<String, List<String>> appliesTo;

  /// Ưu tiên cao hơn được chọn trước.
  final int priority;
  final String? source;
  final bool active;

  TipSnapshot toSnapshot() => TipSnapshot(code: code, title: title, content: content);
}

/// Bản sao nội dung gợi ý được lưu kèm bữa ăn tại thời điểm ghi.
///
/// Nhờ lưu bản sao, sửa thư viện tips về sau không làm thay đổi lịch sử.
class TipSnapshot {
  const TipSnapshot({required this.code, required this.title, required this.content});

  final String code;
  final String title;
  final String content;

  @override
  bool operator ==(Object other) =>
      other is TipSnapshot &&
      other.code == code &&
      other.title == title &&
      other.content == content;

  @override
  int get hashCode => Object.hash(code, title, content);
}
