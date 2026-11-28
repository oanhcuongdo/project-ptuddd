# Danh Sách Thành Viên - Nhóm 01 (nhom01-65ktpm)

- **Lớp học phần / Lớp sinh hoạt:** 65KTPM
- **Tên đề tài / Ứng dụng:** Ứng dụng Quản lý Kỷ luật & Luyện tập Bóng đá (Football Discipline & Training Tracker)
- **Giảng viên hướng dẫn:** [Tên Giảng viên]

---

## 1. Bảng Thông Tin Thành Viên

| STT | Họ và Tên | Mã Sinh Viên | Lớp Sinh Hoạt | Vai Trò | Nhiệm Vụ Phân Công | Đóng Góp (%) | Email |
| :---: | :--- | :---: | :---: | :---: | :--- | :---: | :--- |
| 1 | Nguyễn Minh Đức  | [MSV 1] | 65KTPM | Thành viên | Supabase Cloud Backend & Hồ sơ Cầu thủ (Baller Profile) | 100% | member1@example.com |
| 2 | Nguyễn Khắc Sỹ| [MSV 2] | 65KTPM | Trưởng nhóm | Giáo án Kỷ luật Bài tập (Football Habits & Streak 🔥) | 100% | member2@example.com |
| 3 | Bùi Đức Hiệp | [MSV 3] | 65KTPM | Thành viên | Bộ đếm Phiên tập Huấn luyện (Drill Timer & Cloud Log) | 100% | hieptop12@gmail.com |
| 4 | Hà Văn Phong| [MSV 4] | 65KTPM | Thành viên | Nhật ký Trận đấu & Buổi tập (Match Journal & Storage) | 100% | member4@example.com |
| 5 | Nguyễn Hồng Thái  | [MSV 5] | 65KTPM | Thành viên | Thống kê Phong độ Cầu thủ & Nhắc lịch ra sân (Analytics) | 100% | ngotuananh2005@gmail.com |

---

## 2. Bảng Phân Công Công Việc Chi Tiết

| Thành viên | Phân hệ phụ trách | Nội dung công việc chi tiết |
| :--- | :--- | :--- |
| **Nguyễn Minh Đức**<br> | **Supabase Cloud Backend & Hồ sơ Cầu thủ (Baller Profile)** | • Thiết lập Project Supabase, viết Script SQL tạo 5 bảng CSDL và cấu hình bảo mật Row Level Security (RLS).<br>• Xây dựng màn hình Đăng ký, Đăng nhập (Email/Password), Quên mật khẩu.<br>• Màn hình Hồ sơ Cầu thủ (Baller Profile): Quản lý vị trí thi đấu, Chân thuận, Số áo thi đấu, Đội bóng tham gia, cập nhật Avatar. |
| **Nguyễn Khắc Sỹ** | **Giáo án Kỷ luật Bài tập (Football Habits & Streak 🔥)** | • Thiết kế Dashboard hiển thị danh sách bài tập kỷ luật hôm nay theo 3 nhóm: Kỹ thuật bóng đá, Thể lực & Dinh dưỡng.<br>• Chức năng Thêm/Sửa/Xóa thói quen bóng đá (định tính & định lượng: tâng bóng, chạy km, số lít nước...).<br>• Hệ thống check-in hoàn thành bài tập hàng ngày, tính chuỗi Kỷ luật sân cỏ liên tục (Streak 🔥 ngày tập luyện). |
| **Bùi Đức Hiệp** | **Bộ đếm Phiên tập Huấn luyện (Drill Timer & Cloud Log)** | • Thiết kế Đồng hồ bấm giờ tập luyện chuyên biệt: Đếm ngược thời gian bài tập (VD: Bài tập thể lực 20 phút, bài tập tâng bóng 15 phút, thời gian nghỉ hiệp).<br>• Hỗ trợ các nút Bắt đầu, Tạm dừng, Hết hiệp và Chuyển bài drill tiếp theo.<br>• Tự động ghi nhận số phút tập luyện thực tế vào bảng `training_drills_sessions` trên Supabase. |
| **Hà Văn Phong** | **Nhật ký Trận đấu & Buổi tập (Match Journal & Storage)** | • Giao diện Nhật ký sau trận đấu/buổi tập: Đánh giá phong độ (1 - 5 sao), ghi nhận chỉ số cá nhân (số bàn thắng, số kiến tạo, vị trí đá hôm nay).<br>• Soạn thảo nhận xét: *"Hôm nay xử lý bóng tốt pha nào? Pha nào bị mất bóng cần sửa?"*.<br>• Chụp/chọn ảnh sân bóng, đội bóng và upload trực tiếp lên Supabase Storage (Bucket ảnh). |
| **Nguyễn Hồng Thái** | **Thống kê Phong độ Cầu thủ & Nhắc lịch ra sân (Analytics)** | • Màn hình Thống kê: Tỷ lệ hoàn thành kỷ luật theo Ngày, Biểu đồ cột thể lực 7 ngày qua (`fl_chart`), Lưới lịch nhiệt Heatmap cả tháng.<br>• Báo cáo tổng hợp: Tổng số phút tập luyện trong tuần/tháng, số trận ra sân thi đấu.<br>• Lập lịch thông báo (`flutter_local_notifications`): Hẹn giờ nhắc nhở xách giày đi tập bóng đá theo lịch cố định và thông báo nhắc giãn cơ/nghỉ ngơi. |

---

## 3. Hướng Dẫn Cài Đặt & Khởi Chạy Ứng Dụng

### Yêu cầu môi trường:
- Flutter SDK (phiên bản `>= 3.0.0`)
- Dart SDK
- Thiết bị chạy thử: Android Emulator / Thiết bị thật / iOS Simulator

### Các bước chạy dự án:
```bash
# 1. Di chuyển vào thư mục mã nguồn
cd nhom01-65ktpm/src

# 2. Cài đặt các dependencies
flutter pub get

# 3. Khởi chạy ứng dụng
flutter run
```
