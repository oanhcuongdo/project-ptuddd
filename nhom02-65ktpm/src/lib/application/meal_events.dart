import 'dart:async';

/// "Bảng tin" báo nhật ký vừa thay đổi (lưu / xóa / khôi phục bữa ăn).
///
/// Phân hệ khác (ví dụ Thử thách tuần) lắng nghe [changes] để tính lại tiến độ
/// mà không cần sửa code của phân hệ Nhật ký.
class MealEvents {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get changes => _controller.stream;

  void notifyChanged() => _controller.add(null);
}
