# Danh sách thành viên — Nhóm 06

- **Đề tài:** HealthyLife — Trợ lý kỷ luật và lối sống lành mạnh.
- **Kế thừa:** Bài ứng dụng kỷ luật cá nhân với Flutter.
- **Lớp học phần / định danh:** 65KTPM / nhom06-65ktpm; lớp sinh hoạt từng người chờ xác nhận.
- **Giảng viên:** ThS. Đỗ Oanh Cường (theo mẫu, nhóm cần xác nhận).
- **Trạng thái:** Đề cương, khung Flutter và cấu hình client Firebase/Supabase chung; chưa triển khai chức năng hoặc khởi tạo backend trong ứng dụng.

| STT | Họ và tên | MSSV | Lớp sinh hoạt | Vai trò | Nhiệm vụ dự kiến | Đóng góp (%) | Email |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Nguyễn Thế Trưởng | 2351170626 | Chờ xác nhận | Nhóm trưởng | Kiến trúc, auth/profile/planner, JWT Firebase–Supabase, tích hợp/review/PR | Chờ xác nhận | Chờ xác nhận |
| 2 | Phương Văn Đức | 2351170585 | Chờ xác nhận | Thành viên | habits/sleep/notifications, UI responsive, streak và nhắc lịch | Chờ xác nhận | Chờ xác nhận |
| 3 | Hàn Hoàng Hà | 2051063882 | Chờ xác nhận | Thành viên | activity/GPS, schema/RLS/Storage, SQLite/sync và xóa dữ liệu | Chờ xác nhận | Chờ xác nhận |
| 4 | Nguyễn Đăng Đại | 2351170578 | Chờ xác nhận | Thành viên | nutrition/camera/recommendations/insights, danh mục, kiểm thử/báo cáo | Chờ xác nhận | Chờ xác nhận |

Mỗi người viết kiểm thử và tài liệu cho module phụ trách. Review chéo Trưởng–Đại, Đức–Hà. Kế hoạch sáu tuần, sản phẩm bàn giao và tiêu chí nghiệm thu chi tiết trong [README dự án](src/README.md). Cập nhật đóng góp theo minh chứng thực tế trước nộp bài.

## Thiết lập và chạy

Cài Flutter stable tương thích (khung sinh bằng 3.47.2, Dart ^3.13.2), Git, Android SDK/thiết bị hoặc Chrome. Từ gốc repository:

```bash
cd nhom06-65ktpm/src
flutter doctor
flutter pub get
flutter analyze
flutter run -d chrome
# Hoặc flutter devices rồi flutter run -d <device-id>
```

Chỉ chạy khung mặc định, chưa gọi backend. Firebase Android/Web và Supabase client config đã chuẩn bị chung, không cần thành viên tạo project hoặc key mới; iOS chưa có Firebase config. Đọc phần “Bắt đầu tại đây” trong [src/README.md](src/README.md) và [hướng dẫn AI](src/AGENTS.md) để nhận issue, chốt phụ thuộc và làm đúng phạm vi. Hướng dẫn commit/push/merge theo thầy nằm trong cùng README.

Đề cương hiện hành: [HealthyLife_Nhom06_De_cuong.docx](docs/HealthyLife_Nhom06_De_cuong.docx).
