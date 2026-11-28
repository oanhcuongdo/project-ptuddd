# Dự Án Cuối Kỳ: Ứng Dụng Quản Lý Kỷ Luật & Luyện Tập Bóng Đá
*(Football Discipline & Training Tracker)*

> **Nhóm thực hiện:** Nhóm 1 - Lớp 65KTPM  
> **Học phần:** Phát triển ứng dụng trên thiết bị di động  
> **Nền tảng:** Flutter & Supabase  

---

## 📌 1. Giới thiệu Đề tài
Ứng dụng hỗ trợ các cầu thủ/người chơi bóng đá rèn luyện kỷ luật bản thân, theo dõi các bài tập kỹ thuật & thể lực hàng ngày, ghi chép nhật ký sau mỗi trận đấu/buổi tập, bấm giờ huấn luyện và thống kê phân tích phong độ cá nhân qua thời gian.

---

## 👥 2. Thành viên & Phân công công việc

| STT | Họ và Tên | Vai trò | Phân hệ phụ trách |
|:---:|:---|:---:|:---|
| 1 | **Nguyễn Khắc Sỹ** | **Trưởng nhóm** | **Giáo án Kỷ luật Bài tập (Football Habits & Streak 🔥):** Dashboard thói quen, check-in hằng ngày, chuỗi ngày kỷ luật liên tục. |
| 2 | **Nguyễn Minh Đức** | Thành viên | **Supabase Backend & Hồ sơ Cầu thủ (Baller Profile):** Thiết kế database Supabase, Auth (Đăng nhập/Đăng ký), thông tin cầu thủ (vị trí, chân thuận, số áo). |
| 3 | **Bùi Đức Hiệp** | Thành viên | **Bộ đếm Phiên tập Huấn luyện (Drill Timer & Cloud Log):** Đồng hồ bấm giờ drill bài tập, tạm dừng/chuyển hiệp, tự động lưu lịch sử tập luyện lên Cloud. |
| 4 | **Hà Văn Phong** | Thành viên | **Nhật ký Trận đấu & Buổi tập (Match Journal & Storage):** Đánh giá phong độ, số bàn thắng/kiến tạo, nhận xét sau trận, upload ảnh lên Supabase Storage. |
| 5 | **Nguyễn Hồng Thái** | Thành viên | **Thống kê Phong độ & Nhắc lịch ra sân (Analytics):** Biểu đồ thể lực, Heatmap kỷ luật tháng, tổng thời gian tập và lập lịch thông báo (`flutter_local_notifications`). |

Chi tiết hơn xem tại: [danhsachnhom.md](./danhsachnhom.md)

---

## 📂 3. Cấu trúc thư mục

```text
nhom01-65ktpm/
├── docs/                # Chứa tài liệu báo cáo, đề cương (PDF/Word)
├── danhsachnhom.md      # Chi tiết danh sách và phân công công việc
├── README.md            # Tài liệu tổng quan dự án (file này)
└── src/                 # Mã nguồn ứng dụng Flutter
    ├── lib/             # Mã nguồn chính (Dart)
    ├── android/         # Cấu hình dự án cho Android
    ├── ios/             # Cấu hình dự án cho iOS
    └── pubspec.yaml     # Cấu hình thư viện và tài nguyên
```

---

## 🚀 4. Hướng dẫn Dành Cho Thành Viên Khi Pull Về

### Yêu cầu trước khi chạy:
- Đã cài đặt **Flutter SDK** (khuyến nghị phiên bản `>= 3.13.x`).
- Đã cài đặt công cụ lập trình: **VS Code** (khuyên dùng) hoặc **Android Studio** kèm theo Flutter extension.
- Thiết bị chạy thử: **Android Emulator**, **Thiết bị thật (bật USB Debugging)**, hoặc **Chrome / Windows**.

### Các bước cài đặt và khởi chạy:

1. **Mở terminal và di chuyển vào thư mục mã nguồn (`src`)**:
   ```bash
   cd nhom01-65ktpm/src
   ```

2. **Tải các gói thư viện (Dependencies)**:
   ```bash
   flutter pub get
   ```

3. **Kiểm tra thiết bị kết nối**:
   ```bash
   flutter devices
   ```

4. **Khởi chạy ứng dụng**:
   ```bash
   flutter run
   ```

---

## ⚠️ 5. Quy Ước Làm Việc Nhóm Với Git (Rất quan trọng)

Để tránh **xung đột code (merge conflict)** và giữ repo sạch sẽ:

1. **Không commit đè trực tiếp lên nhánh chính khi chưa trao đổi:**
   * Mỗi thành viên tạo một branch riêng khi làm chức năng của mình:
     ```bash
     git checkout -b feature/<ten-thanh-vien>-<ten-chuc-nang>
     # Ví dụ: git checkout -b feature/duc-auth-profile
     ```
   * Sau khi hoàn thiện tính năng và test chạy ổn định, tạo Pull Request hoặc xin ý kiến trưởng nhóm để merge vào nhánh chính.

2. **Luôn cập nhật code mới nhất trước khi làm việc:**
   * Đầu mỗi buổi làm việc, chuyển về nhánh chính và pull code mới:
     ```bash
     git checkout nhom01-65ktpm
     git pull origin nhom01-65ktpm
     ```
   * Sau đó merge/rebase vào nhánh tính năng của bạn.

3. **Không đẩy các file rác / build cache:**
   * Tuyệt đối không commit các thư mục `build/`, `.dart_tool/`, `.idea/`, file `.env` hoặc file tạm không cần thiết.
   * Trước khi `git add .`, luôn kiểm tra lại trạng thái bằng `git status`.

4. **Khi thêm thư viện mới vào `pubspec.yaml`:**
   * Thông báo lên nhóm Zalo/chat để các thành viên khác biết và chạy lại lệnh `flutter pub get` sau khi pull.
