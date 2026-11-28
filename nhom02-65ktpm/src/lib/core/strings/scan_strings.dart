/// Chuỗi của phân hệ Quét món ăn bằng AI và Nhập tên món.
class ScanStrings {
  ScanStrings._();

  // Lựa chọn trong bottom sheet
  static const scanMeal = 'Quét món ăn';
  static const scanMealSub = 'Chụp món ăn hoặc đồ uống để AI đánh giá';
  static const fromGallery = 'Chọn ảnh có sẵn';
  static const fromGallerySub = 'Lấy ảnh món ăn từ thư viện';
  static const typeName = 'Nhập tên món';
  static const typeNameSub = 'Gõ tên món, AI đánh giá giúp bạn';

  // Màn hình quét
  static const scanTitle = 'Quét món ăn';
  static const analyzing = 'Đang phân tích món ăn...';
  static const privacyNote = 'Ảnh chỉ dùng để phân tích, không được lưu lại.';
  static const pickAgain = 'Chọn ảnh khác';
  static const manualEntry = 'Nhập thủ công';

  // Nhập tên món
  static const textTitle = 'Nhập tên món';
  static const textHint = 'Ví dụ: bún bò Huế, trà sữa trân châu';
  static const textLabel = 'Tên món ăn / đồ uống';
  static const analyze = 'Phân tích';
  static const chooseLevelsYourself = 'Tự chọn mức độ';
  static const textNameRequired = 'Nhập tên món trước nhé';

  // Lỗi AI (luôn kèm lối thoát sang nhập thủ công)
  static const rateLimited = 'Bạn quét hơi nhanh, đợi một chút nhé.';
  static const network = 'Không có kết nối mạng. Bạn có thể nhập thủ công, khi có mạng app sẽ tự đồng bộ.';
  static const quota = 'Dịch vụ AI đang tạm hết lượt miễn phí. Bạn nhập thủ công giúp mình nhé.';
  static const timeout = 'AI phản hồi hơi lâu, bạn thử lại hoặc nhập thủ công nhé.';
  static const appCheck = 'Không xác thực được ứng dụng với dịch vụ AI.';
  static const appCheckDebugHint =
      'Bản debug: kiểm tra đã thêm App Check debug token (in trong logcat) vào '
      'Firebase Console > App Check > Manage debug tokens chưa.';
  static const invalidResponse = 'Chưa đọc được kết quả từ AI. Bạn thử lại hoặc nhập thủ công nhé.';
  static const notRecognized = 'Mình chưa nhận ra món ăn hay đồ uống nào. Bạn thử ảnh khác hoặc nhập thủ công nhé.';
  static const unknown = 'AI đang gặp trục trặc. Bạn thử lại sau hoặc nhập thủ công nhé.';
}
