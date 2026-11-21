# Danh Sách Thành Viên - Nhóm 02

- **Lớp học phần:** Phát triển ứng dụng cho các thiết bị di động (`65KTPM`)
- **Tên đề tài / Ứng dụng:** NutriTrack AI – Ứng dụng Gợi ý và Hình thành Thói quen Ăn uống Lành mạnh bằng Nhận diện Hình ảnh và Điện toán Đám mây
- **Giảng viên hướng dẫn:** *(Đang cập nhật)*

## Bảng Thông Tin Thành Viên

| STT | Họ và Tên | Mã Sinh Viên | Lớp Sinh Hoạt | Vai Trò | Nhiệm Vụ Phân Công | Đóng Góp (%) | Email |
| :-: | --------- | ------------ | ------------- | ------- | ------------------ | :----------: | ----- |
| 1 | Phạm Văn Việt | 2351170633 | 65KTPM | Trưởng nhóm | Khởi tạo khung Flutter & DI GetIt (Issue #1); Backend Firebase & Security Rules (Issue #3); Chủ trì QA, Build APK Release & Báo cáo (Issue #12) | 100% | pvv210805@gmail.com |
| 2 | Nguyễn Hoàng Anh | 2251161939 | 64HTTT1 | Thành viên | Màn hình Auth, Quản lý hồ sơ & Mục tiêu (Issue #4); Gợi ý mục tiêu & Gọi món thông minh từ Menu (Issue #8) | 100% | hoanganhh6102004@gmail.com |
| 3 | Phùng Thành An | 2251061692 | 64CNTT2 | Thành viên | Nhật ký ăn uống, "Ăn lại" & Xóa mềm Tombstone (Issue #5); Quét món ăn bằng Gemini AI & Màn hình Review (Issue #7); Viết Unit Test Domain (Issue #12) | 100% | Phungthanhan257@gmail.com |
| 4 | Võ Mạnh Thắng | 2351170620 | 65KTPM | Thành viên | Tài liệu, đề cương & README nhóm (Issue #2); Thống kê thói quen & Báo cáo tuần fl_chart (Issue #9); Hoàn thiện UI Material 3 Dark/Light (Issue #11) | 100% | Thangvm515@gmail.com |
| 5 | Đặng Xuân Minh | 2251172421 | 64KTPM4 | Thành viên | Soạn thư viện Tips JSON & Thiết kế Prompt AI (Issue #6); Thử thách tuần, Streak & Nhắc nhở thông báo (Issue #10) | 100% | minh76720@gmail.com |

## Bảng Danh Sách Issues Và Phân Công Quản Lý Dự Án

| STT | Tiêu đề Issue (GitHub Title) | Người thực hiện (Assignee) | Tóm tắt nhiệm vụ |
| :-: | :--- | :--- | :--- |
| **#1** | `[Setup] Khởi tạo khung dự án Flutter (Layered Architecture) & DI GetIt` | **Phạm Văn Việt** | Dựng khung kiến trúc 4 tầng trong `src/`, cấu hình DI `get_it`, thiết lập routing ban đầu. |
| **#2** | `[Docs] Cập nhật thông tin đề tài NutriTrack AI & README nhóm` | **Võ Mạnh Thắng** | Cập nhật tên đề tài vào `danhsachnhom.md`, viết `README.md` của nhóm (giới thiệu, công nghệ, cách chạy). |
| **#3** | `[Backend] Kết nối Firebase (Auth, Firestore, App Check) & Security Rules` | **Phạm Văn Việt** | Liên kết FlutterFire, cấu hình App Check debug provider, bật Firestore Offline, viết Security Rules. |
| **#4** | `[Feature] Phân hệ 1 - Đăng ký, Đăng nhập, Hồ sơ & Mục tiêu cá nhân` | **Nguyễn Hoàng Anh** | Màn hình Auth (Email, Google), Onboarding chọn mục tiêu (Giảm cân / Cân bằng / Giảm đường), lưu Profile. |
| **#5** | `[Core Feature] Phân hệ 4 - Nhật ký Ăn uống, Thêm thủ công, "Ăn lại" & Xóa mềm` | **Phùng Thành An** | Màn hình Food Diary 4 bữa, form thêm thủ công, nút "Ăn lại" 1 chạm, xóa mềm Tombstone kèm Undo SnackBar. |
| **#6** | `[Data/AI] Soạn thư viện 30-50 Tips gợi ý, Script nạp Firestore & Prompt AI` | **Đặng Xuân Minh** | Soạn 30–50 tips JSON, script nạp Firestore `tips_library`, kiểm thử Prompt & Schema trên Google AI Studio. |
| **#7** | `[Core Feature] Phân hệ 2 - Quét ảnh món ăn bằng Gemini AI & Màn hình Review` | **Phùng Thành An** | Tích hợp camera/thư viện, nén ảnh client, gọi Gemini AI bóc tách JSON đa món, màn hình Review sửa kết quả. |
| **#8** | `[AI/Feature] Phân hệ 3 - Gợi ý theo mục tiêu & Gọi món thông minh từ Menu` | **Nguyễn Hoàng Anh** | Ghép mã gợi ý AI với kho tips; tính năng quét ảnh thực đơn quán ăn đề xuất món và cách gọi phù hợp. |
| **#9** | `[Feature] Phân hệ 5 - Thống kê thói quen & Báo cáo tuần với fl_chart` | **Võ Mạnh Thắng** | Vẽ biểu đồ `fl_chart` so sánh thói quen tuần, bộ quy tắc phản hồi (rule-based), xử lý khi thiếu dữ liệu (< 4 ngày). |
| **#10** | `[Feature] Phân hệ 6 - Thử thách tuần, Chuỗi Streak & Nhắc nhở thông báo` | **Đặng Xuân Minh** | Đề xuất thử thách tuần, tự tính chuỗi Streak, cài thông báo nhắc giờ bằng `flutter_local_notifications`. |
| **#11** | `[UI/UX] Hoàn thiện giao diện Material 3, Dark/Light Mode & Trạng thái rỗng/lỗi` | **Võ Mạnh Thắng** | Hoàn thiện theme Material 3 Dark/Light, hiệu ứng Shimmer loading, thiết kế màn hình rỗng (Empty state). |
| **#12** | `[QA/Release] Viết Unit Test Domain, Build APK Release & Hoàn thiện Báo cáo` | **Phùng Thành An** + **Phạm Văn Việt** | An viết Unit Test cho tầng Domain (logic tips, thử thách, dữ liệu); Việt build APK Release và tổng hợp báo cáo/slide. |

## Hướng Dẫn Thiết Lập Môi Trường Và Khởi Chạy Ứng Dụng

### 1. Yêu cầu môi trường
- **Flutter SDK:** Phiên bản `>= 3.22.0` (kênh stable)
- **Dart SDK:** Phiên bản `>= 3.4.0`
- **Android Studio / VS Code:** Cài đặt tiện ích mở rộng Flutter và Dart
- **Thiết bị:** Android Emulator (API 30+) hoặc thiết bị Android thật (bật USB Debugging)
- **Firebase CLI & FlutterFire CLI:** Đã đăng nhập và cấu hình dự án Firebase

### 2. Các bước cài đặt và chạy ứng dụng
```bash
# 1. Di chuyển vào thư mục mã nguồn
cd nhom02-65ktpm/src

# 2. Cài đặt các thư viện phụ thuộc
flutter pub get

# 3. Kiểm tra thiết bị kết nối
flutter devices

# 4. Khởi chạy ứng dụng ở chế độ debug
flutter run
```
