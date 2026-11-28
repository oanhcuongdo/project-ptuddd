# TÀI LIỆU ĐẶC TẢ KỸ THUẬT BACKEND & AUTH (PHÂN HỆ 1)

> **Dự án:** Baller Discipline – Sổ Tay Kỷ Luật & Huấn Luyện Bóng Đá Cá Nhân  
> **Học phần:** Phát triển ứng dụng trên thiết bị di động (Flutter)  
> **Lớp:** 65KTPM - Nhóm 1  
> **Sinh viên phụ trách:** Nguyễn Minh Đức  
> **Phân hệ:** Supabase Cloud Backend & Hồ Sơ Cầu Thủ (Baller Profile)  

---

## 1. Tổng Quan Kiến Trúc Backend (Supabase Cloud BaaS)

Ứng dụng sử dụng nền tảng **Supabase Cloud (PostgreSQL)** làm Backend-as-a-Service, tích hợp 3 dịch vụ cốt lõi:
1. **Supabase Database (PostgreSQL 15):** Lưu trữ dữ liệu quan hệ cho toàn bộ 5 phân hệ của nhóm.
2. **Supabase Auth (GoTrue):** Quản lý xác thực tài khoản cầu thủ an toàn bằng JWT và mã hóa mật khẩu Bcrypt.
3. **Supabase Storage:** Lưu trữ tệp hình ảnh đám mây (Ảnh đại diện cầu thủ, ảnh nhật ký trận đấu).

---

## 2. Đặc Tả Cơ Sở Dữ Liệu (5 Bảng Quan Hệ)

### 2.1. Bảng `player_profiles` (Hồ sơ cầu thủ)
Lưu thông tin chuyên môn cá nhân của cầu thủ, liên kết 1-1 với tài khoản `auth.users`.
* `id` (UUID - Primary Key): Tham chiếu khóa ngoại đến `auth.users(id)` (ON DELETE CASCADE).
* `full_name` (TEXT): Họ và tên đầy đủ của cầu thủ.
* `avatar_url` (TEXT): Đường dẫn hình ảnh đại diện trên Supabase Storage.
* `position` (TEXT): Vị trí thi đấu trên sân (`Tiền đạo`, `Tiền vệ`, `Hậu vệ`, `Thủ môn`).
* `preferred_foot` (TEXT): Chân thuận (`Chân phải`, `Chân trái`, `Hai chân`).
* `jersey_number` (INT): Số áo thi đấu (0 - 99).
* `club_team` (TEXT): Câu lạc bộ / Đội bóng tham gia (VD: FC 65KTPM).
* `created_at` / `updated_at` (TIMESTAMPTZ): Thời điểm khởi tạo và cập nhật.

### 2.2. Bảng `football_habits` (Giáo án kỷ luật bài tập)
* `id` (BIGINT - PK): Mã định danh thói quen.
* `user_id` (UUID - FK): Cầu thủ sở hữu thói quen.
* `title` (TEXT): Tên bài tập (VD: Tâng bóng 500 cái, Chạy bứt tốc 3km).
* `category` (TEXT): Nhóm bài tập (`Kỹ thuật`, `Thể lực`, `Dinh dưỡng`).
* `target_value` (INT), `unit` (TEXT), `reminder_time` (TIME), `color_value` (INT).

### 2.3. Bảng `habit_logs` (Lịch sử check-in kỷ luật)
* `id` (BIGINT - PK), `habit_id` (BIGINT - FK), `user_id` (UUID - FK).
* `date` (DATE): Ngày rèn luyện (yyyy-MM-dd).
* `is_completed` (BOOLEAN): Trạng thái hoàn thành bài tập hôm đó.
* `actual_value` (INT): Khối lượng thực tế đạt được.

### 2.4. Bảng `training_drills_sessions` (Phiên tập bấm giờ Drill)
* `id` (BIGINT - PK), `user_id` (UUID - FK).
* `drill_name` (TEXT): Tên bài drill tập luyện.
* `duration_minutes` (INT): Số phút tập thực tế được ghi nhận từ bộ đếm giờ.
* `sets_completed` (INT): Số hiệp bài tập đã hoàn thành.

### 2.5. Bảng `match_journals` (Nhật ký trận đấu & Buổi tập)
* `id` (BIGINT - PK), `user_id` (UUID - FK), `date` (DATE).
* `match_type` (TEXT): `Trận đấu` hoặc `Buổi tập`.
* `rating` (INT): Đánh giá phong độ từ 1 đến 5 sao.
* `goals` (INT), `assists` (INT): Bàn thắng và kiến tạo.
* `review_content` (TEXT): Nhận xét sau trận.
* `image_url` (TEXT): Đường dẫn ảnh sân bóng lưu tại bucket `match_photos`.

---

## 3. Chính Sách Bảo Mật Row Level Security (RLS) & Trigger

### 3.1. Row Level Security (RLS)
Cả 5 bảng đều kích hoạt cơ chế bảo mật hàng dọc RLS (`ENABLE ROW LEVEL SECURITY`). Mọi câu truy vấn từ ứng dụng di động phải có Token xác thực hợp lệ (`authenticated`) và chỉ được phép xem/sửa dữ liệu của chính mình:
```sql
CREATE POLICY "Chỉ người sở hữu được thao tác" ON public.player_profiles
    FOR ALL TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
```

### 3.2. Database Trigger Tự Động Tạo Profile
Khi người dùng đăng ký tài khoản mới qua hàm `signUp()`, hệ thống kích hoạt Trigger PostgreSQL tự động tạo bản ghi trong `player_profiles`:
```sql
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

## 4. Cấu Hình Supabase Storage Bucket

Hệ thống thiết lập 2 bucket lưu trữ đám mây:
1. **`avatars` (Public):** Lưu ảnh đại diện cầu thủ theo cấu trúc `<user_id>/avatar_<timestamp>.<ext>`.
2. **`match_photos` (Public):** Lưu hình ảnh nhật ký trận đấu theo cấu trúc `<user_id>/match_<timestamp>.<ext>`.

---

## 5. Đặc Tả Tầng Mã Nguồn Dart (Clean Architecture)

### 5.1. `PlayerProfileModel` (`lib/models/player_profile_model.dart`)
* Thực thể mô hình dữ liệu cầu thủ.
* Cung cấp các hàm ánh xạ dữ liệu:
  * `fromJson(Map<String, dynamic> json)`: Chuyển đổi dữ liệu JSON từ PostgreSQL.
  * `toJson()`: Serialize sang JSON để gửi lệnh Insert / Update.
  * `copyWith(...)`: Nhân bản Object với thuộc tính mới, giữ tính bất biến (Immutability).

### 5.2. `AuthService` (`lib/services/auth_service.dart`)
* `signInWithEmailPassword(email, password)`: Đăng nhập.
* `signUp(email, password, fullName, position, preferredFoot)`: Đăng ký tài khoản kèm metadata.
* `sendPasswordResetEmail(email)`: Gửi mail khôi phục mật khẩu.
* `updatePassword(newPassword)`: Cập nhật mật khẩu mới.
* `signOut()`: Đăng xuất và xóa phiên làm việc.
* `currentUser`, `isAuthenticated`: Kiểm tra trạng thái đăng nhập.

### 5.3. `ProfileService` (`lib/services/profile_service.dart`)
* `getProfile(userId)`: Lấy thông tin hồ sơ cầu thủ.
* `saveProfile(profileModel)`: Lưu/Cập nhật thông tin chuyên môn vào CSDL.
* `uploadAvatar(userId, imageBytes, fileExtension)`: Tải ảnh nhị phân lên bucket `avatars` và trả về URL ảnh công khai.
* `checkConnection()`: Ping kiểm tra kết nối CSDL Supabase.
