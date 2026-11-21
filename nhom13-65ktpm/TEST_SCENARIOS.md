# Kịch Bản Kiểm Thử Thủ Công (Test Scenarios) — TLU PeerLearn

Tài liệu này dùng để kiểm thử thủ công các luồng nghiệp vụ đã hoàn thiện trên thiết bị thật / trình duyệt.

## Tài Khoản Test Mẫu (Seed Data)

> Chạy file `supabase/migrations/20261120000002_seed_users.sql` trên Supabase SQL Editor để tạo sẵn 3 tài khoản dưới đây:

| Vai trò | Email | Mật khẩu | Ghi chú |
| :--- | :--- | :--- | :--- |
| **Sinh viên 1** | `mentor01.tlu@gmail.com` | `123456` | MSV: `2351170574` (Phùng Minh Anh) |
| **Sinh viên 2** | `mentee01.tlu@gmail.com` | `123456` | MSV: `2251172456` (Phạm Văn Phước) |
| **Admin** | `admin.tlu@gmail.com` | `123456` | Quyền giám sát (`role = admin`) |

---

## 1. Luồng Tài khoản & Hồ sơ (`ACC-01` → `ACC-03`)
1. **Đăng ký mới:** Nhập Họ tên, Mã sinh viên (10 chữ số, thử nhập sai 5 số để kiểm tra báo lỗi), Email hợp lệ, Mật khẩu $\ge 6$ ký tự $\rightarrow$ Bấm **Đăng ký**.
2. **Đăng nhập:** Dùng tài khoản vừa tạo (hoặc tạo trên Supabase Dashboard) đăng nhập $\rightarrow$ Kiểm tra tự động chuyển vào màn hình **StudentHomeScreen** (không còn màn hình trống).
3. **Cập nhật hồ sơ:** Bấm vào **Hồ sơ cá nhân** $\rightarrow$ Cập nhật Khoa, Lớp, SĐT $\rightarrow$ Bấm **Lưu thay đổi** $\rightarrow$ Kiểm tra thông báo thành công và dữ liệu giữ nguyên khi tải lại.

## 2. Luồng Đăng ký Mentor / Mentee (`ACC-04` → `ACC-06`)
1. Từ Trang chủ, bấm **Đăng ký Mentor / Mentee**.
2. Chọn học phần (VD: `CSE204 - Cơ sở dữ liệu`).
3. Chọn vai trò **Mentor**, thử nhập điểm `11` để kiểm tra báo lỗi `(0 - 10)`, sau đó nhập `9.0`, chọn số Mentee tối đa, chọn 4–5 ô trên bảng 21 khung lịch rảnh $\rightarrow$ Bấm **Lưu đăng ký**.
4. Kiểm tra danh sách **Học phần đã đăng ký** hiển thị ngay bên dưới và trên Trang chủ.
5. Thử bấm icon **Xóa** để hủy đăng ký và xác nhận danh sách cập nhật.

## 3. Luồng Admin Giám sát (`ADM-01` → `ADM-03`)
1. Trên Supabase bảng `ck_profiles`, đổi `role` của 1 tài khoản thành `admin` rồi đăng nhập bằng tài khoản đó.
2. Kiểm tra tự động chuyển vào **AdminDashboardScreen**, hiển thị đủ 6 chỉ số tổng quan và danh sách phòng học (thử gõ từ khóa tìm kiếm).
3. Bấm icon **Nhật ký & Minh chứng** trên AppBar $\rightarrow$ Kiểm tra màn hình **AdminSessionLogsScreen** hiển thị danh sách buổi học, đối chiếu trạng thái điểm danh Mentor vs Mentee tự xác nhận.

