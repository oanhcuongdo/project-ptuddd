# Tài Liệu Hướng Dẫn Sử Dụng API Dịch Tức Thì (Instant Translation Service)

- **Học phần:** Phát Triển Ứng Dụng Di Động (PTUDDD) - Lớp 65KTPM
- **Dự án:** BuddyTalk - Ứng dụng kỷ luật cá nhân cải thiện kỹ năng giao tiếp và vượt rào cản ngôn ngữ
- **Phân hệ:** Kèm Online: Chat Thực Chiến 1-1 & Dịch Tức Thì
- **Người thực hiện:** Trương Tuấn Hải (MSSV: 2351170590)

---

## 1. Giới thiệu chức năng

Trong phân hệ phòng chat thực chiến 1-1 của BuddyTalk, người học thường ghép đôi với bạn đồng hành bù trừ ngôn ngữ (Ví dụ: Người Việt kèm người nước ngoài). Khi gặp câu nói khó hiểu hoặc từ vựng mới, người dùng chỉ cần nhấn nút **"Dịch tức thì"** cạnh tin nhắn, hệ thống sẽ dịch ngay lập tức mà không cần thoát ứng dụng sang Google Dịch.

## 2. Các tính năng kỹ thuật nổi bật

1. **Tốc độ phản hồi cực nhanh (< 200ms):** Sử dụng Google Translate Client GTX công khai, không cần đăng ký API Key phức tạp hay trả phí.
2. **Bộ nhớ đệm thông minh (In-memory Cache):** Tự động lưu trữ các câu đã dịch trong phiên chat. Khi người dùng bấm lại nút dịch hoặc lướt qua lại tin nhắn cũ, hệ thống lấy kết quả ngay trong 0ms từ Cache, tiết kiệm 100% băng thông mạng.
3. **Dịch 2 chiều linh hoạt:** Hỗ trợ dịch chuyên sâu `Anh -> Việt`, `Việt -> Anh`, hoặc `Tự động nhận diện (Auto)`.
4. **Không phụ thuộc thư viện ngoài (Zero Dependency):** Xây dựng hoàn toàn bằng `dart:io` và `dart:convert`, tương thích 100% với mọi nền tảng Flutter/Dart.
5. **Khả năng chịu lỗi cao:** Bắt trọn vẹn ngoại lệ Timeout (5 giây), mất mạng Internet (SocketException), trả về đối tượng `TranslationResult` an toàn, chống crash ứng dụng.

## 3. Cấu trúc thư mục mã nguồn

```text
nhom9-65ktpm/
├── docs/
│   └── HUONG_DAN_SU_DUNG_TRANSLATION_API.md  # Tài liệu kỹ thuật
└── src/
    ├── lib/
    │   └── features/
    │       └── chat_online/
    │           ├── models/
    │           │   └── translation_result.dart # Model kết quả dịch & CSDL
    │           └── services/
    │               └── translation_service.dart # Service gọi API dịch
    └── test/
        └── translation_service_test.dart       # Kiểm thử độc lập
```

## 4. Hướng dẫn tích hợp vào Giao diện Chat (UI)

Dành cho thành viên phụ trách giao diện Chat (Đỗ Việt Tiến):

```dart
import 'package:nhom9_65ktpm/features/chat_online/services/translation_service.dart';
import 'package:nhom9_65ktpm/features/chat_online/models/translation_result.dart';

// 1. Khởi tạo service (Singleton dùng chung)
final translationService = TranslationService();

// 2. Gọi dịch câu chat khi bấm nút icon Dịch
void onTranslateButtonPressed(String messageContent) async {
  final TranslationResult result = await translationService.translateEnToVi(messageContent);

  if (result.isSuccess) {
    print('Câu dịch: ${result.translatedText}');
    // setState() để hiển thị bản dịch ngay dưới bong bóng chat
  } else {
    // Hiển thị SnackBar thông báo: result.errorMessage
  }
}
```

