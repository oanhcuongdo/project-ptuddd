/// Chuỗi của phân hệ Nhật ký, Xác nhận bữa ăn, Ăn lại, Thùng rác.
class DiaryStrings {
  DiaryStrings._();

  static const title = 'Nhật ký';
  static const today = 'Hôm nay';
  static const yesterday = 'Hôm qua';
  static const emptyDay = 'Chưa có bữa nào trong ngày này';
  static const emptyDayHint = 'Ghi lại bữa ăn để theo dõi thói quen của bạn nhé.';
  static const addManual = 'Thêm thủ công';
  static const addToMeal = 'Thêm món';
  static const trash = 'Thùng rác';
  static const movedToTrash = 'Đã chuyển bữa ăn vào thùng rác';
  static const loadError = 'Không tải được nhật ký. Kéo xuống để thử lại.';
  static const previousDay = 'Ngày trước';
  static const nextDay = 'Ngày sau';
  static String itemCount(int n) => '$n món';
}

class ReviewStrings {
  ReviewStrings._();

  static const titleNew = 'Xác nhận bữa ăn';
  static const titleEdit = 'Sửa bữa ăn';
  static const mealType = 'Bữa';
  static const time = 'Thời gian';
  static const dishName = 'Tên món';
  static const dishNameHint = 'Ví dụ: bún bò Huế';
  static const nameRequired = 'Nhập tên món';
  static const category = 'Loại món';
  static const levels = 'Mức độ (chạm để sửa)';
  static const tips = 'Gợi ý cho bạn';
  static const checkAgain = 'Vui lòng kiểm tra lại';
  static const addItem = 'Thêm món';
  static const removeItem = 'Bỏ món này';
  static const selectAtLeastOne = 'Chọn ít nhất một món để lưu';
  static const tooManyItems = 'Một bữa tối đa 10 món';
  static const saved = 'Đã lưu bữa ăn';
  static const discardTitle = 'Bỏ thay đổi?';
  static const discardMessage = 'Bữa ăn chưa được lưu. Bạn có muốn thoát không?';
  static const discard = 'Thoát';
  static const keepEditing = 'Ở lại';
  static const aiNote = 'Mô tả';
}

class RelogStrings {
  RelogStrings._();

  static const title = 'Ăn lại';
  static const empty = 'Chưa có món nào. Món bạn lưu sẽ xuất hiện ở đây để ghi lại nhanh.';
  static const recent = 'Gần đây';
  static const frequent = 'Hay ăn';
  static String useCount(int n) => 'Đã ăn $n lần';
  static String logged(String name) => 'Đã ghi lại "$name"';
  static const tapHint = 'Chạm để ghi lại ngay • Giữ để sửa trước khi lưu';
}

class TrashStrings {
  TrashStrings._();

  static const title = 'Thùng rác';
  static const empty = 'Thùng rác trống';
  static const restore = 'Khôi phục';
  static const deleteForever = 'Xóa vĩnh viễn';
  static const restored = 'Đã khôi phục bữa ăn';
  static const deleted = 'Đã xóa vĩnh viễn';
  static const emptyTrash = 'Dọn sạch thùng rác';
  static const confirmDeleteTitle = 'Xóa vĩnh viễn?';
  static const confirmDeleteMessage = 'Bữa ăn sẽ bị xóa hẳn và không thể khôi phục.';
  static const confirmEmptyMessage = 'Toàn bộ bữa ăn trong thùng rác sẽ bị xóa hẳn và không thể khôi phục.';
  static String deletedAt(String when) => 'Đã xóa $when';
}

class ScanSheetStrings {
  ScanSheetStrings._();

  static const title = 'Ghi bữa ăn';
  static const manual = 'Nhập thủ công';
  static const manualSub = 'Tự chọn mức độ bằng chip, không cần mạng';
  static const relog = 'Ăn lại';
  static const relogSub = 'Ghi nhanh món bạn hay ăn';
}
